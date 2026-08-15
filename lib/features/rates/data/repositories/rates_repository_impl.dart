import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_local_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/dtos/rates_response_dto.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rates_snapshot.dart';
import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';

/// The latest payload plus where it came from.
typedef _LatestPayload = ({
  RatesResponseDto rates,
  DateTime fetchedAt,
  bool isFromCache,
});

/// [RatesRepository] over the remote and local data sources.
///
/// Owns the two cache policies and the date anchoring; the data sources own
/// transport, parsing and storage.
class RatesRepositoryImpl implements RatesRepository {
  /// Creates the repository.
  const RatesRepositoryImpl({
    required RatesRemoteDataSource remoteDataSource,
    required RatesLocalDataSource localDataSource,
    required Clock clock,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _clock = clock;

  final RatesRemoteDataSource _remoteDataSource;
  final RatesLocalDataSource _localDataSource;
  final Clock _clock;

  /// How long a cached `latest` payload is served without a refetch.
  ///
  /// Only the mutable `latest` entry ages. Dated snapshots never expire.
  static const Duration latestCacheTtl = Duration(minutes: 15);

  @override
  Future<Result<RatesSnapshot>> getLatestRates({
    bool forceRefresh = false,
  }) async {
    final (payload, failure) = await _latestPayload(forceRefresh: forceRefresh);
    if (payload == null) return failed(failure!);

    final previous = await _previousDayFor(payload.rates.date);
    final previousRates = <Currency, ExchangeRate>{
      for (final rate in previous?.toDomain() ?? const <ExchangeRate>[])
        rate.currency: rate,
    };

    return success(
      RatesSnapshot(
        rates: [
          for (final rate in payload.rates.toDomain())
            RateComparison(
              current: rate,
              previous: previousRates[rate.currency],
            ),
        ],
        fetchedAt: payload.fetchedAt,
        isFromCache: payload.isFromCache,
      ),
    );
  }

  @override
  Future<Result<List<ExchangeRate>>> getHistory(
    Currency currency, {
    int days = 7,
  }) async {
    final (payload, failure) = await _latestPayload();
    if (payload == null) return failed(failure!);

    final anchorDate = payload.rates.date;
    // Keyed by the date the API actually answered with: a walk-back can hand
    // back the same snapshot for two requested days, and a chart must not
    // plot that day twice.
    final byDate = <DateTime, ExchangeRate>{};

    for (var step = 0; step < days; step++) {
      final requestedDate = anchorDate.subtract(Duration(days: step));
      final RatesResponseDto rates;
      if (step == 0) {
        // The list screen already holds this day; no request for it.
        rates = payload.rates;
      } else {
        final (dayRates, dayFailure) = await _ratesForDate(requestedDate);
        if (dayRates == null) return failed(dayFailure!);
        rates = dayRates;
      }
      final rate = rates.toDomain().firstWhere(
        (entry) => entry.currency == currency,
      );
      byDate[rate.date] = rate;
    }

    final ordered = byDate.values.toList()
      ..sort((first, second) => first.date.compareTo(second.date));
    return success(ordered);
  }

  /// The latest payload, from cache while it is fresh and from the network
  /// otherwise, falling back to a stale cache when the network fails.
  Future<Result<_LatestPayload>> _latestPayload({
    bool forceRefresh = false,
  }) async {
    final (cached, _) = await _localDataSource.readLatest();
    final isFresh =
        cached != null &&
        _clock.now().difference(cached.fetchedAt) < latestCacheTtl;

    if (cached != null && isFresh && !forceRefresh) {
      return success((
        rates: cached.rates,
        fetchedAt: cached.fetchedAt,
        isFromCache: true,
      ));
    }

    final (fresh, failure) = await _remoteDataSource.fetchLatest();
    if (fresh != null) {
      final fetchedAt = _clock.now();
      await _localDataSource.writeLatest(fresh, fetchedAt: fetchedAt);
      return success((
        rates: fresh,
        fetchedAt: fetchedAt,
        isFromCache: false,
      ));
    }

    if (cached != null) {
      return success((
        rates: cached.rates,
        fetchedAt: cached.fetchedAt,
        isFromCache: true,
      ));
    }
    return failed(failure!);
  }

  /// The published day before [date], or `null` when it cannot be obtained.
  ///
  /// Best effort on purpose: a missing previous day costs the movement
  /// indicator, it does not cost the rates list.
  Future<RatesResponseDto?> _previousDayFor(DateTime date) async {
    final (rates, _) = await _ratesForDate(
      date.subtract(const Duration(days: 1)),
    );
    return rates;
  }

  /// The snapshot for [date]: cache first — dated snapshots are immutable, so
  /// a hit is always valid — then the network, caching what comes back.
  Future<Result<RatesResponseDto>> _ratesForDate(DateTime date) async {
    final (cached, _) = await _localDataSource.readForDate(date);
    if (cached != null) return success(cached);

    final (fetched, failure) = await _remoteDataSource.fetchForDate(date);
    if (fetched == null) return failed(failure!);

    await _localDataSource.writeForDate(fetched);
    return success(fetched);
  }
}

import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/extensions/date_time_extensions.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_local_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/dtos/rates_response_dto.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
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

  /// Extra calendar days the history may reach past the days it plots.
  ///
  /// The source publishes on business days, so a week of published rates can
  /// span more than a week of calendar dates. This bounds how far back that
  /// search may go before giving up.
  static const int maxExtraCalendarDays = 7;

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
  Future<Result<RateHistory>> getHistory(
    Currency currency, {
    int days = 7,
  }) async {
    final (payload, failure) = await _latestPayload();
    if (payload == null) return failed(failure!);

    final anchorDate = payload.rates.date;
    // Keyed by the date the API actually answered with: two requested days
    // can resolve to one published file over a weekend, and that counts once.
    final byDate = <DateTime, ExchangeRate>{};

    // One more published day than is plotted: the extra is never a dot, it
    // only gives the oldest plotted point something to be compared against.
    final wanted = days + 1;
    final lastStep = wanted + maxExtraCalendarDays;

    for (var step = 0; step <= lastStep && byDate.length < wanted; step++) {
      final requestedDate = anchorDate.subtract(Duration(days: step));
      final RatesResponseDto rates;
      if (step == 0) {
        // The list screen already holds this day; no request for it. It is
        // also what pins the newest point to the anchored latest date.
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

    if (byDate.length < wanted) {
      // The search reached its bound without finding enough published days.
      return failed(
        RateUnavailableFailure(
          currencyCode: currency.code,
          requestedDate: anchorDate
              .subtract(Duration(days: lastStep))
              .toApiDate(),
        ),
      );
    }

    return success(_historyFrom(byDate, days: days));
  }

  /// Builds the plotted history from the published days that came back.
  ///
  /// Each point is paired with the day before it in the series, and the
  /// oldest day is then dropped: it exists to be a predecessor, not a dot.
  RateHistory _historyFrom(
    Map<DateTime, ExchangeRate> byDate, {
    required int days,
  }) {
    final ordered = byDate.values.toList()
      ..sort((first, second) => first.date.compareTo(second.date));

    final points = [
      for (var index = 0; index < ordered.length; index++)
        RateHistoryPoint(
          rate: ordered[index],
          previous: index == 0 ? null : ordered[index - 1],
        ),
    ];

    final displayed = points.length > days
        ? points.sublist(points.length - days)
        : points;
    return RateHistory(points: displayed);
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

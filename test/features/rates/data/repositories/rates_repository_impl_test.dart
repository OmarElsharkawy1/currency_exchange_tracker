import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_local_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/dtos/rates_response_dto.dart';
import 'package:currency_exchange_tracker/features/rates/data/repositories/rates_repository_impl.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/fake_clock.dart';

class MockRatesRemoteDataSource extends Mock implements RatesRemoteDataSource {}

class MockRatesLocalDataSource extends Mock implements RatesLocalDataSource {}

RatesResponseDto dtoFor(DateTime date, {double usd = 0.02}) =>
    RatesResponseDto.fromJson(<String, dynamic>{
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'egp': <String, dynamic>{
        'usd': usd,
        'eur': 0.017821,
        'gbp': 0.015231,
        'sar': 0.072103,
        'jpy': 2.9012,
      },
    });

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2024));
    registerFallbackValue(dtoFor(DateTime.utc(2024, 3, 6)));
  });

  late MockRatesRemoteDataSource remote;
  late MockRatesLocalDataSource local;
  late FakeClock clock;
  late RatesRepositoryImpl repository;

  final anchorDate = DateTime.utc(2024, 3, 6);
  final latestDto = dtoFor(anchorDate, usd: 0.019100);
  final yesterdayDto = dtoFor(DateTime.utc(2024, 3, 5), usd: 0.019227);

  setUp(() {
    remote = MockRatesRemoteDataSource();
    local = MockRatesLocalDataSource();
    clock = FakeClock(DateTime.utc(2024, 3, 6, 12));
    repository = RatesRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      clock: clock,
    );

    when(
      () => local.readLatest(),
    ).thenAnswer((_) async => failed(const CacheMissFailure(key: 'latest')));
    when(
      () => local.readForDate(any()),
    ).thenAnswer((_) async => failed(const CacheMissFailure()));
    when(
      () => local.writeLatest(any(), fetchedAt: any(named: 'fetchedAt')),
    ).thenAnswer((_) async {});
    when(() => local.writeForDate(any())).thenAnswer((_) async {});
    when(
      () => remote.fetchLatest(),
    ).thenAnswer((_) async => success(latestDto));
    when(() => remote.fetchForDate(any())).thenAnswer(
      (_) async => failed(const RateUnavailableFailure()),
    );
  });

  /// Makes the cache hold [rates] as the latest payload, fetched [age] ago.
  void cacheLatest(RatesResponseDto rates, {required Duration age}) {
    when(() => local.readLatest()).thenAnswer(
      (_) async =>
          success((rates: rates, fetchedAt: clock.instant.subtract(age))),
    );
  }

  group('getLatestRates — cache policy', () {
    test('serves a fresh cache without touching the network', () async {
      cacheLatest(latestDto, age: const Duration(minutes: 5));
      when(
        () => local.readForDate(DateTime.utc(2024, 3, 5)),
      ).thenAnswer((_) async => success(yesterdayDto));

      final (snapshot, failure) = await repository.getLatestRates();

      expect(failure, isNull);
      expect(snapshot!.isFromCache, isTrue);
      expect(
        snapshot.fetchedAt,
        clock.instant.subtract(const Duration(minutes: 5)),
      );
      verifyNever(() => remote.fetchLatest());
      verifyNever(() => remote.fetchForDate(any()));
    });

    test('refetches once the cached payload goes stale', () async {
      cacheLatest(latestDto, age: RatesRepositoryImpl.latestCacheTtl);

      final (snapshot, failure) = await repository.getLatestRates();

      expect(failure, isNull);
      expect(snapshot!.isFromCache, isFalse);
      expect(snapshot.fetchedAt, clock.instant);
      verify(() => remote.fetchLatest()).called(1);
      verify(
        () => local.writeLatest(latestDto, fetchedAt: clock.instant),
      ).called(1);
    });

    test('refetches a fresh cache when a refresh is forced', () async {
      cacheLatest(latestDto, age: const Duration(minutes: 1));

      final (snapshot, failure) = await repository.getLatestRates(
        forceRefresh: true,
      );

      expect(failure, isNull);
      expect(snapshot!.isFromCache, isFalse);
      verify(() => remote.fetchLatest()).called(1);
    });

    test(
      'falls back to the stale cache when the network is unreachable',
      () async {
        cacheLatest(latestDto, age: const Duration(hours: 6));
        when(
          () => remote.fetchLatest(),
        ).thenAnswer((_) async => failed(const NetworkFailure()));

        final (snapshot, failure) = await repository.getLatestRates();

        expect(failure, isNull);
        expect(snapshot!.isFromCache, isTrue);
        expect(
          snapshot.fetchedAt,
          clock.instant.subtract(const Duration(hours: 6)),
        );
      },
    );

    test(
      'surfaces the network failure when there is no cache at all',
      () async {
        when(
          () => remote.fetchLatest(),
        ).thenAnswer((_) async => failed(const TimeoutFailure()));

        final (snapshot, failure) = await repository.getLatestRates();

        expect(snapshot, isNull);
        expect(failure, const TimeoutFailure());
      },
    );
  });

  group('getLatestRates — offline paths', () {
    test(
      'cold start offline serves the cache and says where it came from',
      () async {
        // Nothing fresh, no network: the cache is the whole answer.
        cacheLatest(latestDto, age: const Duration(days: 2));
        when(
          () => remote.fetchLatest(),
        ).thenAnswer((_) async => failed(const NetworkFailure()));
        when(
          () => local.readForDate(DateTime.utc(2024, 3, 5)),
        ).thenAnswer((_) async => success(yesterdayDto));

        final (snapshot, failure) = await repository.getLatestRates();

        expect(failure, isNull);
        expect(snapshot!.isFromCache, isTrue);
        expect(snapshot.rates.first.hasPrevious, isTrue);
        expect(
          snapshot.fetchedAt,
          clock.instant.subtract(const Duration(days: 2)),
        );
      },
    );

    test(
      'offline with an empty cache surfaces the failure, not empty rates',
      () async {
        when(
          () => remote.fetchLatest(),
        ).thenAnswer((_) async => failed(const NetworkFailure()));

        final (snapshot, failure) = await repository.getLatestRates();

        expect(snapshot, isNull);
        expect(failure, const NetworkFailure());
      },
    );

    test(
      'offline still shows rates when only the previous day is missing',
      () async {
        cacheLatest(latestDto, age: const Duration(hours: 3));
        when(
          () => remote.fetchLatest(),
        ).thenAnswer((_) async => failed(const NetworkFailure()));

        final (snapshot, failure) = await repository.getLatestRates();

        expect(failure, isNull);
        expect(snapshot!.rates.first.hasPrevious, isFalse);
        expect(snapshot.rates.first.change, 0);
      },
    );

    test('a forced refresh offline falls back rather than failing', () async {
      cacheLatest(latestDto, age: const Duration(minutes: 1));
      when(
        () => remote.fetchLatest(),
      ).thenAnswer((_) async => failed(const TimeoutFailure()));

      final (snapshot, failure) = await repository.getLatestRates(
        forceRefresh: true,
      );

      expect(failure, isNull);
      expect(snapshot!.isFromCache, isTrue);
    });
  });

  group('getLatestRates — previous day', () {
    test('attaches the previous day from the immutable cache', () async {
      when(
        () => local.readForDate(DateTime.utc(2024, 3, 5)),
      ).thenAnswer((_) async => success(yesterdayDto));

      final (snapshot, _) = await repository.getLatestRates();

      final usd = snapshot!.rates.firstWhere(
        (rate) => rate.currency == Currency.usd,
      );
      expect(usd.hasPrevious, isTrue);
      expect(usd.previous!.rawRate, 0.019227);
      expect(usd.direction, RateDirection.egpWeakening);
      expect(usd.percentChange, closeTo(0.664923, 1e-5));
      verifyNever(() => remote.fetchForDate(any()));
    });

    test('fetches the previous day and caches it write-once', () async {
      when(
        () => remote.fetchForDate(DateTime.utc(2024, 3, 5)),
      ).thenAnswer((_) async => success(yesterdayDto));

      final (snapshot, _) = await repository.getLatestRates();

      expect(snapshot!.rates.first.hasPrevious, isTrue);
      verify(() => local.writeForDate(yesterdayDto)).called(1);
    });

    test(
      'reports no movement when the previous day cannot be reached',
      () async {
        final (snapshot, failure) = await repository.getLatestRates();

        expect(failure, isNull);
        final usd = snapshot!.rates.first;
        expect(usd.hasPrevious, isFalse);
        expect(usd.change, 0);
        expect(usd.direction, RateDirection.flat);
      },
    );

    test('covers every tracked currency, in declaration order', () async {
      final (snapshot, _) = await repository.getLatestRates();

      expect(snapshot!.rates.map((rate) => rate.currency), Currency.values);
    });
  });

  group('getHistory', () {
    /// Answers every dated request with that same date's snapshot.
    void servePerfectHistory() {
      when(() => remote.fetchForDate(any())).thenAnswer((invocation) async {
        final date = invocation.positionalArguments.first as DateTime;
        return success(dtoFor(date));
      });
    }

    test(
      'anchors on the latest payload date, never on the device clock',
      () async {
        clock.instant = DateTime.utc(2025);
        servePerfectHistory();

        final (history, failure) = await repository.getHistory(
          Currency.usd,
          days: 3,
        );

        expect(failure, isNull);
        expect(history!.map((rate) => rate.date), [
          DateTime.utc(2024, 3, 4),
          DateTime.utc(2024, 3, 5),
          anchorDate,
        ]);
      },
    );

    test('returns seven points oldest first by default', () async {
      servePerfectHistory();

      final (history, _) = await repository.getHistory(Currency.usd);

      expect(history!.length, 7);
      expect(history.first.date, DateTime.utc(2024, 2, 29));
      expect(history.last.date, anchorDate);
      expect(history.every((rate) => rate.currency == Currency.usd), isTrue);
    });

    test('reuses the latest payload for the anchor day', () async {
      servePerfectHistory();

      final (history, _) = await repository.getHistory(Currency.usd, days: 2);

      expect(history!.last.rawRate, 0.019100); // the latest payload's quote
      verifyNever(() => remote.fetchForDate(anchorDate));
    });

    test('never touches the network for a date already cached', () async {
      when(
        () => local.readForDate(DateTime.utc(2024, 3, 5)),
      ).thenAnswer((_) async => success(yesterdayDto));

      final (history, failure) = await repository.getHistory(
        Currency.usd,
        days: 2,
      );

      expect(failure, isNull);
      expect(history!.first.rawRate, 0.019227);
      verifyNever(() => remote.fetchForDate(any()));
      verifyNever(() => local.writeForDate(any()));
    });

    test('caches every freshly fetched day', () async {
      servePerfectHistory();

      await repository.getHistory(Currency.usd, days: 3);

      verify(() => local.writeForDate(any())).called(2);
    });

    test('surfaces a walk-back that ran out of steps', () async {
      when(() => remote.fetchForDate(DateTime.utc(2024, 3, 5))).thenAnswer(
        (_) async =>
            failed(const RateUnavailableFailure(requestedDate: '2024-03-05')),
      );

      final (history, failure) = await repository.getHistory(
        Currency.usd,
        days: 3,
      );

      expect(history, isNull);
      expect(
        failure,
        const RateUnavailableFailure(requestedDate: '2024-03-05'),
      );
    });

    test(
      'collapses days a walk-back answered with the same snapshot',
      () async {
        // A weekend: both Sunday and Saturday resolve to Friday's file.
        final friday = dtoFor(DateTime.utc(2024, 3, 4));
        when(
          () => remote.fetchForDate(any()),
        ).thenAnswer((_) async => success(friday));

        final (history, failure) = await repository.getHistory(
          Currency.usd,
          days: 3,
        );

        expect(failure, isNull);
        expect(history!.map((rate) => rate.date), [
          DateTime.utc(2024, 3, 4),
          anchorDate,
        ]);
      },
    );

    test('fetches the anchor when no cached latest payload exists', () async {
      servePerfectHistory();

      final (history, failure) = await repository.getHistory(
        Currency.usd,
        days: 1,
      );

      expect(failure, isNull);
      expect(history!.single.date, anchorDate);
      verify(() => remote.fetchLatest()).called(1);
    });

    test('surfaces the anchor failure when latest is unreachable and '
        'uncached', () async {
      when(
        () => remote.fetchLatest(),
      ).thenAnswer((_) async => failed(const NetworkFailure()));

      final (history, failure) = await repository.getHistory(Currency.usd);

      expect(history, isNull);
      expect(failure, const NetworkFailure());
    });

    test('works offline entirely from cache', () async {
      cacheLatest(latestDto, age: const Duration(minutes: 2));
      when(
        () => local.readForDate(DateTime.utc(2024, 3, 5)),
      ).thenAnswer((_) async => success(yesterdayDto));

      final (history, failure) = await repository.getHistory(
        Currency.usd,
        days: 2,
      );

      expect(failure, isNull);
      expect(history!.length, 2);
      verifyNever(() => remote.fetchLatest());
      verifyNever(() => remote.fetchForDate(any()));
    });
  });
}

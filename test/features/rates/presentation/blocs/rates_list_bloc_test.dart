import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rates_snapshot.dart';
import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatesRepository extends Mock implements RatesRepository {}

RateComparison comparisonFor(Currency currency, double rawRate) {
  return RateComparison(
    current: ExchangeRate(
      currency: currency,
      rawRate: rawRate,
      date: DateTime.utc(2024, 3, 6),
    ),
    previous: ExchangeRate(
      currency: currency,
      rawRate: 0.019227,
      date: DateTime.utc(2024, 3, 5),
    ),
  );
}

void main() {
  late MockRatesRepository repository;

  final fetchedAt = DateTime.utc(2024, 3, 6, 12);
  final rates = [comparisonFor(Currency.usd, 0.019100)];
  final snapshot = RatesSnapshot(
    rates: rates,
    fetchedAt: fetchedAt,
    isFromCache: false,
  );
  final refreshedSnapshot = RatesSnapshot(
    rates: [comparisonFor(Currency.usd, 0.019000)],
    fetchedAt: DateTime.utc(2024, 3, 6, 13),
    isFromCache: false,
  );

  setUp(() {
    repository = MockRatesRepository();
  });

  RatesListBloc buildBloc() => RatesListBloc(repository: repository);

  /// Makes the repository answer with [result] for any call.
  void stubLatest(Result<RatesSnapshot> result) {
    when(
      () => repository.getLatestRates(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('starts in progress so the first frame is a skeleton', () {
    expect(buildBloc().state, const RatesLoadInProgress());
  });

  group('RatesRequested', () {
    blocTest<RatesListBloc, RatesListState>(
      'emits in-progress then success',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRequested()),
      expect: () => [
        const RatesLoadInProgress(),
        RatesLoadSuccess(
          rates: rates,
          lastUpdated: fetchedAt,
          isFromCache: false,
        ),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'passes the entities through untouched',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRequested()),
      verify: (bloc) {
        final state = bloc.state as RatesLoadSuccess;
        expect(identical(state.rates, rates), isTrue);
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'carries the cache flag and the fetch time',
      setUp: () => stubLatest(
        success(
          RatesSnapshot(
            rates: rates,
            fetchedAt: fetchedAt,
            isFromCache: true,
          ),
        ),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRequested()),
      verify: (bloc) {
        final state = bloc.state as RatesLoadSuccess;
        expect(state.isFromCache, isTrue);
        expect(state.lastUpdated, fetchedAt);
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'emits empty when the repository returns no rates',
      setUp: () => stubLatest(
        success(
          RatesSnapshot(
            rates: const [],
            fetchedAt: fetchedAt,
            isFromCache: false,
          ),
        ),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRequested()),
      expect: () => [const RatesLoadInProgress(), const RatesLoadEmpty()],
    );

    blocTest<RatesListBloc, RatesListState>(
      'emits failure carrying the failure type',
      setUp: () => stubLatest(failed(const NetworkFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRequested()),
      expect: () => [
        const RatesLoadInProgress(),
        const RatesLoadFailure(failure: NetworkFailure()),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'does not force a refresh — a fresh cache is good enough',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRequested()),
      verify: (_) {
        verify(() => repository.getLatestRates()).called(1);
      },
    );
  });

  group('RatesConnectivityChanged', () {
    blocTest<RatesListBloc, RatesListState>(
      'refreshes exactly once when connectivity comes back',
      setUp: () => stubLatest(success(refreshedSnapshot)),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: true,
      ),
      act: (bloc) => bloc
        ..add(const RatesConnectivityChanged(isOnline: false))
        ..add(const RatesConnectivityChanged(isOnline: true)),
      verify: (_) {
        verify(() => repository.getLatestRates(forceRefresh: true)).called(1);
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'does not skeleton the rates it already has while reconnecting',
      setUp: () => stubLatest(success(refreshedSnapshot)),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: true,
      ),
      act: (bloc) => bloc
        ..add(const RatesConnectivityChanged(isOnline: false))
        ..add(const RatesConnectivityChanged(isOnline: true)),
      expect: () => [
        RatesLoadSuccess(
          rates: refreshedSnapshot.rates,
          lastUpdated: refreshedSnapshot.fetchedAt,
          isFromCache: false,
        ),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'going offline alone refreshes nothing',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: false,
      ),
      act: (bloc) => bloc.add(const RatesConnectivityChanged(isOnline: false)),
      expect: () => <RatesListState>[],
      verify: (_) {
        verifyNever(
          () => repository.getLatestRates(
            forceRefresh: any(named: 'forceRefresh'),
          ),
        );
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'staying online refreshes nothing — only a reconnect counts',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: false,
      ),
      act: (bloc) => bloc
        ..add(const RatesConnectivityChanged(isOnline: true))
        ..add(const RatesConnectivityChanged(isOnline: true)),
      verify: (_) {
        verifyNever(
          () => repository.getLatestRates(
            forceRefresh: any(named: 'forceRefresh'),
          ),
        );
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'each reconnect refreshes once, not once per flap report',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: false,
      ),
      act: (bloc) {
        for (final isOnline in [false, true, false, true]) {
          bloc.add(RatesConnectivityChanged(isOnline: isOnline));
        }
      },
      verify: (_) {
        verify(() => repository.getLatestRates(forceRefresh: true)).called(2);
      },
    );
  });

  group('offline with nothing cached', () {
    blocTest<RatesListBloc, RatesListState>(
      'is its own state, not a generic error',
      setUp: () => stubLatest(failed(const NetworkFailure())),
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const RatesConnectivityChanged(isOnline: false))
        ..add(const RatesRequested()),
      expect: () => [
        const RatesLoadInProgress(),
        const RatesUnavailableOffline(),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'is still a plain failure while online',
      setUp: () => stubLatest(failed(const NetworkFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRequested()),
      expect: () => [
        const RatesLoadInProgress(),
        const RatesLoadFailure(failure: NetworkFailure()),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'serves the cache silently when offline at cold start',
      setUp: () => stubLatest(
        success(
          RatesSnapshot(
            rates: rates,
            fetchedAt: fetchedAt,
            isFromCache: true,
          ),
        ),
      ),
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const RatesConnectivityChanged(isOnline: false))
        ..add(const RatesRequested()),
      expect: () => [
        const RatesLoadInProgress(),
        RatesLoadSuccess(
          rates: rates,
          lastUpdated: fetchedAt,
          isFromCache: true,
        ),
      ],
    );
  });

  group('RatesRefreshed', () {
    blocTest<RatesListBloc, RatesListState>(
      'forces a refresh past the cache',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRefreshed()),
      verify: (_) {
        verify(() => repository.getLatestRates(forceRefresh: true)).called(1);
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'refreshing while loaded never falls back to a skeleton',
      setUp: () => stubLatest(success(refreshedSnapshot)),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: false,
      ),
      act: (bloc) => bloc.add(const RatesRefreshed()),
      expect: () => [
        RatesLoadSuccess(
          rates: refreshedSnapshot.rates,
          lastUpdated: refreshedSnapshot.fetchedAt,
          isFromCache: false,
        ),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'keeps the rates on screen when a refresh fails, and says it failed',
      setUp: () => stubLatest(failed(const TimeoutFailure())),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: false,
      ),
      act: (bloc) => bloc.add(const RatesRefreshed()),
      expect: () => [
        RatesLoadSuccess(
          rates: rates,
          lastUpdated: fetchedAt,
          isFromCache: false,
          refreshFailure: const TimeoutFailure(),
        ),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'a failed refresh keeps the very same rates and timestamp',
      setUp: () => stubLatest(failed(const TimeoutFailure())),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: true,
      ),
      act: (bloc) => bloc.add(const RatesRefreshed()),
      verify: (bloc) {
        final state = bloc.state as RatesLoadSuccess;
        expect(identical(state.rates, rates), isTrue);
        expect(state.lastUpdated, fetchedAt);
        expect(state.isFromCache, isTrue);
        expect(state.refreshFailure, const TimeoutFailure());
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'never falls back to a full-screen error once rates are loaded',
      setUp: () => stubLatest(failed(const NetworkFailure())),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: false,
      ),
      act: (bloc) => bloc.add(const RatesRefreshed()),
      verify: (bloc) {
        expect(bloc.state, isA<RatesLoadSuccess>());
        expect(bloc.state, isNot(isA<RatesLoadFailure>()));
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'the next successful refresh clears the failure',
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: fetchedAt,
        isFromCache: false,
        refreshFailure: const TimeoutFailure(),
      ),
      act: (bloc) {
        stubLatest(success(refreshedSnapshot));
        bloc.add(const RatesRefreshed());
      },
      expect: () => [
        RatesLoadSuccess(
          rates: refreshedSnapshot.rates,
          lastUpdated: refreshedSnapshot.fetchedAt,
          isFromCache: false,
        ),
      ],
      verify: (bloc) {
        expect((bloc.state as RatesLoadSuccess).refreshFailure, isNull);
      },
    );

    blocTest<RatesListBloc, RatesListState>(
      'a cold-start failure is still a full-screen failure',
      setUp: () => stubLatest(failed(const NetworkFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(const RatesRefreshed()),
      expect: () => [
        const RatesLoadInProgress(),
        const RatesLoadFailure(failure: NetworkFailure()),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'shows the failure when a retry from the failure state fails again',
      setUp: () => stubLatest(failed(const NetworkFailure(statusCode: 500))),
      build: buildBloc,
      seed: () => const RatesLoadFailure(failure: TimeoutFailure()),
      act: (bloc) => bloc.add(const RatesRefreshed()),
      expect: () => [
        const RatesLoadInProgress(),
        const RatesLoadFailure(failure: NetworkFailure(statusCode: 500)),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'recovers from the failure state when the retry succeeds',
      setUp: () => stubLatest(success(snapshot)),
      build: buildBloc,
      seed: () => const RatesLoadFailure(failure: NetworkFailure()),
      act: (bloc) => bloc.add(const RatesRefreshed()),
      expect: () => [
        const RatesLoadInProgress(),
        RatesLoadSuccess(
          rates: rates,
          lastUpdated: fetchedAt,
          isFromCache: false,
        ),
      ],
    );

    blocTest<RatesListBloc, RatesListState>(
      'serves cached rates when a refresh only reaches the cache',
      setUp: () => stubLatest(
        success(
          RatesSnapshot(
            rates: rates,
            fetchedAt: fetchedAt,
            isFromCache: true,
          ),
        ),
      ),
      build: buildBloc,
      seed: () => RatesLoadSuccess(
        rates: rates,
        lastUpdated: DateTime.utc(2024, 3, 5),
        isFromCache: false,
      ),
      act: (bloc) => bloc.add(const RatesRefreshed()),
      expect: () => [
        RatesLoadSuccess(
          rates: rates,
          lastUpdated: fetchedAt,
          isFromCache: true,
        ),
      ],
    );
  });
}

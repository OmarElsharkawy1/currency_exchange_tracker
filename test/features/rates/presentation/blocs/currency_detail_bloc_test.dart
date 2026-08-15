import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatesRepository extends Mock implements RatesRepository {}

ExchangeRate rateOn(int day, double rawRate) => ExchangeRate(
  currency: Currency.usd,
  rawRate: rawRate,
  date: DateTime.utc(2024, 3, day),
);

RateHistory historyOfSeven() => RateHistory(
  points: [
    for (var day = 1; day <= 7; day++)
      RateHistoryPoint(
        rate: rateOn(day, 0.0192 - day * 0.00001),
        previous: rateOn(day - 1, 0.0192 - (day - 1) * 0.00001),
      ),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(Currency.usd);
  });

  late MockRatesRepository repository;

  final history = historyOfSeven();

  setUp(() {
    repository = MockRatesRepository();
  });

  CurrencyDetailBloc buildBloc() => CurrencyDetailBloc(repository: repository);

  void stubHistory(Result<RateHistory> result) {
    when(
      () => repository.getHistory(any(), days: any(named: 'days')),
    ).thenAnswer((_) async => result);
  }

  /// A bloc already showing the seven-day history.
  CurrencyDetailBloc loadedBloc() => buildBloc();

  HistoryLoadSuccess loaded({int? selectedIndex}) =>
      HistoryLoadSuccess(history: history, selectedIndex: selectedIndex);

  test('starts in progress — only the chart waits, never the header', () {
    expect(buildBloc().state, const HistoryLoadInProgress());
  });

  group('loading', () {
    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'emits in-progress then the history with nothing selected',
      setUp: () => stubHistory(success(history)),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [const HistoryLoadInProgress(), loaded()],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'shows the latest point while nothing is selected',
      setUp: () => stubHistory(success(history)),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      verify: (bloc) {
        final state = bloc.state as HistoryLoadSuccess;
        expect(state.selectedPoint, history.latest);
        expect(state.isShowingLatest, isTrue);
      },
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'emits failure carrying the failure type',
      setUp: () => stubHistory(failed(const NetworkFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        const HistoryLoadFailure(failure: NetworkFailure()),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'emits empty when a single point cannot make a line',
      setUp: () => stubHistory(
        success(
          RateHistory(points: [RateHistoryPoint(rate: rateOn(6, 0.0191))]),
        ),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        const HistoryLoadEmpty(),
      ],
    );
  });

  group('tapping a point', () {
    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'selects it and keeps it selected',
      build: loadedBloc,
      seed: loaded,
      act: (bloc) => bloc.add(const HistoryPointSelected(2)),
      expect: () => [loaded(selectedIndex: 2)],
      verify: (bloc) {
        final state = bloc.state as HistoryLoadSuccess;
        expect(state.selectedPoint, history.points[2]);
        expect(state.isShowingLatest, isFalse);
      },
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'clearing returns to the latest',
      build: loadedBloc,
      seed: () => loaded(selectedIndex: 2),
      act: (bloc) => bloc.add(const HistoryPointCleared()),
      expect: () => [loaded()],
      verify: (bloc) {
        expect(
          (bloc.state as HistoryLoadSuccess).selectedPoint,
          history.latest,
        );
      },
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'ignores an index the history does not have',
      build: loadedBloc,
      seed: loaded,
      act: (bloc) => bloc
        ..add(const HistoryPointSelected(99))
        ..add(const HistoryPointSelected(-1)),
      expect: () => <CurrencyDetailState>[],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'ignores a selection while there is no history',
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryPointSelected(1)),
      expect: () => <CurrencyDetailState>[],
    );
  });

  group('scrubbing', () {
    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'follows the finger',
      build: loadedBloc,
      seed: loaded,
      act: (bloc) => bloc
        ..add(const HistoryScrubbed(1))
        ..add(const HistoryScrubbed(4)),
      expect: () => [loaded(selectedIndex: 1), loaded(selectedIndex: 4)],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'releases back to the latest when nothing was selected before',
      build: loadedBloc,
      seed: loaded,
      act: (bloc) => bloc
        ..add(const HistoryScrubbed(3))
        ..add(const HistoryScrubEnded()),
      expect: () => [loaded(selectedIndex: 3), loaded()],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'releases back to the tap-selection that preceded it',
      build: loadedBloc,
      seed: loaded,
      act: (bloc) => bloc
        ..add(const HistoryPointSelected(5))
        ..add(const HistoryScrubbed(1))
        ..add(const HistoryScrubEnded()),
      expect: () => [
        loaded(selectedIndex: 5),
        loaded(selectedIndex: 1),
        loaded(selectedIndex: 5),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'a tap during a scrub becomes the new persisted selection',
      build: loadedBloc,
      seed: loaded,
      act: (bloc) => bloc
        ..add(const HistoryScrubbed(1))
        ..add(const HistoryPointSelected(6))
        ..add(const HistoryScrubEnded()),
      expect: () => [
        loaded(selectedIndex: 1),
        loaded(selectedIndex: 6),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'ignores a scrub past the ends of the series',
      build: loadedBloc,
      seed: loaded,
      act: (bloc) => bloc.add(const HistoryScrubbed(42)),
      expect: () => <CurrencyDetailState>[],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'a reload drops any selection',
      setUp: () => stubHistory(success(history)),
      build: buildBloc,
      seed: () => loaded(selectedIndex: 4),
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [const HistoryLoadInProgress(), loaded()],
    );
  });
}

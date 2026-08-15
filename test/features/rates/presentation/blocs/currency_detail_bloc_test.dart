import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatesRepository extends Mock implements RatesRepository {}

List<ExchangeRate> historyFor(Currency currency) => [
  for (var day = 0; day < 7; day++)
    ExchangeRate(
      currency: currency,
      rawRate: 0.0191 + day * 0.00001,
      date: DateTime.utc(2024, 2, 29).add(Duration(days: day)),
    ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(Currency.usd);
  });

  late MockRatesRepository repository;

  final usdHistory = historyFor(Currency.usd);

  setUp(() {
    repository = MockRatesRepository();
  });

  CurrencyDetailBloc buildBloc() => CurrencyDetailBloc(repository: repository);

  /// Makes the repository answer any history request with [result].
  void stubHistory(Result<List<ExchangeRate>> result) {
    when(
      () => repository.getHistory(any(), days: any(named: 'days')),
    ).thenAnswer((_) async => result);
  }

  test('starts in progress — only the chart waits, never the header', () {
    expect(buildBloc().state, const HistoryLoadInProgress());
  });

  group('HistoryRequested', () {
    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'emits in-progress then the seven points',
      setUp: () => stubHistory(success(usdHistory)),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        HistoryLoadSuccess(points: usdHistory),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'asks for seven days of the requested currency',
      setUp: () => stubHistory(success(historyFor(Currency.jpy))),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.jpy)),
      verify: (_) {
        final arguments = verify(
          () => repository.getHistory(
            captureAny(),
            days: captureAny(named: 'days'),
          ),
        ).captured;
        expect(arguments, [Currency.jpy, 7]);
      },
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'passes the points through untouched',
      setUp: () => stubHistory(success(usdHistory)),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      verify: (bloc) {
        final state = bloc.state as HistoryLoadSuccess;
        expect(identical(state.points, usdHistory), isTrue);
      },
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'emits empty when no day could be plotted',
      setUp: () => stubHistory(success(const [])),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        const HistoryLoadEmpty(),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'emits empty when a single point cannot make a line',
      setUp: () => stubHistory(success([usdHistory.first])),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        const HistoryLoadEmpty(),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'emits failure carrying the failure type',
      setUp: () => stubHistory(
        failed(const RateUnavailableFailure(requestedDate: '2024-03-03')),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        const HistoryLoadFailure(
          failure: RateUnavailableFailure(requestedDate: '2024-03-03'),
        ),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'retrying from the failure state loads the chart',
      setUp: () => stubHistory(success(usdHistory)),
      build: buildBloc,
      seed: () => const HistoryLoadFailure(failure: NetworkFailure()),
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        HistoryLoadSuccess(points: usdHistory),
      ],
    );

    blocTest<CurrencyDetailBloc, CurrencyDetailState>(
      'reloading a loaded chart shows the skeleton again',
      setUp: () => stubHistory(success(usdHistory)),
      build: buildBloc,
      seed: () => HistoryLoadSuccess(points: usdHistory),
      act: (bloc) => bloc.add(const HistoryRequested(Currency.usd)),
      expect: () => [
        const HistoryLoadInProgress(),
        HistoryLoadSuccess(points: usdHistory),
      ],
    );
  });
}

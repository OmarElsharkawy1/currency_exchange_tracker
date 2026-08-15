import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/trend_colors.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/rates_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MockRatesListBloc extends MockBloc<RatesListEvent, RatesListState>
    implements RatesListBloc {}

RateComparison comparison(
  Currency currency, {
  required double rawRate,
  double? previousRawRate,
}) {
  return RateComparison(
    current: ExchangeRate(
      currency: currency,
      rawRate: rawRate,
      date: DateTime.utc(2024, 3, 6),
    ),
    previous: previousRawRate == null
        ? null
        : ExchangeRate(
            currency: currency,
            rawRate: previousRawRate,
            date: DateTime.utc(2024, 3, 5),
          ),
  );
}

/// USD: raw fell, so a dollar costs more pounds — the pound weakened.
final RateComparison weakeningUsd = comparison(
  Currency.usd,
  rawRate: 0.019100,
  previousRawRate: 0.019227,
);

/// EUR: the mirror case — the pound strengthened.
final RateComparison strengtheningEur = comparison(
  Currency.eur,
  rawRate: 0.019227,
  previousRawRate: 0.019100,
);

final lastUpdated = DateTime(2024, 3, 6, 9, 5);

void main() {
  setUpAll(() {
    registerFallbackValue(const RatesRequested());
  });

  late MockRatesListBloc bloc;

  setUp(() {
    bloc = MockRatesListBloc();
  });

  Future<void> pumpPage(WidgetTester tester, RatesListState state) async {
    bloc = MockRatesListBloc();
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<RatesListBloc>.value(
          value: bloc,
          child: const RatesListPage(),
        ),
      ),
    );
  }

  group('while loading', () {
    testWidgets('shows skeleton rows, never a spinner', (tester) async {
      await pumpPage(tester, const RatesLoadInProgress());

      final skeletonizer = tester
          .widgetList<Skeletonizer>(
            find.byWidgetPredicate((widget) => widget is Skeletonizer),
          )
          .single;
      expect(skeletonizer.enabled, isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('with rates', () {
    testWidgets('states the rate as a sentence', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('US Dollar'), findsOneWidget);
    });

    testWidgets('shows the absolute and percentage movement', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.text('+0.35'), findsOneWidget);
      expect(find.text('+0.66%'), findsOneWidget);
    });

    testWidgets('paints a weakening pound with the weakening color', (
      tester,
    ) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      final percent = tester.widget<Text>(find.text('+0.66%'));
      expect(percent.style?.color, TrendColors.light.weakening);
    });

    testWidgets('paints a strengthening pound with the strengthening color', (
      tester,
    ) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [strengtheningEur],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      final percent = tester.widget<Text>(find.text('-0.66%'));
      expect(percent.style?.color, TrendColors.light.strengthening);
    });

    testWidgets('labels each row for a screen reader', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(
        find.bySemanticsLabel(
          'US Dollar, 52.36 Egyptian pounds, up 0.66 '
          'percent',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says unchanged when there is no previous day', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [comparison(Currency.usd, rawRate: 0.019100)],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(
        find.bySemanticsLabel('US Dollar, 52.36 Egyptian pounds, unchanged'),
        findsOneWidget,
      );
    });

    testWidgets('renders one row per currency', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd, strengtheningEur],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.text('US Dollar'), findsOneWidget);
      expect(find.text('Euro'), findsOneWidget);
    });

    testWidgets('shows when the data was last updated', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.textContaining('Mar 6, 09:05'), findsOneWidget);
    });

    testWidgets('says so when the rates came from the cache', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: true,
        ),
      );

      expect(find.textContaining('Offline'), findsOneWidget);
    });

    testWidgets('pulling down asks for a refresh', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd, strengtheningEur],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => bloc.add(const RatesRefreshed())).called(1);
    });
  });

  group('when empty', () {
    testWidgets('explains that there is nothing to show', (tester) async {
      await pumpPage(tester, const RatesLoadEmpty());

      expect(find.textContaining('No rates'), findsOneWidget);
    });
  });

  group('when it fails', () {
    testWidgets('shows a friendly message, never the exception', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const RatesLoadFailure(failure: NetworkFailure(statusCode: 500)),
      );

      expect(find.textContaining('connect'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('500'), findsNothing);
    });

    testWidgets('maps each failure type to its own message', (tester) async {
      await pumpPage(tester, const RatesLoadFailure(failure: TimeoutFailure()));
      expect(find.textContaining('took too long'), findsOneWidget);

      await pumpPage(
        tester,
        const RatesLoadFailure(failure: RateUnavailableFailure()),
      );
      expect(find.textContaining('not published'), findsOneWidget);

      await pumpPage(tester, const RatesLoadFailure(failure: ParseFailure()));
      expect(find.textContaining("couldn't be read"), findsOneWidget);
    });

    testWidgets('retrying asks for a refresh', (tester) async {
      await pumpPage(
        tester,
        const RatesLoadFailure(failure: NetworkFailure()),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => bloc.add(const RatesRefreshed())).called(1);
    });
  });
}

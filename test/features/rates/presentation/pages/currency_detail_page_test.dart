import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_button.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_scope.dart';
import 'package:currency_exchange_tracker/core/theme/trend_colors.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/currency_detail_page.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MockCurrencyDetailBloc
    extends MockBloc<CurrencyDetailEvent, CurrencyDetailState>
    implements CurrencyDetailBloc {}

ExchangeRate rateOn(int day, double rawRate) => ExchangeRate(
  currency: Currency.usd,
  rawRate: rawRate,
  date: DateTime.utc(2024, 3, day),
);

/// The pound weakened: a dollar costs more pounds than yesterday.
final RateComparison weakeningUsd = RateComparison(
  current: rateOn(6, 0.019100),
  previous: rateOn(5, 0.019227),
);

final List<ExchangeRate> history = [
  rateOn(1, 0.019300),
  rateOn(2, 0.019250),
  rateOn(3, 0.019227),
  rateOn(4, 0.019200),
  rateOn(5, 0.019227),
  rateOn(6, 0.019100),
];

void main() {
  setUpAll(() {
    registerFallbackValue(const HistoryRequested(Currency.usd));
  });

  late MockCurrencyDetailBloc bloc;
  late ThemeModeController themeMode;

  setUp(() => themeMode = ThemeModeController());

  tearDown(() => themeMode.dispose());

  Future<void> pumpPage(
    WidgetTester tester,
    CurrencyDetailState state, {
    RateComparison? comparison,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    bloc = MockCurrencyDetailBloc();
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: textDirection,
          child: ThemeModeScope(
            controller: themeMode,
            child: BlocProvider<CurrencyDetailBloc>.value(
              value: bloc,
              child: CurrencyDetailPage(comparison: comparison ?? weakeningUsd),
            ),
          ),
        ),
      ),
    );
  }

  group('header — rendered from the entity the route carried', () {
    testWidgets('shows the rate before any history arrives', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('US Dollar'), findsOneWidget);
    });

    testWidgets('shows the movement and its direction color', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      final percent = tester.widget<Text>(find.text('+0.66%'));
      expect(percent.style?.color, TrendColors.light.weakening);
      expect(find.text('+0.35'), findsOneWidget);
    });

    testWidgets('shows the day the rate belongs to', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(find.textContaining('Mar 6, 2024'), findsOneWidget);
    });

    testWidgets('never shows a loading state of its own', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The header is outside the skeletonized subtree.
      expect(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is Skeletonizer),
          matching: find.text('1 USD = 52.36 EGP'),
        ),
        findsNothing,
      );
    });

    testWidgets('carries the currency code in a hero', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, CurrencyDetailPage.heroTagFor(Currency.usd));
    });
  });

  group('the theme switch', () {
    testWidgets('is on this screen too, not just the list', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(find.byType(ThemeModeButton), findsOneWidget);
    });

    testWidgets('cycles from here as well', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      await tester.tap(find.byType(ThemeModeButton));
      await tester.pump();

      expect(themeMode.value, ThemeMode.light);
    });
  });

  group('while the history loads', () {
    testWidgets('shows a chart-shaped skeleton, not a spinner', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(
        find.byWidgetPredicate((widget) => widget is Skeletonizer),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('with history', () {
    testWidgets('draws the chart', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      expect(find.byType(LineChart), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) => widget is Skeletonizer),
        findsNothing,
      );
    });

    testWidgets('plots one spot per published day', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.length, history.length);
    });

    testWidgets('fills the area under the line with a gradient', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final bar = chart.data.lineBarsData.single;
      expect(bar.belowBarData.show, isTrue);
      expect(bar.belowBarData.gradient, isNotNull);
    });

    testWidgets('plots the inverted display rate, never the raw quote', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final spots = chart.data.lineBarsData.single.spots;
      expect(spots.last.y, closeTo(52.3560, 1e-3));
      expect(spots.first.y, closeTo(51.8135, 1e-3));
    });
  });

  group('bottom axis labels', () {
    /// A series that crosses a month boundary.
    final acrossMonths = [
      ExchangeRate(
        currency: Currency.usd,
        rawRate: 0.019300,
        date: DateTime.utc(2024, 2, 27),
      ),
      ExchangeRate(
        currency: Currency.usd,
        rawRate: 0.019250,
        date: DateTime.utc(2024, 2, 28),
      ),
      ExchangeRate(
        currency: Currency.usd,
        rawRate: 0.019227,
        date: DateTime.utc(2024, 2, 29),
      ),
      ExchangeRate(
        currency: Currency.usd,
        rawRate: 0.019200,
        date: DateTime.utc(2024, 3),
      ),
      ExchangeRate(
        currency: Currency.usd,
        rawRate: 0.019100,
        date: DateTime.utc(2024, 3, 2),
      ),
    ];

    testWidgets('labels every plotted day', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      expect(
        find.byType(SideTitleWidget),
        findsNWidgets(history.length),
      );
    });

    testWidgets('keeps edge labels inside the chart', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));
      // fitInside measures its child in a post-frame callback and translates
      // on the frame after that.
      await tester.pump();

      final chart = tester.getRect(find.byType(LineChart));
      // The painted text is what must stay inside: fitInside translates the
      // child, leaving the wrapper's own box centred on its tick.
      final labels = find.descendant(
        of: find.byType(SideTitleWidget),
        matching: find.byType(Text),
      );
      expect(labels, findsNWidgets(history.length));
      for (final label in labels.evaluate()) {
        final rect = tester.getRect(find.byWidget(label.widget));
        expect(rect.left, greaterThanOrEqualTo(chart.left));
        expect(rect.right, lessThanOrEqualTo(chart.right));
      }
    });

    testWidgets('names the month on the first label only', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      // History runs Mar 1..Mar 6, so only the first label carries a month.
      expect(find.text('Mar 1'), findsOneWidget);
      for (final day in ['2', '3', '4', '5', '6']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(find.text('Mar 2'), findsNothing);
    });

    testWidgets('names the month again when the month changes', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: acrossMonths));

      expect(find.text('Feb 27'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);
      expect(find.text('Mar 1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('insets the chart by the same token as the header', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(LineChart),
              matching: find.byType(Padding),
            )
            .first,
      );
      final insets = padding.padding as EdgeInsetsDirectional;
      expect(insets.start, AppSpacing.pageHorizontal);
      expect(insets.end, AppSpacing.pageHorizontal);
    });

    testWidgets('the first dot starts at the header leading edge', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      final chart = tester.getRect(find.byType(LineChart));
      final rate = tester.getRect(find.text('1 USD = 52.36 EGP'));
      expect(chart.left, closeTo(AppSpacing.pageHorizontal, 0.5));
      expect(rate.left, greaterThanOrEqualTo(chart.left));
    });
  });

  group('right-to-left', () {
    testWidgets('plots time left to right regardless of text direction', (
      tester,
    ) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(points: history),
        textDirection: TextDirection.rtl,
      );

      // The axis is data, not prose: oldest stays leftmost, exactly as in LTR.
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final spots = chart.data.lineBarsData.single.spots;
      expect(spots.first.y, closeTo(51.8135, 1e-3));
      expect(spots.last.y, closeTo(52.3560, 1e-3));
    });

    testWidgets('still labels every day, month named at the oldest', (
      tester,
    ) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(points: history),
        textDirection: TextDirection.rtl,
      );

      expect(find.byType(SideTitleWidget), findsNWidgets(history.length));
      expect(find.text('Mar 1'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('keeps edge labels inside the chart', (tester) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(points: history),
        textDirection: TextDirection.rtl,
      );
      await tester.pump();

      final chart = tester.getRect(find.byType(LineChart));
      // The painted text is what must stay inside: fitInside translates the
      // child, leaving the wrapper's own box centred on its tick.
      final labels = find.descendant(
        of: find.byType(SideTitleWidget),
        matching: find.byType(Text),
      );
      expect(labels, findsNWidgets(history.length));
      for (final label in labels.evaluate()) {
        final rect = tester.getRect(find.byWidget(label.widget));
        expect(rect.left, greaterThanOrEqualTo(chart.left));
        expect(rect.right, lessThanOrEqualTo(chart.right));
      }
    });

    testWidgets('scrubs the day the finger is actually on', (tester) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(points: history),
        textDirection: TextDirection.rtl,
      );

      tester
          .widget<RateHistoryChart>(find.byType(RateHistoryChart))
          .onPointScrubbed(history.first);
      await tester.pump();

      expect(find.textContaining('Mar 1, 2024'), findsOneWidget);
    });
  });

  group('scrubbing', () {
    testWidgets('shows the touched point in the header', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      final chart = tester.widget<RateHistoryChart>(
        find.byType(RateHistoryChart),
      );
      chart.onPointScrubbed(history.first);
      await tester.pump();

      expect(find.text('1 USD = 51.81 EGP'), findsOneWidget);
      expect(find.textContaining('Mar 1, 2024'), findsOneWidget);
    });

    testWidgets('hides the day movement while scrubbing', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      tester
          .widget<RateHistoryChart>(find.byType(RateHistoryChart))
          .onPointScrubbed(history.first);
      await tester.pump();

      expect(find.text('+0.66%'), findsNothing);
    });

    testWidgets('reverts to the current rate on release', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(points: history));

      final chart = tester.widget<RateHistoryChart>(
        find.byType(RateHistoryChart),
      );
      chart.onPointScrubbed(history.first);
      await tester.pump();
      chart.onPointScrubbed(null);
      await tester.pump();

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('+0.66%'), findsOneWidget);
    });
  });

  group('when the history fails', () {
    testWidgets('keeps the header rate on screen', (tester) async {
      await pumpPage(
        tester,
        const HistoryLoadFailure(failure: NetworkFailure()),
      );

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('+0.66%'), findsOneWidget);
    });

    testWidgets('shows a friendly message, never the exception', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const HistoryLoadFailure(failure: TimeoutFailure()),
      );

      expect(find.textContaining('took too long'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
    });

    testWidgets('retrying asks for the history again', (tester) async {
      await pumpPage(
        tester,
        const HistoryLoadFailure(failure: NetworkFailure()),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(
        () => bloc.add(const HistoryRequested(Currency.usd)),
      ).called(1);
    });
  });

  group('when the history is too short to plot', () {
    testWidgets('explains it and keeps the header', (tester) async {
      await pumpPage(tester, const HistoryLoadEmpty());

      expect(find.textContaining('No history'), findsOneWidget);
      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
    });
  });
}

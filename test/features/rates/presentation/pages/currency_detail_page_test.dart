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
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/currency_detail_page.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

/// Seven plotted days, every one with a predecessor.
final RateHistory sevenDays = RateHistory(
  points: [
    RateHistoryPoint(rate: rateOn(1, 0.019300), previous: rateOn(0, 0.019310)),
    RateHistoryPoint(rate: rateOn(2, 0.019250), previous: rateOn(1, 0.019300)),
    RateHistoryPoint(rate: rateOn(3, 0.019227), previous: rateOn(2, 0.019250)),
    RateHistoryPoint(rate: rateOn(4, 0.019200), previous: rateOn(3, 0.019227)),
    RateHistoryPoint(rate: rateOn(5, 0.019227), previous: rateOn(4, 0.019200)),
    RateHistoryPoint(rate: rateOn(6, 0.019100), previous: rateOn(5, 0.019227)),
    RateHistoryPoint(rate: rateOn(7, 0.019050), previous: rateOn(6, 0.019100)),
  ],
);

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
              child: CurrencyDetailPage(comparison: weakeningUsd),
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData barOf(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.single;

  group('the header before history arrives', () {
    testWidgets('renders the route rate immediately', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('+0.35'), findsOneWidget);
      expect(find.text('+0.66%'), findsOneWidget);
      expect(find.textContaining('Mar 6, 2024'), findsOneWidget);
    });

    testWidgets('colors the movement by direction', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      final percent = tester.widget<Text>(find.text('+0.66%'));
      expect(percent.style?.color, TrendColors.light.weakening);
    });

    testWidgets('survives a failed load with the rate still on screen', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const HistoryLoadFailure(failure: NetworkFailure()),
      );

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('+0.66%'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('the header is one widget', () {
    /// The rendered header, as (rate text, change, percent, date) styles.
    List<TextStyle?> headerStyles(WidgetTester tester) => [
      tester.widget<Text>(find.textContaining('1 USD =')).style,
      tester.widget<Text>(find.textContaining('%')).style,
      tester.widget<Text>(find.textContaining(', 2024')).style,
    ];

    testWidgets('renders resting and selected days through the same styles', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));
      final resting = headerStyles(tester);

      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays, selectedIndex: 3),
      );
      final selected = headerStyles(tester);

      expect(selected, resting);
    });

    testWidgets('shows the selected day, not the latest', (tester) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays, selectedIndex: 0),
      );

      expect(find.text('1 USD = 51.81 EGP'), findsOneWidget);
      expect(find.textContaining('Mar 1, 2024'), findsOneWidget);
    });

    testWidgets('keeps the movement slot when a day has no predecessor', (
      tester,
    ) async {
      final orphan = RateHistory(
        points: [
          RateHistoryPoint(rate: rateOn(1, 0.019300)),
          RateHistoryPoint(
            rate: rateOn(2, 0.019250),
            previous: rateOn(1, 0.019300),
          ),
        ],
      );

      await pumpPage(
        tester,
        HistoryLoadSuccess(history: orphan, selectedIndex: 0),
      );

      // Two em-dashes: one for the change, one for the percentage.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('does not move the rate line when the movement is unknown', (
      tester,
    ) async {
      // Both days are selected, so the chip is present either way: the only
      // difference is that one has a predecessor and one does not.
      final orphan = RateHistory(
        points: [
          RateHistoryPoint(rate: rateOn(1, 0.019300)),
          RateHistoryPoint(
            rate: rateOn(2, 0.019250),
            previous: rateOn(1, 0.019300),
          ),
          RateHistoryPoint(
            rate: rateOn(3, 0.019227),
            previous: rateOn(2, 0.019250),
          ),
        ],
      );

      await pumpPage(
        tester,
        HistoryLoadSuccess(history: orphan, selectedIndex: 1),
      );
      final withMovement = tester.getTopLeft(find.textContaining('1 USD ='));

      await pumpPage(
        tester,
        HistoryLoadSuccess(history: orphan, selectedIndex: 0),
      );

      expect(tester.getTopLeft(find.textContaining('1 USD =')), withMovement);
    });

    testWidgets('the chip appearing does not move the rate line either', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));
      final resting = tester.getTopLeft(find.textContaining('1 USD ='));

      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays, selectedIndex: 2),
      );

      expect(tester.getTopLeft(find.textContaining('1 USD =')), resting);
    });
  });

  group('the Latest chip', () {
    testWidgets('is hidden while the latest day is showing', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      expect(find.text('Latest'), findsNothing);
    });

    testWidgets('appears once an older day is selected', (tester) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays, selectedIndex: 2),
      );

      expect(find.text('Latest'), findsOneWidget);
    });

    testWidgets('clears the selection when tapped', (tester) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays, selectedIndex: 2),
      );

      await tester.tap(find.text('Latest'));
      await tester.pump();

      verify(() => bloc.add(const HistoryPointCleared())).called(1);
    });
  });

  group('the chart', () {
    testWidgets('plots one visible dot per day', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      final bar = barOf(tester);
      expect(bar.spots.length, 7);
      expect(bar.dotData.show, isTrue);
    });

    testWidgets('keeps the gradient fill', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      expect(barOf(tester).belowBarData.show, isTrue);
      expect(barOf(tester).belowBarData.gradient, isNotNull);
    });

    testWidgets('plots the inverted display rate, never the raw quote', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      final spots = barOf(tester).spots;
      expect(spots.first.y, closeTo(51.8135, 1e-3));
      expect(spots.last.y, closeTo(52.4934, 1e-3));
    });

    testWidgets('draws the selected dot larger, ringed in its trend color', (
      tester,
    ) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays, selectedIndex: 5),
      );

      final bar = barOf(tester);
      final resting =
          bar.dotData.getDotPainter(bar.spots[0], 0, bar, 0)
              as FlDotCirclePainter;
      final selected =
          bar.dotData.getDotPainter(bar.spots[5], 0, bar, 5)
              as FlDotCirclePainter;

      expect(selected.radius, greaterThan(resting.radius));
      expect(selected.strokeColor, TrendColors.light.weakening);
    });

    testWidgets('marks the selection with an indicator line', (tester) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays, selectedIndex: 4),
      );

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.extraLinesData.verticalLines.single.x, 4);
    });

    testWidgets('draws no indicator line while resting', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.extraLinesData.verticalLines, isEmpty);
    });

    testWidgets('leaves the built-in tooltip off — the header is the readout', (
      tester,
    ) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineTouchData.handleBuiltInTouches, isFalse);
      expect(
        chart.data.lineTouchData.touchSpotThreshold,
        greaterThanOrEqualTo(24),
      );
    });

    testWidgets('summarises its range for a screen reader', (tester) async {
      final handle = SemanticsBinding.instance.ensureSemantics();
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      expect(
        find.bySemanticsLabel(
          '7-day chart, from 51.81 to 52.49 Egyptian pounds',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('chart touches reach the bloc', () {
    RateHistoryChart chartOf(WidgetTester tester) =>
        tester.widget<RateHistoryChart>(find.byType(RateHistoryChart));

    testWidgets('a tap selects the day', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      chartOf(tester).onPointTapped(3);

      verify(() => bloc.add(const HistoryPointSelected(3))).called(1);
    });

    testWidgets('a drag scrubs', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      chartOf(tester).onScrubbed(1);

      verify(() => bloc.add(const HistoryScrubbed(1))).called(1);
    });

    testWidgets('a release ends the scrub', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

      chartOf(tester).onScrubEnded();

      verify(() => bloc.add(const HistoryScrubEnded())).called(1);
    });
  });

  group('the other chart states', () {
    testWidgets('shows a chart-shaped skeleton while loading', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(
        find.byWidgetPredicate((widget) => widget is Skeletonizer),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('explains a history too short to plot', (tester) async {
      await pumpPage(tester, const HistoryLoadEmpty());

      expect(find.textContaining('No history'), findsOneWidget);
      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
    });

    testWidgets('maps a failure to friendly copy and a retry', (tester) async {
      await pumpPage(
        tester,
        const HistoryLoadFailure(failure: TimeoutFailure()),
      );

      expect(find.textContaining('took too long'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(
        () => bloc.add(const HistoryRequested(Currency.usd)),
      ).called(1);
    });
  });

  group('chrome', () {
    testWidgets('carries the currency code in a hero', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, CurrencyDetailPage.heroTagFor(Currency.usd));
    });

    testWidgets('offers the theme switch', (tester) async {
      await pumpPage(tester, const HistoryLoadInProgress());

      expect(find.byType(ThemeModeButton), findsOneWidget);
    });

    testWidgets('insets the chart by the shared page token', (tester) async {
      await pumpPage(tester, HistoryLoadSuccess(history: sevenDays));

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
  });

  group('right-to-left', () {
    testWidgets('plots time left to right regardless of text direction', (
      tester,
    ) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays),
        textDirection: TextDirection.rtl,
      );

      final spots = barOf(tester).spots;
      expect(spots.first.y, closeTo(51.8135, 1e-3));
      expect(spots.last.y, closeTo(52.4934, 1e-3));
    });

    testWidgets('keeps every label inside the plot', (tester) async {
      await pumpPage(
        tester,
        HistoryLoadSuccess(history: sevenDays),
        textDirection: TextDirection.rtl,
      );
      await tester.pump();

      final chart = tester.getRect(find.byType(LineChart));
      final labels = find.descendant(
        of: find.byType(SideTitleWidget),
        matching: find.byType(Text),
      );
      expect(labels, findsNWidgets(7));
      for (final label in labels.evaluate()) {
        final rect = tester.getRect(find.byWidget(label.widget));
        expect(rect.left, greaterThanOrEqualTo(chart.left));
        expect(rect.right, lessThanOrEqualTo(chart.right));
      }
    });
  });
}

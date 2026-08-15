import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_scope.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/formatting/rate_semantics.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/currency_detail_page.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCurrencyDetailBloc
    extends MockBloc<CurrencyDetailEvent, CurrencyDetailState>
    implements CurrencyDetailBloc {}

ExchangeRate rateOn(int day, double rawRate) => ExchangeRate(
  currency: Currency.usd,
  rawRate: rawRate,
  date: DateTime.utc(2024, 3, day),
);

/// The pound weakened: a dollar costs more pounds than the day before.
final RateComparison weakeningUsd = RateComparison(
  current: rateOn(6, 0.019100),
  previous: rateOn(5, 0.019227),
);

final RateHistoryPoint weakeningPoint = RateHistoryPoint(
  rate: rateOn(6, 0.019100),
  previous: rateOn(5, 0.019227),
);

void main() {
  group('the phrasing itself', () {
    test('reads rate then movement', () {
      expect(
        RateSemantics.describe(weakeningPoint),
        'US Dollar, 52.36 Egyptian pounds, up 0.66 percent',
      );
    });

    test('a strengthening pound reads as down', () {
      expect(
        RateSemantics.describe(
          RateHistoryPoint(
            rate: rateOn(6, 0.019227),
            previous: rateOn(5, 0.019100),
          ),
        ),
        'US Dollar, 52.01 Egyptian pounds, down 0.66 percent',
      );
    });

    test('a day with no predecessor is unchanged, not zero percent', () {
      expect(
        RateSemantics.describe(RateHistoryPoint(rate: rateOn(1, 0.019300))),
        'US Dollar, 51.81 Egyptian pounds, unchanged',
      );
    });

    test('an unmoved day is unchanged', () {
      expect(
        RateSemantics.describe(
          RateHistoryPoint(
            rate: rateOn(6, 0.019227),
            previous: rateOn(5, 0.019227),
          ),
        ),
        'US Dollar, 52.01 Egyptian pounds, unchanged',
      );
    });
  });

  group('both screens say the same thing', () {
    late SemanticsHandle semantics;
    late ThemeModeController themeMode;

    setUp(() {
      semantics = SemanticsBinding.instance.ensureSemantics();
      themeMode = ThemeModeController();
    });

    tearDown(() {
      semantics.dispose();
      themeMode.dispose();
    });

    Future<void> pumpRow(WidgetTester tester, RateComparison comparison) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: RateRow(comparison: comparison)),
        ),
      );
    }

    Future<void> pumpHeader(
      WidgetTester tester,
      RateComparison comparison,
    ) async {
      final bloc = MockCurrencyDetailBloc();
      when(() => bloc.state).thenReturn(const HistoryLoadInProgress());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ThemeModeScope(
            controller: themeMode,
            child: BlocProvider<CurrencyDetailBloc>.value(
              value: bloc,
              child: CurrencyDetailPage(comparison: comparison),
            ),
          ),
        ),
      );
    }

    testWidgets('for a day that moved', (tester) async {
      const expected = 'US Dollar, 52.36 Egyptian pounds, up 0.66 percent';

      await pumpRow(tester, weakeningUsd);
      expect(find.bySemanticsLabel(expected), findsOneWidget);

      await pumpHeader(tester, weakeningUsd);
      expect(find.bySemanticsLabel(expected), findsOneWidget);
    });

    testWidgets('for a day with nothing to compare against', (tester) async {
      final orphan = RateComparison(current: rateOn(1, 0.019300));
      const expected = 'US Dollar, 51.81 Egyptian pounds, unchanged';

      await pumpRow(tester, orphan);
      expect(find.bySemanticsLabel(expected), findsOneWidget);

      // The same day on the detail screen, where the movement renders as an
      // em-dash rather than a number.
      await pumpHeader(tester, orphan);
      expect(find.bySemanticsLabel(expected), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
    });
  });

  group('the shared function is the only implementation', () {
    test('history points and list comparisons describe identically', () {
      final fromHistory = RateSemantics.describe(weakeningPoint);
      final fromList = RateSemantics.describe(
        RateHistoryPoint(
          rate: weakeningUsd.current,
          previous: weakeningUsd.previous,
        ),
      );

      expect(fromList, fromHistory);
    });

    test('a history and a list view of the same day agree', () {
      final history = RateHistory(points: [weakeningPoint]);

      expect(
        RateSemantics.describe(history.latest),
        RateSemantics.describe(weakeningPoint),
      );
    });
  });
}

import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart_skeleton.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/phone_surface.dart';

final RateHistory sevenDays = RateHistory(
  points: [
    for (var day = 1; day <= 7; day++)
      RateHistoryPoint(
        rate: ExchangeRate(
          currency: Currency.usd,
          rawRate: 0.0193 - day * 0.00003,
          date: DateTime.utc(2024, 3, day),
        ),
        previous: ExchangeRate(
          currency: Currency.usd,
          rawRate: 0.0193 - (day - 1) * 0.00003,
          date: DateTime.utc(2024, 3, day - 1),
        ),
      ),
  ],
);

void main() {
  /// The chart and its placeholder live in the same padded slot on screen.
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: child,
      ),
    ),
  );

  for (final size in PhoneSurface.all) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    group('at $label', () {
      testWidgets('the skeleton lays out without overflowing', (tester) async {
        tester.usePhoneSurface(size);

        await tester.pumpWidget(host(const RateHistoryChartSkeleton()));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('the chart lays out without overflowing', (tester) async {
        tester.usePhoneSurface(size);

        await tester.pumpWidget(
          host(
            RateHistoryChart(
              history: sevenDays,
              selectedIndex: null,
              onPointTapped: (_) {},
              onScrubbed: (_) {},
              onScrubEnded: () {},
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('the placeholder plot starts where the real one does', (
        tester,
      ) async {
        tester.usePhoneSurface(size);

        await tester.pumpWidget(host(const RateHistoryChartSkeleton()));
        await tester.pump();
        // The silhouette's own left edge: everything left of it is the
        // reserved value column.
        final skeletonPlot = tester.getRect(
          find.byType(RateHistoryChartSkeleton),
        );

        await tester.pumpWidget(
          host(
            RateHistoryChart(
              history: sevenDays,
              selectedIndex: null,
              onPointTapped: (_) {},
              onScrubbed: (_) {},
              onScrubEnded: () {},
            ),
          ),
        );
        await tester.pump();
        final chartPlot = tester.getRect(find.byType(LineChart));

        expect(
          skeletonPlot.left + RateHistoryChart.axisValueWidth,
          chartPlot.left + RateHistoryChart.axisValueWidth,
          reason: 'both reserve the same value column, so the plot aligns',
        );
        expect(skeletonPlot.left, chartPlot.left);
        expect(skeletonPlot.width, chartPlot.width);
      });
    });
  }
}

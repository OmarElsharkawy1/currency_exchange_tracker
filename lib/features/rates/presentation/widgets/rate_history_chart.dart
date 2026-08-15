import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// The 7-day line chart.
///
/// Plots `displayRate` — the value the screen talks about — never the raw
/// quote. Dragging across it reports the touched day through
/// [onPointScrubbed]; releasing reports `null`.
class RateHistoryChart extends StatelessWidget {
  /// Creates the chart for [points], oldest first.
  const RateHistoryChart({
    required this.points,
    required this.onPointScrubbed,
    super.key,
  });

  /// The published days, oldest first.
  final List<ExchangeRate> points;

  /// Called with the touched day while scrubbing, and `null` on release.
  final ValueChanged<ExchangeRate?> onPointScrubbed;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.colors.primary;

    return LineChart(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      LineChartData(
        minY: _bounds.min,
        maxY: _bounds.max,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.colors.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _labelInterval,
              reservedSize: 28,
              getTitlesWidget: (value, meta) =>
                  _DayLabel(date: points[value.toInt()].date),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchCallback: _onTouch,
          getTouchedSpotIndicator: (barData, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                FlLine(color: lineColor, strokeWidth: 1),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: lineColor,
                        strokeColor: context.colors.surface,
                        strokeWidth: 2,
                      ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            // The header is the readout; a tooltip would say it twice.
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItems: (spots) => List<LineTooltipItem?>.filled(
              spots.length,
              null,
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var index = 0; index < points.length; index++)
                FlSpot(index.toDouble(), points[index].displayRate),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.28),
                  lineColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Only the first and last day get a label; seven would collide.
  double get _labelInterval => (points.length - 1).toDouble();

  /// A little headroom either side so the line never touches the frame.
  ({double min, double max}) get _bounds {
    final values = points.map((point) => point.displayRate).toList()..sort();
    final lowest = values.first;
    final highest = values.last;
    final padding = (highest - lowest) * 0.15;
    return (min: lowest - padding, max: highest + padding);
  }

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    final index = response?.lineBarSpots?.firstOrNull?.spotIndex;
    onPointScrubbed(
      switch (event.isInterestedForInteractions) {
        false => null,
        true => switch (index) {
          null => null,
          final spotIndex => points[spotIndex],
        },
      },
    );
  }
}

/// One date label under the chart.
class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8),
      child: Text(
        RateFormatter.chartDay(date),
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

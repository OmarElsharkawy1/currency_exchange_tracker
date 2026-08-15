import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// The history line chart.
///
/// Plots `displayRate` — the value the screen talks about — never the raw
/// quote. Every day is a visible dot, so the points are findable without
/// hunting for them with a finger. Touching one reports it upward; the header
/// is the readout, so the built-in tooltip is off.
///
/// Time always runs left to right, in every locale: the axis is data, not
/// prose. Only the labels, insets and surrounding chrome follow the text
/// direction.
class RateHistoryChart extends StatelessWidget {
  /// Creates the chart for [history].
  const RateHistoryChart({
    required this.history,
    required this.selectedIndex,
    required this.onPointTapped,
    required this.onScrubbed,
    required this.onScrubEnded,
    super.key,
  });

  /// The plotted days, oldest first.
  final RateHistory history;

  /// The day currently read out, or `null` when the latest is showing.
  final int? selectedIndex;

  /// Called when a dot is tapped.
  final ValueChanged<int> onPointTapped;

  /// Called repeatedly while a finger is dragged across the chart.
  final ValueChanged<int> onScrubbed;

  /// Called when the finger lifts.
  final VoidCallback onScrubEnded;

  /// How far from a dot a touch still counts as that dot.
  static const double touchThreshold = 24;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.colors.primary;
    final bounds = _bounds;

    return Semantics(
      container: true,
      // Without this the axis labels merge into the summary and a screen
      // reader announces "…Egyptian pounds, Mar 1, 2, 3, 4…".
      excludeSemantics: true,
      label: _semanticsLabel,
      child: LineChart(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        LineChartData(
          minY: bounds.min,
          maxY: bounds.max,
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
                // Every plotted day gets a label.
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) =>
                    _DayLabel(meta: meta, label: _labelAt(value.toInt())),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              for (final index in _selectedIndexes)
                VerticalLine(
                  x: index.toDouble(),
                  color: context.colors.outline,
                  strokeWidth: 1,
                  dashArray: const [4, 3],
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchSpotThreshold: touchThreshold,
            // The header is the readout: no tooltip, no built-in highlight.
            handleBuiltInTouches: false,
            touchCallback: _onTouch,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var index = 0; index < history.length; index++)
                  FlSpot(index.toDouble(), history.points[index].displayRate),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: lineColor,
              barWidth: 2.5,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    _dotFor(context, index),
              ),
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
      ),
    );
  }

  /// The selected index as a list, so the indicator line is a comprehension
  /// rather than a conditional.
  Iterable<int> get _selectedIndexes => switch (selectedIndex) {
    null => const <int>[],
    final index => [index],
  };

  /// The dot for the day at [index]: small and filled, or ringed in its own
  /// trend colour when it is the day being read out.
  FlDotPainter _dotFor(BuildContext context, int index) {
    final isSelected = index == selectedIndex;
    return switch (isSelected) {
      // No ring on a resting dot; fl_chart's zero stroke width is the
      // default and saying so again trips the linter.
      false => FlDotCirclePainter(radius: 3, color: context.colors.primary),
      true => FlDotCirclePainter(
        radius: 6,
        color: context.colors.surface,
        strokeWidth: 3,
        strokeColor: _trendColor(context, history.points[index].direction),
      ),
    };
  }

  Color _trendColor(BuildContext context, RateDirection direction) =>
      switch (direction) {
        RateDirection.egpWeakening => context.trendColors.weakening,
        RateDirection.egpStrengthening => context.trendColors.strengthening,
        RateDirection.flat => context.colors.primary,
      };

  /// What a screen reader announces for the chart as a whole.
  String get _semanticsLabel {
    final oldest = RateFormatter.spokenRate(history.points.first.displayRate);
    final newest = RateFormatter.spokenRate(history.latest.displayRate);
    return '${history.length}-day chart, from $oldest to $newest Egyptian '
        'pounds';
  }

  /// The label for the day at [index].
  ///
  /// The oldest day is always leftmost and always index 0, so "name the month
  /// at the start, and again whenever the series crosses into a new one" is a
  /// comparison with the day before it.
  String _labelAt(int index) {
    final date = history.points[index].date;
    final namesItsMonth =
        index == 0 || date.month != history.points[index - 1].date.month;
    return switch (namesItsMonth) {
      true => RateFormatter.chartDay(date),
      false => RateFormatter.chartDayOfMonth(date),
    };
  }

  /// A little headroom either side so the line never touches the frame.
  ({double min, double max}) get _bounds {
    final values = history.points.map((point) => point.displayRate).toList()
      ..sort();
    final lowest = values.first;
    final highest = values.last;
    final padding = (highest - lowest) * 0.15;
    return (min: lowest - padding, max: highest + padding);
  }

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    final index = response?.lineBarSpots?.firstOrNull?.spotIndex;

    switch (event) {
      case FlTapUpEvent() when index != null:
        onPointTapped(index);
      case FlPanUpdateEvent() when index != null:
      case FlLongPressMoveUpdate() when index != null:
      case FlLongPressStart() when index != null:
        onScrubbed(index);
      case FlPanEndEvent():
      case FlPanCancelEvent():
      case FlLongPressEnd():
        onScrubEnded();
      default:
        break;
    }
  }
}

/// One date label under the chart.
///
/// Every other label is just the day, so seven of them fit without collapsing
/// into noise.
class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.meta, required this.label});

  final TitleMeta meta;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SideTitleWidget(
      meta: meta,
      // Pulls the first and last labels back inside the plot area instead of
      // letting them hang off the edge.
      fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
      child: Text(
        label,
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

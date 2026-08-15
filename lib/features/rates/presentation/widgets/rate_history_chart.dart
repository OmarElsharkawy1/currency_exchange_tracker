import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/core/theme/app_motion.dart';
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

  /// Vertical space the date row occupies under the plot.
  ///
  /// Shared with the skeleton so the placeholder and the real chart reserve
  /// the same room and the layout does not shift when history arrives.
  static const double axisLabelHeight = 28;

  /// Horizontal space the value column occupies beside the plot.
  ///
  /// Wide enough for a rate at display precision, and shared with the
  /// skeleton for the same reason as [axisLabelHeight].
  static const double axisValueWidth = 52;

  /// How much the line is smoothed between points.
  ///
  /// Low on purpose: a rate series is a sequence of real readings, and a
  /// rounder line invents shapes between them that the data does not have.
  static const double curveSmoothness = 0.2;

  /// Headroom above and below the data, as a fraction of its range.
  ///
  /// Without it a week's wobble stretches to fill the full height and reads
  /// as a dramatic move.
  static const double verticalHeadroom = 0.1;

  /// Below this height the midpoint label is dropped and only the extremes
  /// are shown; three labels in a short chart collide.
  static const double minHeightForMidpointLabel = 160;

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
      child: LayoutBuilder(
        builder: (context, constraints) => _chart(
          context,
          lineColor: lineColor,
          bounds: bounds,
          showMidpointLabel: constraints.maxHeight >= minHeightForMidpointLabel,
        ),
      ),
    );
  }

  Widget _chart(
    BuildContext context, {
    required Color lineColor,
    required ({double min, double max, double dataMin, double dataMax}) bounds,
    required bool showMidpointLabel,
  }) {
    return LineChart(
      duration: AppMotion.chart,
      curve: AppMotion.curve,
      LineChartData(
        minY: bounds.min,
        maxY: bounds.max,
        // Ticks are measured from the data, not from the padded frame, so
        // the labels read as the series' own low and high.
        baselineY: bounds.dataMin,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.colors.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: axisValueWidth,
              interval: _valueLabelInterval(
                bounds,
                withMidpoint: showMidpointLabel,
              ),
              // The padded frame is not a reading; only the data is.
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) => _ValueLabel(
                meta: meta,
                label: RateFormatter.spokenRate(value),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // Every plotted day gets a label.
              interval: 1,
              reservedSize: axisLabelHeight,
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
            curveSmoothness: curveSmoothness,
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

  /// The plotted frame, and the data extremes it was built from.
  ///
  /// A flat series has no range to pad, so it gets a small absolute margin
  /// instead — otherwise the frame collapses onto the line.
  ({double min, double max, double dataMin, double dataMax}) get _bounds {
    final values = history.points.map((point) => point.displayRate).toList()
      ..sort();
    final lowest = values.first;
    final highest = values.last;
    final range = highest - lowest;
    final padding = switch (range) {
      0 => _flatSeriesMargin(highest),
      _ => range * verticalHeadroom,
    };
    return (
      min: lowest - padding,
      max: highest + padding,
      dataMin: lowest,
      dataMax: highest,
    );
  }

  static double _flatSeriesMargin(double value) {
    final proportional = value.abs() * verticalHeadroom;
    return proportional == 0 ? 1 : proportional;
  }

  /// The gap between value labels: half the data range for low/mid/high, the
  /// whole range when there is only room for the extremes.
  double _valueLabelInterval(
    ({double min, double max, double dataMin, double dataMax}) bounds, {
    required bool withMidpoint,
  }) {
    final range = bounds.dataMax - bounds.dataMin;
    if (range == 0) return bounds.max - bounds.min;
    return switch (withMidpoint) {
      true => range / 2,
      false => range,
    };
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

/// One value label beside the chart.
class _ValueLabel extends StatelessWidget {
  const _ValueLabel({required this.meta, required this.label});

  final TitleMeta meta;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SideTitleWidget(
      meta: meta,
      // Same treatment as the date row: the top and bottom labels sit on the
      // frame's edge and would otherwise hang outside it.
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

import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The chart's placeholder: a chart-shaped silhouette, shimmering.
///
/// Built from real widgets rather than a single block, so Skeletonizer paints
/// a column-and-axis outline instead of one grey rectangle where the chart
/// will be.
class RateHistoryChartSkeleton extends StatelessWidget {
  /// Creates the skeleton.
  const RateHistoryChartSkeleton({super.key});

  /// One column per day the chart will show.
  ///
  /// Relative heights of the placeholder columns, as a fraction of the plot
  /// area. Uneven on purpose: a flat row of bars reads as a table.
  static const List<double> columnHeights = <double>[
    0.45,
    0.62,
    0.38,
    0.71,
    0.55,
    0.83,
    0.66,
  ];

  /// How much of its slot a placeholder column fills.
  ///
  /// A fraction, not a fixed width: seven fixed-width children overflow the
  /// moment the screen is narrower than the test surface, and the real chart
  /// spaces its dots proportionally anyway.
  static const double columnWidthFactor = 0.45;

  /// How much of its slot a placeholder date label fills.
  static const double labelWidthFactor = 0.7;

  /// Height of a placeholder date label.
  static const double labelHeight = 12;

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The loaded chart reserves this much for its value column; the
          // skeleton reserves the same, so the plot does not slide sideways
          // when history arrives.
          SizedBox(width: RateHistoryChart.axisValueWidth),
          Expanded(child: _Silhouette()),
        ],
      ),
    );
  }
}

/// The placeholder plot: uneven columns over a reserved date row.
class _Silhouette extends StatelessWidget {
  const _Silhouette();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final height in RateHistoryChartSkeleton.columnHeights)
                  Expanded(
                    child: _Column(height: constraints.maxHeight * height),
                  ),
              ],
            ),
          ),
        ),
        // The loaded chart reserves this much for its date row; the skeleton
        // reserves the same, so nothing shifts when it resolves.
        const SizedBox(height: AppSpacing.sectionGap),
        const SizedBox(
          height: RateHistoryChart.axisLabelHeight,
          child: _AxisLabels(),
        ),
      ],
    );
  }
}

/// One placeholder column of the silhouette.
///
/// Its width is a fraction of the slot the parent `Row` gives it, so seven of
/// them fit any width the phone has.
class _Column extends StatelessWidget {
  const _Column({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: RateHistoryChartSkeleton.columnWidthFactor,
      child: Bone(
        height: height,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }
}

/// Placeholder day labels under the silhouette.
class _AxisLabels extends StatelessWidget {
  const _AxisLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final _ in RateHistoryChartSkeleton.columnHeights)
          const Expanded(
            child: FractionallySizedBox(
              widthFactor: RateHistoryChartSkeleton.labelWidthFactor,
              child: Bone(height: RateHistoryChartSkeleton.labelHeight),
            ),
          ),
      ],
    );
  }
}

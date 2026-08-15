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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final height in RateHistoryChartSkeleton.columnHeights)
                  _Column(height: constraints.maxHeight * height),
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
class _Column extends StatelessWidget {
  const _Column({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Bone(
      width: 18,
      height: height,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
    );
  }
}

/// Placeholder day labels under the silhouette.
class _AxisLabels extends StatelessWidget {
  const _AxisLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final _ in RateHistoryChartSkeleton.columnHeights)
          const Bone.text(words: 1, fontSize: 12),
      ],
    );
  }
}

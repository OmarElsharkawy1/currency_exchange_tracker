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
  static const List<double> _columnHeights = <double>[
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
    return Skeletonizer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final height in _columnHeights)
                    _Column(height: constraints.maxHeight * height),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _AxisLabels(),
        ],
      ),
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
        for (final _ in RateHistoryChartSkeleton._columnHeights)
          const Bone.text(words: 1, fontSize: 12),
      ],
    );
  }
}

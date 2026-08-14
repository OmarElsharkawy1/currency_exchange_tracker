import 'package:currency_exchange_tracker/core/theme/trend_colors.dart';
import 'package:flutter/material.dart';

/// Short accessors for the theme values widgets read most often.
extension ThemeContextExtensions on BuildContext {
  /// The active [ColorScheme].
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// The active [TextTheme].
  TextTheme get textStyles => Theme.of(this).textTheme;

  /// The active [TrendColors] extension.
  ///
  /// Falls back to the light set if the theme was built without the
  /// extension, so a misconfigured theme degrades instead of crashing.
  TrendColors get trendColors =>
      Theme.of(this).extension<TrendColors>() ?? TrendColors.light;
}

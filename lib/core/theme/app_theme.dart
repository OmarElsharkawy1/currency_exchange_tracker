import 'package:currency_exchange_tracker/core/theme/trend_colors.dart';
import 'package:flutter/material.dart';

/// Light and dark [ThemeData] for the app.
///
/// Both themes carry a [TrendColors] extension; widgets read semantic colors
/// from the theme rather than hardcoding them.
abstract final class AppTheme {
  /// Seed color the Material 3 schemes are generated from.
  static const Color _seedColor = Color(0xFF0F4C81);

  /// The light theme.
  static ThemeData get light => _build(Brightness.light, TrendColors.light);

  /// The dark theme.
  static ThemeData get dark => _build(Brightness.dark, TrendColors.dark);

  static ThemeData _build(Brightness brightness, TrendColors trendColors) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      extensions: [trendColors],
    );
  }
}

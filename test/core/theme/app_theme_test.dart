import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/trend_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme carries the light trend colors', () {
      expect(AppTheme.light.extension<TrendColors>(), TrendColors.light);
    });

    test('dark theme carries the dark trend colors', () {
      expect(AppTheme.dark.extension<TrendColors>(), TrendColors.dark);
    });
  });

  group('TrendColors', () {
    test('lerp at t=0 and t=1 returns the endpoints', () {
      const light = TrendColors.light;
      const dark = TrendColors.dark;

      expect(light.lerp(dark, 0), light);
      expect(light.lerp(dark, 1), dark);
    });

    test('copyWith replaces only the given color', () {
      const original = TrendColors.light;
      final copy = original.copyWith(weakening: const Color(0xFF000000));

      expect(copy.strengthening, original.strengthening);
      expect(copy.weakening, const Color(0xFF000000));
    });
  });

  group('ThemeContextExtensions', () {
    testWidgets('trendColors resolves from the active theme', (tester) async {
      late TrendColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              resolved = context.trendColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, TrendColors.dark);
    });

    testWidgets('trendColors falls back when the extension is absent', (
      tester,
    ) async {
      late TrendColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              resolved = context.trendColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, TrendColors.light);
    });
  });
}

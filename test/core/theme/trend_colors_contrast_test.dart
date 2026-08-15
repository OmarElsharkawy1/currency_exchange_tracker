import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/trend_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 relative contrast between two opaque colors.
double contrastRatio(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

/// The AA floor for body text. Trend colors carry meaning, so they are held
/// to the text standard rather than the 3:1 graphical one.
const double wcagAaNormalText = 4.5;

void main() {
  group('light theme', () {
    final surface = AppTheme.light.colorScheme.surface;

    test('a strengthening pound is readable', () {
      expect(
        contrastRatio(TrendColors.light.strengthening, surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
    });

    test('a weakening pound is readable', () {
      expect(
        contrastRatio(TrendColors.light.weakening, surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
    });
  });

  group('dark theme', () {
    final surface = AppTheme.dark.colorScheme.surface;

    test('a strengthening pound is readable', () {
      expect(
        contrastRatio(TrendColors.dark.strengthening, surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
    });

    test('a weakening pound is readable', () {
      expect(
        contrastRatio(TrendColors.dark.weakening, surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
    });
  });

  group('the two directions stay distinguishable', () {
    /// Degrees between two hues on the colour wheel.
    double hueGap(Color first, Color second) {
      final gap =
          (HSLColor.fromColor(first).hue - HSLColor.fromColor(second).hue)
              .abs();
      return gap > 180 ? 360 - gap : gap;
    }

    // Contrast ratio is the wrong instrument here: it measures luminance, and
    // a red and a green can match in luminance while being obviously
    // different. Hue separation is what "these are different" means.
    //
    // Colour is never the only signal regardless — the sign on the number and
    // the "up"/"down" wording in the semantics label both carry it, which is
    // what keeps this readable for red-green colour blindness.
    test('light theme separates the two hues', () {
      expect(
        hueGap(
          TrendColors.light.strengthening,
          TrendColors.light.weakening,
        ),
        greaterThan(60),
      );
    });

    test('dark theme separates the two hues', () {
      expect(
        hueGap(TrendColors.dark.strengthening, TrendColors.dark.weakening),
        greaterThan(60),
      );
    });
  });
}

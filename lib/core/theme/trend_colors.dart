import 'package:flutter/material.dart';

/// Semantic colors for exchange-rate movement.
///
/// The names are deliberately about the Egyptian pound, not about arrows:
/// a rising *display* rate (more EGP per foreign unit) means the pound got
/// weaker, so it is painted with [weakening]. Every color decision keys off
/// `ExchangeRate.direction` and resolves through this extension — a literal
/// `Colors.green` at a call site is a defect.
@immutable
final class TrendColors extends ThemeExtension<TrendColors> {
  /// Creates a trend color set.
  const TrendColors({required this.strengthening, required this.weakening});

  /// EGP gained value against the foreign currency.
  final Color strengthening;

  /// EGP lost value against the foreign currency.
  final Color weakening;

  /// Trend colors for the light theme.
  ///
  /// The green is darker than a stock "success" green on purpose: the lighter
  /// shade measured 4.37:1 against the light surface, under the 4.5:1 WCAG AA
  /// floor for body text. This one clears it at 5.16:1.
  static const TrendColors light = TrendColors(
    strengthening: Color(0xFF177A35),
    weakening: Color(0xFFC62828),
  );

  /// Trend colors for the dark theme.
  static const TrendColors dark = TrendColors(
    strengthening: Color(0xFF4ADE80),
    weakening: Color(0xFFF87171),
  );

  @override
  TrendColors copyWith({Color? strengthening, Color? weakening}) {
    return TrendColors(
      strengthening: strengthening ?? this.strengthening,
      weakening: weakening ?? this.weakening,
    );
  }

  @override
  TrendColors lerp(covariant TrendColors? other, double t) {
    if (other == null) return this;
    return TrendColors(
      strengthening:
          Color.lerp(strengthening, other.strengthening, t) ?? strengthening,
      weakening: Color.lerp(weakening, other.weakening, t) ?? weakening,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrendColors &&
        other.strengthening == strengthening &&
        other.weakening == weakening;
  }

  @override
  int get hashCode => Object.hash(strengthening, weakening);
}

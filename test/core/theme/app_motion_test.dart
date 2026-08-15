import 'package:currency_exchange_tracker/core/theme/app_motion.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The brief's ceiling: this is feedback, not choreography.
  const budget = Duration(milliseconds: 400);

  test('every duration fits the motion budget', () {
    for (final duration in [
      AppMotion.value,
      AppMotion.entrance,
      AppMotion.stagger,
      AppMotion.chart,
    ]) {
      expect(duration, lessThanOrEqualTo(budget));
    }
  });

  test('a full staggered list still lands inside a second', () {
    // Five currencies: the last one starts after four stagger steps.
    final last = AppMotion.stagger * 4 + AppMotion.entrance;

    expect(last, lessThan(const Duration(milliseconds: 500)));
  });

  test('one curve for everything', () {
    expect(AppMotion.curve, Curves.easeOutCubic);
  });
}

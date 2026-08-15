import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// The rate sentence, rolling from its old figure to its new one.
///
/// Only the digits move: the sentence keeps its place in the layout, so a
/// refresh reads as the number changing rather than the row redrawing.
class RollingRate extends StatelessWidget {
  /// Creates a rolling rate for [currencyCode] at [displayRate].
  const RollingRate({
    required this.currencyCode,
    required this.displayRate,
    this.style,
    super.key,
  });

  /// The currency the sentence names.
  final String currencyCode;

  /// The rate to settle on.
  final double displayRate;

  /// Style for the sentence.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // No `begin`: TweenAnimationBuilder seeds it from the current value,
      // so the first paint is static and only later changes roll.
      tween: Tween<double>(end: displayRate),
      duration: AppMotion.value,
      curve: AppMotion.curve,
      builder: (context, value, child) => Text(
        RateFormatter.rateSentence(currencyCode, value),
        style: style,
      ),
    );
  }
}

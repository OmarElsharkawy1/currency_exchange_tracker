import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:flutter/material.dart';

/// A currency's code in a fixed-size disc.
///
/// Deliberately a box of constant size rather than bare text: this is what
/// flies between the list and the detail screen, and a `Hero` interpolates
/// its child's rect. Text laid out at an intermediate width clips mid-flight
/// and snaps at the end — a disc that measures the same at both ends has
/// nothing to interpolate.
class CurrencyBadge extends StatelessWidget {
  /// Creates a badge for [currency].
  const CurrencyBadge({required this.currency, super.key});

  /// The currency named on the badge.
  final Currency currency;

  /// Width and height, identical on every screen that shows one.
  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      // Transparent Material so the code paints normally while the badge is
      // in flight, outside its usual Scaffold.
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              currency.code,
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

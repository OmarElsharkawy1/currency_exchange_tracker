import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:flutter/material.dart';

/// The detail screen's readout.
///
/// Renders from the entity the route carried, so it is complete on the first
/// frame and never waits for the chart. While a day is scrubbed it reads that
/// day out instead; releasing returns it to today's rate and movement.
class CurrencyDetailHeader extends StatelessWidget {
  /// Creates the header.
  const CurrencyDetailHeader({
    required this.comparison,
    required this.scrubbedPoint,
    required this.heroTag,
    super.key,
  });

  /// Today's rate and its movement.
  final RateComparison comparison;

  /// The day currently under the finger, or `null` when not scrubbing.
  final ExchangeRate? scrubbedPoint;

  /// Hero tag shared with the list row.
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final shownRate = switch (scrubbedPoint) {
      null => comparison.current,
      final point => point,
    };

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageHorizontal,
        AppSpacing.pageTop,
        AppSpacing.pageHorizontal,
        AppSpacing.sectionGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The app bar already names the currency; this is the code the
          // list row flies in.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Hero(
              tag: heroTag,
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  comparison.currency.code,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            RateFormatter.rateSentence(
              comparison.currency.code,
              shownRate.displayRate,
            ),
            style: context.textStyles.headlineSmall,
          ),
          const SizedBox(height: 4),
          switch (scrubbedPoint) {
            null => _DayMovement(comparison: comparison),
            final point => _ScrubbedDay(point: point),
          },
        ],
      ),
    );
  }
}

/// Today's movement, painted by direction.
class _DayMovement extends StatelessWidget {
  const _DayMovement({required this.comparison});

  final RateComparison comparison;

  @override
  Widget build(BuildContext context) {
    final color = switch (comparison.direction) {
      RateDirection.egpWeakening => context.trendColors.weakening,
      RateDirection.egpStrengthening => context.trendColors.strengthening,
      RateDirection.flat => context.colors.onSurfaceVariant,
    };
    final style = context.textStyles.bodyMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Text(RateFormatter.signedChange(comparison.change), style: style),
        const SizedBox(width: 6),
        Text(
          RateFormatter.signedPercent(comparison.percentChange),
          style: style,
        ),
        const SizedBox(width: 8),
        Text(
          RateFormatter.rateDate(comparison.current.date),
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The date of the day being scrubbed, in place of today's movement.
class _ScrubbedDay extends StatelessWidget {
  const _ScrubbedDay({required this.point});

  final ExchangeRate point;

  @override
  Widget build(BuildContext context) {
    return Text(
      RateFormatter.rateDate(point.date),
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:flutter/material.dart';

/// One currency's row in the rates list.
///
/// Every number it shows was computed by [RateComparison]; this widget only
/// formats and paints.
class RateRow extends StatelessWidget {
  /// Creates a row for [comparison].
  const RateRow({required this.comparison, super.key});

  /// The rate and its movement.
  final RateComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticsLabel(comparison),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Expanded(child: _CurrencyIdentity(comparison: comparison)),
            _RateMovement(comparison: comparison),
          ],
        ),
      ),
    );
  }
}

/// The name and code of the currency, at the start of the row.
class _CurrencyIdentity extends StatelessWidget {
  const _CurrencyIdentity({required this.comparison});

  final RateComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comparison.currency.englishName,
          style: context.textStyles.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          comparison.currency.code,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The rate sentence and the day's movement, at the end of the row.
class _RateMovement extends StatelessWidget {
  const _RateMovement({required this.comparison});

  final RateComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          RateFormatter.rateSentence(
            comparison.currency.code,
            comparison.displayRate,
          ),
          style: context.textStyles.titleMedium,
        ),
        const SizedBox(height: 2),
        _ChangeLabel(comparison: comparison),
      ],
    );
  }
}

/// The signed change and percentage, painted by direction.
class _ChangeLabel extends StatelessWidget {
  const _ChangeLabel({required this.comparison});

  final RateComparison comparison;

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.bodyMedium?.copyWith(
      color: _colorFor(context, comparison.direction),
      fontWeight: FontWeight.w600,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(RateFormatter.signedChange(comparison.change), style: style),
        const SizedBox(width: 6),
        Text(
          RateFormatter.signedPercent(comparison.percentChange),
          style: style,
        ),
      ],
    );
  }
}

/// The only place a trend color is chosen.
Color _colorFor(BuildContext context, RateDirection direction) =>
    switch (direction) {
      RateDirection.egpWeakening => context.trendColors.weakening,
      RateDirection.egpStrengthening => context.trendColors.strengthening,
      RateDirection.flat => context.colors.onSurfaceVariant,
    };

/// What a screen reader announces for the row.
String _semanticsLabel(RateComparison comparison) {
  final name = comparison.currency.englishName;
  final rate = RateFormatter.spokenRate(comparison.displayRate);
  final movement = switch (comparison.direction) {
    RateDirection.egpWeakening =>
      'up ${RateFormatter.absolutePercent(comparison.percentChange)} percent',
    RateDirection.egpStrengthening =>
      'down ${RateFormatter.absolutePercent(comparison.percentChange)} percent',
    RateDirection.flat => 'unchanged',
  };
  return '$name, $rate Egyptian pounds, $movement';
}

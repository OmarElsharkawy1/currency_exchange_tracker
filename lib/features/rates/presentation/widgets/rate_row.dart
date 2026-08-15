import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/formatting/rate_semantics.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/currency_detail_page.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/currency_badge.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rolling_rate.dart';
import 'package:flutter/material.dart';

/// One currency's row in the rates list.
///
/// Every number it shows was computed by [RateComparison]; this widget only
/// formats and paints.
class RateRow extends StatelessWidget {
  /// Creates a row for [comparison].
  const RateRow({
    required this.comparison,
    this.isInteractive = false,
    super.key,
  });

  /// The rate and its movement.
  final RateComparison comparison;

  /// Whether this row can be opened.
  ///
  /// Carried here rather than wrapped around the row, so the phrasing and the
  /// "button" flag land on one semantics node: split across two, a screen
  /// reader stops twice on the same row.
  final bool isInteractive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isInteractive,
      label: RateSemantics.describe(_pointOf(comparison)),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Hero(
              tag: CurrencyDetailPage.heroTagFor(comparison.currency),
              child: CurrencyBadge(currency: comparison.currency),
            ),
            const SizedBox(width: 12),
            Expanded(child: _CurrencyIdentity(comparison: comparison)),
            const SizedBox(width: 8),
            // Flexible + scale-down keeps the row from overflowing on narrow
            // handsets: the movement stays right-aligned and shrinks by a hair
            // when a long rate would otherwise push past the edge, instead of
            // wrapping to a second line or clipping the change chip.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: _RateMovement(comparison: comparison),
              ),
            ),
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
          // The name is the one thing here that can be shortened without
          // losing meaning: the rate and its movement are the point.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        RollingRate(
          currencyCode: comparison.currency.code,
          displayRate: comparison.displayRate,
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

/// The row's day in the shape both screens describe.
RateHistoryPoint _pointOf(RateComparison comparison) =>
    RateHistoryPoint(rate: comparison.current, previous: comparison.previous);

import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_row.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The rates list while it loads: real row layout, shimmering.
///
/// Placeholder rows are built from the real [RateRow] so the skeleton has the
/// exact shape of the content that replaces it.
class RatesLoadingList extends StatelessWidget {
  /// Creates the skeleton list.
  const RatesLoadingList({super.key});

  static final DateTime _placeholderDate = DateTime.utc(2024);

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        itemCount: Currency.values.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final currency = Currency.values[index];
          return RateRow(
            comparison: RateComparison(
              current: ExchangeRate(
                currency: currency,
                rawRate: 0.02,
                date: _placeholderDate,
              ),
            ),
          );
        },
      ),
    );
  }
}

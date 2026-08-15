import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:equatable/equatable.dart';

/// One day on the chart, paired with the day published before it.
///
/// Every number it exposes is computed by [ExchangeRate]; this type only
/// decides what "no predecessor" means. Unlike the list's `RateComparison`,
/// a missing predecessor reports `null` rather than zero: the chart's oldest
/// point genuinely has no movement to show, and rendering `0.00%` there would
/// be a claim the data does not support.
class RateHistoryPoint extends Equatable {
  /// Creates a point for [rate], optionally preceded by [previous].
  const RateHistoryPoint({required this.rate, this.previous});

  /// The day this point plots.
  final ExchangeRate rate;

  /// The day published before it, when one is known.
  final ExchangeRate? previous;

  /// The currency being charted.
  Currency get currency => rate.currency;

  /// The date this point plots.
  DateTime get date => rate.date;

  /// How many Egyptian pounds one unit of [currency] cost on [date].
  double get displayRate => rate.displayRate;

  /// Whether a predecessor was available to compare against.
  bool get hasPrevious => previous != null;

  /// Movement in Egyptian pounds since the previous day, or `null`.
  double? get change {
    final previousRate = previous;
    return previousRate == null ? null : rate.changeFrom(previousRate);
  }

  /// [change] as a percentage of the previous day, or `null`.
  double? get percentChange {
    final previousRate = previous;
    return previousRate == null ? null : rate.percentChangeFrom(previousRate);
  }

  /// Which way the pound moved; [RateDirection.flat] without a predecessor.
  RateDirection get direction {
    final previousRate = previous;
    return previousRate == null
        ? RateDirection.flat
        : rate.directionFrom(previousRate);
  }

  @override
  List<Object?> get props => [rate, previous];
}

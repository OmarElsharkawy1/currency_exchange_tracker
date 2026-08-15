import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:equatable/equatable.dart';

/// Today's rate for one currency, paired with the previous published day.
///
/// This is what the rates list renders: a value, a movement and a direction,
/// all pre-computed. The widget layer reads properties; it never subtracts,
/// divides or null-checks its way to a number.
class RateComparison extends Equatable {
  /// Pairs [current] with [previous], if a previous day is known.
  const RateComparison({required this.current, this.previous});

  /// The most recent rate.
  final ExchangeRate current;

  /// The previous published day's rate.
  ///
  /// `null` when it could not be fetched — offline with an empty historical
  /// cache, for instance. The movement getters then report no movement, so
  /// nothing downstream has to branch on it.
  final ExchangeRate? previous;

  /// The currency being compared.
  Currency get currency => current.currency;

  /// How many Egyptian pounds one unit of [currency] costs today.
  double get displayRate => current.displayRate;

  /// Whether a previous day was available to compare against.
  bool get hasPrevious => previous != null;

  /// Movement in display terms since the previous day; `0` without one.
  double get change {
    final previousRate = previous;
    return previousRate == null ? 0 : current.changeFrom(previousRate);
  }

  /// [change] as a percentage of the previous day; `0` without one.
  double get percentChange {
    final previousRate = previous;
    return previousRate == null ? 0 : current.percentChangeFrom(previousRate);
  }

  /// Which way the pound moved; [RateDirection.flat] without a previous day.
  RateDirection get direction {
    final previousRate = previous;
    return previousRate == null
        ? RateDirection.flat
        : current.directionFrom(previousRate);
  }

  @override
  List<Object?> get props => [current, previous];
}

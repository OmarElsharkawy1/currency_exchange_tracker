import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:equatable/equatable.dart';

/// One currency's rate against the Egyptian pound on one date.
///
/// The API quotes EGP -> foreign (`egp.usd = 0.019227` means 1 EGP buys
/// 0.019227 USD) while the UI shows foreign -> EGP (`1 USD = 52.01 EGP`).
/// This value object stores the raw wire value and owns every conversion and
/// comparison derived from it, so nothing above the domain layer ever divides
/// by a rate.
///
/// All comparisons invert *before* they subtract. Subtracting raw rates and
/// inverting the delta produces a completely different, plausible-looking
/// number.
class ExchangeRate extends Equatable {
  /// Creates a rate for [currency] on [date] from the raw EGP -> foreign
  /// quote [rawRate].
  const ExchangeRate({
    required this.currency,
    required this.rawRate,
    required this.date,
  });

  /// The currency quoted against the Egyptian pound.
  final Currency currency;

  /// The raw EGP -> foreign quote exactly as the API published it: how many
  /// units of [currency] one Egyptian pound buys.
  final double rawRate;

  /// The date this quote belongs to, taken from the API response body.
  final DateTime date;

  /// The foreign -> EGP rate shown in the UI: how many Egyptian pounds one
  /// unit of [currency] costs.
  double get displayRate => 1 / rawRate;

  /// How many more (or fewer) Egyptian pounds a unit of [currency] costs
  /// compared to [previous], in display terms.
  double changeFrom(ExchangeRate previous) =>
      displayRate - previous.displayRate;

  /// [changeFrom] expressed as a percentage of the previous display rate.
  double percentChangeFrom(ExchangeRate previous) =>
      changeFrom(previous) / previous.displayRate * 100;

  /// Which way the pound moved between [previous] and this quote.
  ///
  /// A positive display change means a foreign unit costs more pounds, so the
  /// pound weakened — the opposite of the stock-app reading of a rising line.
  RateDirection directionFrom(ExchangeRate previous) {
    final change = changeFrom(previous);
    if (change > 0) return RateDirection.egpWeakening;
    if (change < 0) return RateDirection.egpStrengthening;
    return RateDirection.flat;
  }

  @override
  List<Object?> get props => [currency, rawRate, date];
}

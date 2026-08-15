import 'package:currency_exchange_tracker/core/extensions/date_time_extensions.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:equatable/equatable.dart';

/// One `egp.json` response body from the currency API.
///
/// The wire payload carries ~200 currencies; only the five tracked ones are
/// kept. Anything unexpected — a missing `date`, a missing `egp` object, a
/// missing tracked currency, a non-numeric quote — throws a
/// [FormatException], which the data source turns into a `ParseFailure`.
///
/// This type never leaves the data layer; callers use [toDomain].
class RatesResponseDto extends Equatable {
  /// Creates a DTO from already-validated values.
  const RatesResponseDto({required this.date, required this.rates});

  /// Parses an `egp.json` body.
  ///
  /// Throws a [FormatException] if the payload does not have the expected
  /// shape.
  factory RatesResponseDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    if (rawDate is! String) {
      throw const FormatException('Missing or non-string "date" field.');
    }
    final date = _parseApiDate(rawDate);

    final rawRates = json['egp'];
    if (rawRates is! Map) {
      throw const FormatException('Missing or malformed "egp" object.');
    }

    final rates = <Currency, double>{};
    for (final currency in Currency.values) {
      final quote = rawRates[currency.responseKey];
      if (quote is! num) {
        throw FormatException(
          'Missing or non-numeric quote for "${currency.responseKey}".',
        );
      }
      rates[currency] = quote.toDouble();
    }

    return RatesResponseDto(date: date, rates: rates);
  }

  /// The date the API itself published this payload under, as a UTC calendar
  /// date.
  ///
  /// Every historical request is anchored on this value, never on device
  /// local time.
  final DateTime date;

  /// Raw EGP -> foreign quotes for the five tracked currencies.
  final Map<Currency, double> rates;

  /// The payload in the API's own shape, ready to be cached as a JSON string.
  ///
  /// Untracked currencies are not preserved; the cache holds exactly what the
  /// app parses back.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'date': date.toApiDate(),
    'egp': <String, dynamic>{
      for (final entry in rates.entries) entry.key.responseKey: entry.value,
    },
  };

  /// The quotes as domain entities, ordered by [Currency.values].
  List<ExchangeRate> toDomain() => [
    for (final currency in Currency.values)
      ExchangeRate(
        currency: currency,
        rawRate: rates[currency]!,
        date: date,
      ),
  ];

  static DateTime _parseApiDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Unparseable API date: "$value".');
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  @override
  List<Object?> get props => [
    date,
    // Map equality: compare the quotes in a stable order.
    [for (final currency in Currency.values) rates[currency]],
  ];
}

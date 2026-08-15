import 'dart:convert';

import 'package:currency_exchange_tracker/features/rates/data/dtos/rates_response_dto.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> payload({
  Object? date = '2024-03-06',
  Map<String, dynamic>? egp,
  bool includeEgp = true,
}) {
  return <String, dynamic>{
    'date': ?date,
    if (includeEgp)
      'egp':
          egp ??
          <String, dynamic>{
            'usd': 0.019227,
            'eur': 0.017821,
            'gbp': 0.015231,
            'sar': 0.072103,
            'jpy': 2.9012,
            // Noise the API really sends: ~200 more keys.
            'aed': 0.070624,
            'btc': 3.1e-7,
            'zwl': 6.191,
          },
  };
}

void main() {
  group('RatesResponseDto.fromJson', () {
    test('parses the API date as a UTC calendar date', () {
      final dto = RatesResponseDto.fromJson(payload());

      expect(dto.date, DateTime.utc(2024, 3, 6));
      expect(dto.date.isUtc, isTrue);
    });

    test('keeps only the five tracked currencies', () {
      final dto = RatesResponseDto.fromJson(payload());

      expect(dto.rates.keys, unorderedEquals(Currency.values));
      expect(dto.rates.length, 5);
    });

    test('reads each raw EGP -> foreign quote', () {
      final dto = RatesResponseDto.fromJson(payload());

      expect(dto.rates[Currency.usd], 0.019227);
      expect(dto.rates[Currency.eur], 0.017821);
      expect(dto.rates[Currency.gbp], 0.015231);
      expect(dto.rates[Currency.sar], 0.072103);
      expect(dto.rates[Currency.jpy], 2.9012);
    });

    test('widens integer-valued quotes to double', () {
      final dto = RatesResponseDto.fromJson(
        payload(
          egp: <String, dynamic>{
            'usd': 0.019227,
            'eur': 0.017821,
            'gbp': 0.015231,
            'sar': 0.072103,
            'jpy': 3, // an int on the wire
          },
        ),
      );

      expect(dto.rates[Currency.jpy], 3.0);
    });

    test('throws FormatException when the date field is missing', () {
      expect(
        () => RatesResponseDto.fromJson(payload(date: null)),
        throwsFormatException,
      );
    });

    test('throws FormatException when the date field is not a string', () {
      expect(
        () => RatesResponseDto.fromJson(payload(date: 20240306)),
        throwsFormatException,
      );
    });

    test('throws FormatException when the date field is unparseable', () {
      expect(
        () => RatesResponseDto.fromJson(payload(date: 'last-tuesday')),
        throwsFormatException,
      );
    });

    test('throws FormatException when the egp object is missing', () {
      expect(
        () => RatesResponseDto.fromJson(payload(includeEgp: false)),
        throwsFormatException,
      );
    });

    test('throws FormatException when the egp object is not a map', () {
      expect(
        () => RatesResponseDto.fromJson(const <String, dynamic>{
          'date': '2024-03-06',
          'egp': <String>['usd'],
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when a tracked currency is missing', () {
      expect(
        () => RatesResponseDto.fromJson(
          payload(
            egp: <String, dynamic>{
              'usd': 0.019227,
              'eur': 0.017821,
              'gbp': 0.015231,
              'sar': 0.072103,
              // jpy dropped
            },
          ),
        ),
        throwsFormatException,
      );
    });

    test('throws FormatException when a quote is not numeric', () {
      expect(
        () => RatesResponseDto.fromJson(
          payload(
            egp: <String, dynamic>{
              'usd': '0.019227',
              'eur': 0.017821,
              'gbp': 0.015231,
              'sar': 0.072103,
              'jpy': 2.9012,
            },
          ),
        ),
        throwsFormatException,
      );
    });
  });

  group('RatesResponseDto.toJson', () {
    test('round-trips through a JSON string, dropping untracked keys', () {
      final original = RatesResponseDto.fromJson(payload());

      final encoded = jsonEncode(original.toJson());
      final restored = RatesResponseDto.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(restored, original);
      expect(encoded.contains('zwl'), isFalse);
    });

    test('writes the date back in YYYY-MM-DD form', () {
      final dto = RatesResponseDto.fromJson(payload());

      expect(dto.toJson()['date'], '2024-03-06');
    });
  });

  group('RatesResponseDto.toDomain', () {
    test('maps every quote to an ExchangeRate stamped with the API date', () {
      final rates = RatesResponseDto.fromJson(payload()).toDomain();

      expect(rates.length, 5);
      final usd = rates.firstWhere((rate) => rate.currency == Currency.usd);
      expect(usd.rawRate, 0.019227);
      expect(usd.date, DateTime.utc(2024, 3, 6));
    });

    test('orders rates by the declaration order of Currency', () {
      final rates = RatesResponseDto.fromJson(payload()).toDomain();

      expect(rates.map((rate) => rate.currency), Currency.values);
    });
  });

  group('value semantics', () {
    test('two dtos parsed from the same payload are equal', () {
      expect(
        RatesResponseDto.fromJson(payload()),
        RatesResponseDto.fromJson(payload()),
      );
    });

    test('a different quote makes a different value', () {
      final other = RatesResponseDto.fromJson(
        payload(
          egp: <String, dynamic>{
            'usd': 0.019100,
            'eur': 0.017821,
            'gbp': 0.015231,
            'sar': 0.072103,
            'jpy': 2.9012,
          },
        ),
      );

      expect(RatesResponseDto.fromJson(payload()), isNot(other));
    });
  });
}

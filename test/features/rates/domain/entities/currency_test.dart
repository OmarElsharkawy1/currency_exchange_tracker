import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    test('tracks exactly the five supported currencies', () {
      expect(Currency.values, [
        Currency.usd,
        Currency.eur,
        Currency.gbp,
        Currency.sar,
        Currency.jpy,
      ]);
    });

    test('exposes the ISO code for each currency', () {
      expect(Currency.usd.code, 'USD');
      expect(Currency.eur.code, 'EUR');
      expect(Currency.gbp.code, 'GBP');
      expect(Currency.sar.code, 'SAR');
      expect(Currency.jpy.code, 'JPY');
    });

    test('exposes the English name for each currency', () {
      expect(Currency.usd.englishName, 'US Dollar');
      expect(Currency.eur.englishName, 'Euro');
      expect(Currency.gbp.englishName, 'British Pound');
      expect(Currency.sar.englishName, 'Saudi Riyal');
      expect(Currency.jpy.englishName, 'Japanese Yen');
    });

    test('exposes the lowercase API response key', () {
      expect(Currency.usd.responseKey, 'usd');
      expect(Currency.eur.responseKey, 'eur');
      expect(Currency.gbp.responseKey, 'gbp');
      expect(Currency.sar.responseKey, 'sar');
      expect(Currency.jpy.responseKey, 'jpy');
    });

    test('resolves a currency from its response key', () {
      expect(Currency.fromResponseKey('jpy'), Currency.jpy);
      expect(Currency.fromResponseKey('usd'), Currency.usd);
    });

    test('returns null for an unsupported response key', () {
      expect(Currency.fromResponseKey('chf'), isNull);
      expect(Currency.fromResponseKey('USD'), isNull);
    });
  });
}

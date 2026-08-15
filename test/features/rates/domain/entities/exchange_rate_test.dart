import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a rate for [currency] from a raw EGP -> foreign quote.
ExchangeRate rateOf(
  double rawRate, {
  Currency currency = Currency.usd,
  DateTime? date,
}) {
  return ExchangeRate(
    currency: currency,
    rawRate: rawRate,
    date: date ?? DateTime.utc(2024, 5, 20),
  );
}

void main() {
  group('ExchangeRate.displayRate', () {
    test('inverts the raw EGP -> foreign quote into foreign -> EGP', () {
      expect(rateOf(0.019227).displayRate, closeTo(52.0102, 1e-4));
      expect(rateOf(0.019100).displayRate, closeTo(52.3560, 1e-4));
    });
  });

  group('raw falling / display rising', () {
    // 1 EGP buys fewer USD today, so a USD costs more EGP: EGP weakened.
    final yesterday = rateOf(0.019227);
    final today = rateOf(0.019100);

    test('display value moves 52.01 -> 52.36', () {
      expect(yesterday.displayRate, closeTo(52.0102, 1e-4));
      expect(today.displayRate, closeTo(52.3560, 1e-4));
    });

    test('change is the difference of the inverted values', () {
      expect(today.changeFrom(yesterday), closeTo(0.345827, 1e-5));
    });

    test('percent change is computed on the inverted values', () {
      expect(today.percentChangeFrom(yesterday), closeTo(0.664923, 1e-5));
    });

    test('direction is egpWeakening', () {
      expect(today.directionFrom(yesterday), RateDirection.egpWeakening);
    });
  });

  group('raw rising / display falling (mirror case)', () {
    // 1 EGP buys more USD today, so a USD costs fewer EGP: EGP strengthened.
    final yesterday = rateOf(0.019100);
    final today = rateOf(0.019227);

    test('display value moves 52.36 -> 52.01', () {
      expect(yesterday.displayRate, closeTo(52.3560, 1e-4));
      expect(today.displayRate, closeTo(52.0102, 1e-4));
    });

    test('change is negative on the inverted values', () {
      expect(today.changeFrom(yesterday), closeTo(-0.345827, 1e-5));
    });

    test('percent change is negative and based on the inverted values', () {
      expect(today.percentChangeFrom(yesterday), closeTo(-0.660527, 1e-5));
    });

    test('direction is egpStrengthening', () {
      expect(today.directionFrom(yesterday), RateDirection.egpStrengthening);
    });
  });

  group('invert-before-diff is not diff-then-invert', () {
    const rawYesterday = 0.019227;
    const rawToday = 0.019100;
    final yesterday = rateOf(rawYesterday);
    final today = rateOf(rawToday);

    test('change matches the invert-before-diff value', () {
      const invertBeforeDiff = (1 / rawToday) - (1 / rawYesterday);

      expect(today.changeFrom(yesterday), closeTo(invertBeforeDiff, 1e-12));
      expect(today.changeFrom(yesterday), closeTo(0.345827, 1e-5));
    });

    test('change is not the raw delta, nor the inverted raw delta', () {
      const rawDelta = rawToday - rawYesterday; // -0.000127
      const invertedRawDelta = 1 / rawDelta; // ~ -7874.0

      expect(today.changeFrom(yesterday), isNot(closeTo(rawDelta, 1e-3)));
      expect(
        today.changeFrom(yesterday),
        isNot(closeTo(invertedRawDelta, 1.0)),
      );
    });

    test('percent is not the percent of the raw rates', () {
      // The plausible-looking wrong answer: same magnitude, wrong sign.
      const rawPercent = (rawToday - rawYesterday) / rawYesterday * 100;

      expect(rawPercent, closeTo(-0.660528, 1e-5));
      expect(today.percentChangeFrom(yesterday), greaterThan(0));
      expect(
        today.percentChangeFrom(yesterday),
        isNot(closeTo(rawPercent, 0.01)),
      );
    });
  });

  group('JPY small-magnitude case', () {
    // 1 EGP ~ 3 JPY, so 1 JPY ~ 0.33 EGP.
    final yesterday = rateOf(3.0303, currency: Currency.jpy);
    final today = rateOf(3, currency: Currency.jpy);

    test('display value stays sub-unit', () {
      expect(yesterday.displayRate, closeTo(0.330000, 1e-6));
      expect(today.displayRate, closeTo(0.333333, 1e-6));
    });

    test('change is tiny but exact on the inverted values', () {
      expect(today.changeFrom(yesterday), closeTo(0.0033330, 1e-7));
    });

    test('percent change is not distorted by the small magnitude', () {
      expect(today.percentChangeFrom(yesterday), closeTo(1.010001, 1e-5));
    });

    test('direction is egpWeakening', () {
      expect(today.directionFrom(yesterday), RateDirection.egpWeakening);
    });
  });

  group('equal rates', () {
    final yesterday = rateOf(0.019227);
    final today = rateOf(0.019227, date: DateTime.utc(2024, 5, 21));

    test('change is zero', () {
      expect(today.changeFrom(yesterday), 0);
    });

    test('percent change is zero', () {
      expect(today.percentChangeFrom(yesterday), 0);
    });

    test('direction is flat', () {
      expect(today.directionFrom(yesterday), RateDirection.flat);
    });
  });

  group('value semantics', () {
    test('two rates with the same currency, raw rate and date are equal', () {
      expect(rateOf(0.019227), rateOf(0.019227));
      expect(rateOf(0.019227).hashCode, rateOf(0.019227).hashCode);
    });

    test('a different raw rate is a different value', () {
      expect(rateOf(0.019227), isNot(rateOf(0.019100)));
    });

    test('a different date is a different value', () {
      expect(
        rateOf(0.019227, date: DateTime.utc(2024, 5, 20)),
        isNot(rateOf(0.019227, date: DateTime.utc(2024, 5, 21))),
      );
    });
  });
}

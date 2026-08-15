import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:flutter_test/flutter_test.dart';

ExchangeRate rateOf(double rawRate, {int day = 6}) => ExchangeRate(
  currency: Currency.usd,
  rawRate: rawRate,
  date: DateTime.utc(2024, 3, day),
);

void main() {
  group('with a previous day', () {
    final comparison = RateComparison(
      current: rateOf(0.019100),
      previous: rateOf(0.019227, day: 5),
    );

    test('exposes the currency and display rate of the current day', () {
      expect(comparison.currency, Currency.usd);
      expect(comparison.displayRate, closeTo(52.3560, 1e-4));
    });

    test('delegates the change to the value object', () {
      expect(comparison.change, closeTo(0.345827, 1e-5));
      expect(comparison.percentChange, closeTo(0.664923, 1e-5));
    });

    test('delegates the direction to the value object', () {
      expect(comparison.direction, RateDirection.egpWeakening);
      expect(comparison.hasPrevious, isTrue);
    });
  });

  group('without a previous day', () {
    final comparison = RateComparison(current: rateOf(0.019100));

    test('reports no movement rather than a null', () {
      // Widgets switch on sealed state only; a nullable change would force a
      // conditional into the widget layer.
      expect(comparison.change, 0);
      expect(comparison.percentChange, 0);
      expect(comparison.direction, RateDirection.flat);
    });

    test('says so through hasPrevious', () {
      expect(comparison.hasPrevious, isFalse);
    });

    test('still exposes the current display rate', () {
      expect(comparison.displayRate, closeTo(52.3560, 1e-4));
    });
  });

  group('value semantics', () {
    test('same current and previous compare equal', () {
      expect(
        RateComparison(current: rateOf(0.0191), previous: rateOf(0.019227)),
        RateComparison(current: rateOf(0.0191), previous: rateOf(0.019227)),
      );
    });

    test('a missing previous is a different value', () {
      expect(
        RateComparison(current: rateOf(0.0191)),
        isNot(
          RateComparison(current: rateOf(0.0191), previous: rateOf(0.019227)),
        ),
      );
    });
  });
}

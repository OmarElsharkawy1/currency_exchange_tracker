import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:flutter_test/flutter_test.dart';

ExchangeRate rateOn(int day, double rawRate) => ExchangeRate(
  currency: Currency.usd,
  rawRate: rawRate,
  date: DateTime.utc(2024, 3, day),
);

void main() {
  group('RateHistoryPoint with a predecessor', () {
    final point = RateHistoryPoint(
      rate: rateOn(6, 0.019100),
      previous: rateOn(5, 0.019227),
    );

    test('delegates the change to the value object', () {
      expect(point.change, closeTo(0.345827, 1e-5));
      expect(point.percentChange, closeTo(0.664923, 1e-5));
    });

    test('delegates the direction to the value object', () {
      expect(point.direction, RateDirection.egpWeakening);
    });

    test('exposes the day it describes', () {
      expect(point.date, DateTime.utc(2024, 3, 6));
      expect(point.currency, Currency.usd);
      expect(point.displayRate, closeTo(52.3560, 1e-4));
    });

    test('knows it can be compared', () {
      expect(point.hasPrevious, isTrue);
    });
  });

  group('RateHistoryPoint without a predecessor', () {
    final point = RateHistoryPoint(rate: rateOn(1, 0.019300));

    test('has no change to report', () {
      expect(point.change, isNull);
      expect(point.percentChange, isNull);
    });

    test('is flat rather than guessing', () {
      expect(point.direction, RateDirection.flat);
      expect(point.hasPrevious, isFalse);
    });

    test('still knows its own rate', () {
      expect(point.displayRate, closeTo(51.8135, 1e-4));
    });
  });

  group('RateHistoryPoint mirror case', () {
    test('a rising raw rate strengthens the pound', () {
      final point = RateHistoryPoint(
        rate: rateOn(6, 0.019227),
        previous: rateOn(5, 0.019100),
      );

      expect(point.direction, RateDirection.egpStrengthening);
      expect(point.percentChange, closeTo(-0.660527, 1e-5));
    });

    test('equal rates are flat', () {
      final point = RateHistoryPoint(
        rate: rateOn(6, 0.019227),
        previous: rateOn(5, 0.019227),
      );

      expect(point.direction, RateDirection.flat);
      expect(point.change, 0);
    });
  });

  group('RateHistory', () {
    final history = RateHistory(
      points: [
        RateHistoryPoint(rate: rateOn(4, 0.019300)),
        RateHistoryPoint(
          rate: rateOn(5, 0.019227),
          previous: rateOn(4, 0.019300),
        ),
        RateHistoryPoint(
          rate: rateOn(6, 0.019100),
          previous: rateOn(5, 0.019227),
        ),
      ],
    );

    test('runs oldest to newest', () {
      expect(history.points.map((point) => point.date), [
        DateTime.utc(2024, 3, 4),
        DateTime.utc(2024, 3, 5),
        DateTime.utc(2024, 3, 6),
      ]);
    });

    test('latest is the last point', () {
      expect(history.latest.date, DateTime.utc(2024, 3, 6));
      expect(history.latest.direction, RateDirection.egpWeakening);
    });

    test('reports how many points it holds', () {
      expect(history.length, 3);
    });

    test('indexes its points', () {
      expect(history.pointAt(0)?.date, DateTime.utc(2024, 3, 4));
      expect(history.pointAt(2)?.date, DateTime.utc(2024, 3, 6));
    });

    test('answers null for an index it does not have', () {
      expect(history.pointAt(-1), isNull);
      expect(history.pointAt(3), isNull);
    });

    test('compares by value', () {
      expect(
        RateHistory(
          points: [RateHistoryPoint(rate: rateOn(6, 0.019100))],
        ),
        RateHistory(
          points: [RateHistoryPoint(rate: rateOn(6, 0.019100))],
        ),
      );
    });
  });
}

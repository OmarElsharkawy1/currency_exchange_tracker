import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rateSentence', () {
    test('reads as the UI sentence, foreign unit first', () {
      expect(RateFormatter.rateSentence('USD', 52.010194), '1 USD = 52.01 EGP');
    });

    test('keeps two decimals for a sub-unit currency', () {
      expect(RateFormatter.rateSentence('JPY', 0.333333), '1 JPY = 0.33 EGP');
    });

    test('groups thousands', () {
      expect(
        RateFormatter.rateSentence('BTC', 3210987.6),
        '1 BTC = 3,210,987.60 EGP',
      );
    });
  });

  group('spokenRate', () {
    test('is the bare number a screen reader reads out', () {
      expect(RateFormatter.spokenRate(52.355999), '52.36');
      expect(RateFormatter.spokenRate(0.333333), '0.33');
    });
  });

  group('signedChange', () {
    test('marks a rise with a plus', () {
      expect(RateFormatter.signedChange(0.345827), '+0.35');
    });

    test('marks a fall with a minus', () {
      expect(RateFormatter.signedChange(-0.345827), '-0.35');
    });

    test('shows no movement without a sign', () {
      expect(RateFormatter.signedChange(0), '0.00');
    });

    test('keeps sub-cent movement visible at four decimals', () {
      expect(RateFormatter.signedChange(0.003333), '+0.0033');
    });
  });

  group('signedPercent', () {
    test('formats a rise', () {
      expect(RateFormatter.signedPercent(0.664923), '+0.66%');
    });

    test('formats a fall', () {
      expect(RateFormatter.signedPercent(-0.660527), '-0.66%');
    });

    test('formats no movement', () {
      expect(RateFormatter.signedPercent(0), '0.00%');
    });
  });

  group('absolutePercent', () {
    test('drops the sign for spoken labels', () {
      expect(RateFormatter.absolutePercent(-0.660527), '0.66');
      expect(RateFormatter.absolutePercent(0.664923), '0.66');
    });
  });

  group('rateDate', () {
    test('names the day a rate belongs to', () {
      expect(RateFormatter.rateDate(DateTime.utc(2024, 3, 6)), 'Mar 6, 2024');
    });
  });

  group('chartDay', () {
    test('is short enough for an axis label', () {
      expect(RateFormatter.chartDay(DateTime.utc(2024, 3, 6)), 'Mar 6');
    });
  });

  group('timestamp', () {
    test('formats a date and time of day', () {
      expect(
        RateFormatter.timestamp(DateTime(2024, 3, 6, 9, 5)),
        'Mar 6, 09:05',
      );
    });

    test('uses a 24-hour clock', () {
      expect(
        RateFormatter.timestamp(DateTime(2024, 3, 6, 21, 30)),
        'Mar 6, 21:30',
      );
    });
  });
}

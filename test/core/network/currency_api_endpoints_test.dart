import 'package:currency_exchange_tracker/core/network/currency_api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyApiEndpoints.primary', () {
    test('builds the jsDelivr URL for the latest rates', () {
      expect(
        CurrencyApiEndpoints.primary(CurrencyApiEndpoints.latestVersion),
        Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/'
          'currency-api@latest/v1/currencies/egp.json',
        ),
      );
    });

    test('builds the jsDelivr URL for a dated snapshot', () {
      expect(
        CurrencyApiEndpoints.primary('2024-03-06'),
        Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/'
          'currency-api@2024-03-06/v1/currencies/egp.json',
        ),
      );
    });
  });

  group('CurrencyApiEndpoints.fallback', () {
    test('builds the pages.dev URL for the latest rates', () {
      expect(
        CurrencyApiEndpoints.fallback(CurrencyApiEndpoints.latestVersion),
        Uri.parse(
          'https://latest.currency-api.pages.dev/v1/currencies/'
          'egp.json',
        ),
      );
    });

    test('builds the pages.dev URL for a dated snapshot', () {
      expect(
        CurrencyApiEndpoints.fallback('2024-03-06'),
        Uri.parse(
          'https://2024-03-06.currency-api.pages.dev/v1/currencies/'
          'egp.json',
        ),
      );
    });
  });

  group('CurrencyApiEndpoints.fallbackFor', () {
    test('maps a primary latest URL to its pages.dev twin', () {
      expect(
        CurrencyApiEndpoints.fallbackFor(
          CurrencyApiEndpoints.primary(CurrencyApiEndpoints.latestVersion),
        ),
        CurrencyApiEndpoints.fallback(CurrencyApiEndpoints.latestVersion),
      );
    });

    test('maps a primary dated URL to its pages.dev twin', () {
      expect(
        CurrencyApiEndpoints.fallbackFor(
          CurrencyApiEndpoints.primary('2024-03-06'),
        ),
        CurrencyApiEndpoints.fallback('2024-03-06'),
      );
    });

    test('returns null for a URL that is already the fallback host', () {
      expect(
        CurrencyApiEndpoints.fallbackFor(
          CurrencyApiEndpoints.fallback('2024-03-06'),
        ),
        isNull,
      );
    });

    test('returns null for an unrelated URL', () {
      expect(
        CurrencyApiEndpoints.fallbackFor(Uri.parse('https://example.com/a')),
        isNull,
      );
    });
  });
}

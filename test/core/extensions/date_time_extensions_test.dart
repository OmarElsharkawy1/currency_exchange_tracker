import 'package:currency_exchange_tracker/core/extensions/date_time_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateTimeApiFormatting.toApiDate', () {
    test('pads single-digit month and day', () {
      expect(DateTime(2024, 3, 7).toApiDate(), '2024-03-07');
    });

    test('leaves two-digit month and day untouched', () {
      expect(DateTime(2024, 12, 31).toApiDate(), '2024-12-31');
    });

    test('ignores the time of day', () {
      expect(DateTime(2024, 3, 7, 23, 59, 59).toApiDate(), '2024-03-07');
      expect(DateTime(2024, 3, 7).toApiDate(), '2024-03-07');
    });

    test('formats a leap day', () {
      expect(DateTime(2024, 2, 29).toApiDate(), '2024-02-29');
    });

    test('pads years below four digits', () {
      expect(DateTime(999, 1, 2).toApiDate(), '0999-01-02');
    });

    test('formats UTC dates by their UTC calendar fields', () {
      expect(DateTime.utc(2024, 1, 5).toApiDate(), '2024-01-05');
    });
  });
}

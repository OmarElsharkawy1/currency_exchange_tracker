import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';

/// Screen-reader phrasing for a rate and its movement.
///
/// One implementation for both screens: the list row and the detail header
/// say the same thing about the same day, and a change to the wording cannot
/// land on one and miss the other.
abstract final class RateSemantics {
  /// What a screen reader announces for [point].
  ///
  /// Reads as "US Dollar, 57.88 Egyptian pounds, down 0.3 percent". The
  /// direction wording follows the display rate, so a weakening pound — a
  /// rising display rate — is announced as "up" while being painted in the
  /// weakening colour.
  static String describe(RateHistoryPoint point) {
    final name = point.currency.englishName;
    final rate = RateFormatter.spokenRate(point.displayRate);
    return '$name, $rate Egyptian pounds, ${_movement(point)}';
  }

  /// The movement clause, or "unchanged" when there is nothing to compare
  /// against or nothing moved.
  static String _movement(RateHistoryPoint point) {
    return switch ((point.direction, point.percentChange)) {
      (RateDirection.egpWeakening, final percent?) =>
        'up ${RateFormatter.absolutePercent(percent)} percent',
      (RateDirection.egpStrengthening, final percent?) =>
        'down ${RateFormatter.absolutePercent(percent)} percent',
      _ => 'unchanged',
    };
  }
}

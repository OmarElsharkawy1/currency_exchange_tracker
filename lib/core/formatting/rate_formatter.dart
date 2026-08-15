import 'package:intl/intl.dart';

/// Number and date formatting for rate values.
///
/// Every user-visible number goes through `intl` here; no widget builds a
/// string out of `toStringAsFixed` and concatenation.
///
/// Takes plain values rather than domain types, so `core` stays independent
/// of the feature module.
abstract final class RateFormatter {
  /// Two decimals with thousands separators: `52.01`.
  static final NumberFormat _rate = NumberFormat('#,##0.00');

  /// Signed movement at two decimals: `+0.35`.
  static final NumberFormat _signedChange = NumberFormat('+#,##0.00;-#,##0.00');

  /// Signed movement at four decimals, for currencies whose whole rate is a
  /// fraction of a pound — a JPY day move rounds to `0.00` otherwise.
  static final NumberFormat _signedFineChange = NumberFormat(
    '+#,##0.0000;-#,##0.0000',
  );

  /// Unsigned movement, used when there was none: `0.00`.
  static final NumberFormat _unsignedChange = NumberFormat('#,##0.00');

  /// Signed percentage with its own sign column: `+0.66%`.
  static final NumberFormat _signedPercent = NumberFormat(
    "+#,##0.00'%';-#,##0.00'%'",
  );

  /// Unsigned percentage, used when there was no movement: `0.00%`.
  static final NumberFormat _unsignedPercent = NumberFormat("#,##0.00'%'");

  /// Below this, two decimals would render a real movement as `0.00`.
  static const double _fineChangeThreshold = 0.01;

  /// Unsigned percentage for spoken labels: `0.66`.
  static final NumberFormat _absolutePercent = NumberFormat('#,##0.00');

  static final DateFormat _timestamp = DateFormat('MMM d, HH:mm');

  static final DateFormat _rateDate = DateFormat('MMM d, y');

  static final DateFormat _chartDay = DateFormat('MMM d');

  /// The rate as the UI states it: `1 USD = 52.01 EGP`.
  static String rateSentence(String currencyCode, double displayRate) =>
      '1 $currencyCode = ${_rate.format(displayRate)} EGP';

  /// The rate on its own, for a screen-reader label: `52.36`.
  static String spokenRate(double displayRate) => _rate.format(displayRate);

  /// Movement in Egyptian pounds, signed: `+0.35`, or `+0.0033` when two
  /// decimals would swallow it. No sign when there was no movement.
  static String signedChange(double change) {
    if (change == 0) return _unsignedChange.format(change);
    if (change.abs() < _fineChangeThreshold) {
      return _signedFineChange.format(change);
    }
    return _signedChange.format(change);
  }

  /// Movement as a percentage, signed: `+0.66%`. No sign at zero.
  static String signedPercent(double percentChange) => percentChange == 0
      ? _unsignedPercent.format(percentChange)
      : _signedPercent.format(percentChange);

  /// Movement as a percentage without its sign, for screen readers.
  static String absolutePercent(double percentChange) =>
      _absolutePercent.format(percentChange.abs());

  /// The day a rate belongs to, as `Mar 6, 2024`.
  static String rateDate(DateTime date) => _rateDate.format(date);

  /// A chart axis label, as `Mar 6`.
  static String chartDay(DateTime date) => _chartDay.format(date);

  /// A fetch time as `Mar 6, 09:05`.
  static String timestamp(DateTime moment) => _timestamp.format(moment);
}

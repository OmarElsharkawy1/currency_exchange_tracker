/// Date formatting helpers for the currency API's URL scheme.
extension DateTimeApiFormatting on DateTime {
  /// This date as `YYYY-MM-DD`, the format the currency API uses in its
  /// historical endpoint paths.
  ///
  /// Only the date part is used; the time of day is ignored. The value is
  /// taken as-is, so callers are responsible for anchoring on an
  /// API-provided date rather than device local time.
  String toApiDate() {
    final paddedMonth = month.toString().padLeft(2, '0');
    final paddedDay = day.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-$paddedMonth-$paddedDay';
  }
}

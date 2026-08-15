import 'package:currency_exchange_tracker/core/failures/failure.dart';

/// User-facing copy for each [Failure].
///
/// The mapping lives outside the widget layer so a screen never reasons about
/// failure types, and never shows raw exception text.
extension FailureMessages on Failure {
  /// A sentence to show the user, in plain language.
  String get userMessage => switch (this) {
    NetworkFailure() =>
      "Couldn't connect to the rates service. Check your connection and try "
          'again.',
    TimeoutFailure() => 'The rates service took too long to answer. Try again.',
    CacheMissFailure() => 'No saved rates on this device yet.',
    ParseFailure() => "The rates service sent something that couldn't be read.",
    RateUnavailableFailure() =>
      'Rates for that day were not published. Try another day.',
  };
}

/// The single source of "now" in the app.
///
/// `DateTime.now()` is banned everywhere except [SystemClock]. Anything
/// time-dependent takes a [Clock] through its constructor so tests can inject
/// a fixed instant instead of racing a real wall clock.
// ignore: one_member_abstracts
abstract class Clock {
  /// The current instant, in UTC-agnostic local form.
  DateTime now();
}

/// [Clock] backed by the device clock.
///
/// The only place in the codebase allowed to call `DateTime.now()`.
final class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

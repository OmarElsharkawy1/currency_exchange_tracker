import 'dart:async';

/// The single source of "now" — and of every timer — in the app.
///
/// `DateTime.now()` and `Timer` are both banned outside [SystemClock].
/// Anything time-dependent takes a [Clock] through its constructor or through
/// context, so tests inject a fixed instant and timers they fire by hand
/// instead of racing a real wall clock.
abstract class Clock {
  /// The current instant, in UTC-agnostic local form.
  DateTime now();

  /// A stream that emits once every [period].
  ///
  /// Callers cancel their subscription to stop the ticks.
  Stream<void> ticks(Duration period);

  /// Runs [action] once, [delay] from now.
  ///
  /// The returned handle cancels it. This is the only way to schedule
  /// one-shot work — debounces included — because it is the only place a real
  /// `Timer` is constructed.
  Timer after(Duration delay, void Function() action);
}

/// [Clock] backed by the device clock.
///
/// The only place in the codebase allowed to call `DateTime.now()` or to
/// construct a `Timer`.
final class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Stream<void> ticks(Duration period) => Stream<void>.periodic(period, (_) {});

  @override
  Timer after(Duration delay, void Function() action) => Timer(delay, action);
}

import 'dart:async';

import 'package:currency_exchange_tracker/core/clock/clock.dart';

/// A [Clock] a test drives by hand.
///
/// Nothing here moves on its own: the instant only changes when moved, ticks
/// only arrive when fired, and a scheduled delay only runs when told to. No
/// test that uses it waits on real time.
class FakeClock implements Clock {
  /// Creates a clock reading [instant].
  FakeClock(this.instant);

  /// The instant [now] reports.
  DateTime instant;

  final StreamController<void> _ticks = StreamController<void>.broadcast();
  final List<FakeTimer> _scheduled = [];

  /// Whether anything is currently subscribed to the tick stream.
  bool get hasTickListener => _ticks.hasListener;

  /// The period the subject asked to be ticked at.
  Duration? requestedPeriod;

  /// The delay the subject asked to be called back after.
  Duration? requestedDelay;

  /// Delays scheduled through [after] that have neither run nor been
  /// cancelled.
  List<FakeTimer> get pendingTimers =>
      _scheduled.where((timer) => timer.isActive).toList();

  /// Runs every delay currently pending, oldest first.
  void firePendingTimers() {
    for (final timer in pendingTimers) {
      timer.fire();
    }
  }

  /// Moves the instant forward and fires one tick, as a real minute would.
  void advance(Duration elapsed) {
    instant = instant.add(elapsed);
    _ticks.add(null);
  }

  @override
  DateTime now() => instant;

  @override
  Stream<void> ticks(Duration period) {
    requestedPeriod = period;
    return _ticks.stream;
  }

  @override
  Timer after(Duration delay, void Function() action) {
    requestedDelay = delay;
    final timer = FakeTimer(action);
    _scheduled.add(timer);
    return timer;
  }

  /// Releases the tick stream.
  void dispose() => _ticks.close();
}

/// A [Timer] that only fires when a test fires it.
class FakeTimer implements Timer {
  /// Creates a timer that will run [_action] when fired.
  FakeTimer(this._action);

  final void Function() _action;
  bool _isActive = true;
  int _tick = 0;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;

  @override
  void cancel() => _isActive = false;

  /// Runs the scheduled action, as elapsing the delay would.
  void fire() {
    if (!_isActive) return;
    _isActive = false;
    _tick++;
    _action();
  }
}

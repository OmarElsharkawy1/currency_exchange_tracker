import 'dart:async';

import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app's single answer to "are we online?".
///
/// `connectivity_plus` reports the radio only — airport wifi with no route to
/// the internet still reports `wifi` — so its stream is merged with a real
/// reachability probe. Both arrive as plain `bool` streams, which keeps this
/// cubit free of both packages and testable with two controllers.
///
/// Transitions are debounced: a radio that flaps while a lift doors open
/// would otherwise stampede a refresh per flap.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  /// Creates the cubit on the two source streams.
  ///
  /// [clock] schedules the debounce: no timer is constructed here, so tests
  /// fire the delay by hand rather than waiting for it.
  ConnectivityCubit({
    required Stream<bool> radioConnected,
    required Stream<bool> internetReachable,
    required Clock clock,
    Duration debounce = const Duration(seconds: 2),
  }) : _clock = clock,
       _debounce = debounce,
       super(const ConnectivityUnknown()) {
    _radioSubscription = radioConnected.listen((connected) {
      _isRadioConnected = connected;
      _reevaluate();
    });
    _reachabilitySubscription = internetReachable.listen((reachable) {
      _isInternetReachable = reachable;
      _reevaluate();
    });
  }

  final Clock _clock;
  final Duration _debounce;

  late final StreamSubscription<bool> _radioSubscription;
  late final StreamSubscription<bool> _reachabilitySubscription;
  Timer? _debounceTimer;

  bool? _isRadioConnected;
  bool? _isInternetReachable;

  void _reevaluate() {
    final verdict = _verdict();
    if (verdict == state) {
      // The reading came back to where it already was: cancel any pending
      // transition instead of emitting a round trip.
      _debounceTimer?.cancel();
      return;
    }

    // The very first conclusive reading is the cold-start answer; nothing is
    // flapping yet, and the banner should not wait two seconds for it.
    if (state is ConnectivityUnknown) {
      _emit(verdict);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = _clock.after(_debounce, () => _emit(verdict));
  }

  /// The merged verdict, or [ConnectivityUnknown] while it cannot be reached.
  ConnectivityState _verdict() {
    // A radio that is down settles it; no probe can route over nothing.
    if (_isRadioConnected == false) return const ConnectivityOffline();
    return switch ((_isRadioConnected, _isInternetReachable)) {
      (true, true) => const ConnectivityOnline(),
      (true, false) => const ConnectivityOffline(),
      _ => const ConnectivityUnknown(),
    };
  }

  void _emit(ConnectivityState verdict) {
    if (isClosed || verdict == state) return;
    if (verdict is ConnectivityUnknown) return;
    emit(verdict);
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    await _radioSubscription.cancel();
    await _reachabilitySubscription.cancel();
    return super.close();
  }
}

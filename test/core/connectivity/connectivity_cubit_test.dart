import 'dart:async';

import 'package:currency_exchange_tracker/core/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';

void main() {
  late StreamController<bool> radio;
  late StreamController<bool> internet;
  late FakeClock clock;
  late ConnectivityCubit cubit;
  late List<ConnectivityState> emitted;

  setUp(() {
    // Synchronous controllers: a source reading lands in the cubit the moment
    // it is added, so no test has to wait for delivery.
    radio = StreamController<bool>.broadcast(sync: true);
    internet = StreamController<bool>.broadcast(sync: true);
    clock = FakeClock(DateTime(2024, 3, 6, 12));
    cubit = ConnectivityCubit(
      radioConnected: radio.stream,
      internetReachable: internet.stream,
      clock: clock,
    );
    emitted = [];
    cubit.stream.listen(emitted.add);
  });

  tearDown(() async {
    await cubit.close();
    await radio.close();
    await internet.close();
    clock.dispose();
  });

  /// Elapses the debounce by firing whatever the cubit scheduled.
  void elapseDebounce() => clock.firePendingTimers();

  test('starts unknown — nothing has been observed yet', () {
    expect(cubit.state, const ConnectivityUnknown());
  });

  group('merging the radio with the reachability probe', () {
    test('a connected radio with reachable internet is online', () {
      radio.add(true);
      internet.add(true);

      expect(cubit.state, const ConnectivityOnline());
    });

    test('a connected radio with no internet is offline', () {
      // Airport wifi: the radio is happy, nothing routes.
      radio.add(true);
      internet.add(false);

      expect(cubit.state, const ConnectivityOffline());
    });

    test('a disconnected radio is offline without waiting for a probe', () {
      radio.add(false);

      expect(cubit.state, const ConnectivityOffline());
    });

    test('stays unknown while the radio is up but unprobed', () {
      radio.add(true);

      expect(cubit.state, const ConnectivityUnknown());
    });

    test('losing internet on a live radio goes offline', () {
      radio.add(true);
      internet
        ..add(true)
        ..add(false);
      elapseDebounce();

      expect(cubit.state, const ConnectivityOffline());
    });
  });

  group('debouncing', () {
    test('resolves the first reading without scheduling anything', () {
      radio.add(true);
      internet.add(true);

      expect(cubit.state, const ConnectivityOnline());
      expect(clock.pendingTimers, isEmpty);
    });

    test('schedules transitions at the two-second default', () {
      radio.add(true);
      internet.add(true);

      radio.add(false);

      expect(clock.requestedDelay, const Duration(seconds: 2));
    });

    test('holds a transition until the delay elapses', () {
      radio.add(true);
      internet.add(true);

      radio.add(false);
      expect(cubit.state, const ConnectivityOnline());

      elapseDebounce();
      expect(cubit.state, const ConnectivityOffline());
    });

    test('a flap that resolves back cancels the pending transition', () async {
      radio.add(true);
      internet.add(true);
      await pumpEventQueue();
      emitted.clear();

      // Down and up again before the delay elapses.
      radio
        ..add(false)
        ..add(true);

      expect(clock.pendingTimers, isEmpty);
      elapseDebounce();
      await pumpEventQueue();

      expect(emitted, isEmpty);
      expect(cubit.state, const ConnectivityOnline());
    });

    test('a storm of flapping settles on one emission', () async {
      radio.add(true);
      internet.add(true);
      await pumpEventQueue();
      emitted.clear();

      for (var flap = 0; flap < 10; flap++) {
        radio.add(flap.isEven);
      }
      radio.add(false);
      elapseDebounce();
      await pumpEventQueue();

      expect(emitted, [const ConnectivityOffline()]);
    });

    test('each new reading restarts the delay rather than stacking one', () {
      radio.add(true);
      internet.add(true);

      radio.add(false);
      internet.add(false);

      expect(clock.pendingTimers, hasLength(1));
    });
  });

  group('lifecycle', () {
    test('stops listening once closed', () async {
      radio.add(true);
      internet.add(true);
      await cubit.close();

      radio.add(false);
      elapseDebounce();

      expect(cubit.state, const ConnectivityOnline());
    });

    test('a pending debounce cannot fire after close', () async {
      radio.add(true);
      internet.add(true);

      // Transition queued but not yet due when the cubit goes away.
      radio.add(false);
      await cubit.close();
      elapseDebounce();

      expect(cubit.state, const ConnectivityOnline());
    });
  });
}

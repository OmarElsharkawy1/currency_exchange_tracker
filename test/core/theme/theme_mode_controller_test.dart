import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<String> {}

void main() {
  late MockBox box;
  late ThemeModeStore store;

  setUp(() {
    box = MockBox();
    store = ThemeModeStore(box);
    when(() => box.put(any<dynamic>(), any())).thenAnswer((_) async {});
    when(() => box.get(any<dynamic>())).thenReturn(null);
  });

  group('starting state', () {
    test('follows the device until told otherwise', () {
      expect(ThemeModeController().value, ThemeMode.system);
    });

    test('starts wherever it was left', () {
      expect(
        ThemeModeController(initial: ThemeMode.dark).value,
        ThemeMode.dark,
      );
    });
  });

  group('the cycle', () {
    test('runs system, light, dark, and back to system', () {
      final controller = ThemeModeController();
      final seen = <ThemeMode>[controller.value];

      for (var step = 0; step < 3; step++) {
        controller.next();
        seen.add(controller.value);
      }

      expect(seen, [
        ThemeMode.system,
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
      ]);
    });

    test('picks up mid-cycle from a restored mode', () {
      final controller = ThemeModeController(initial: ThemeMode.light)..next();

      expect(controller.value, ThemeMode.dark);
    });

    test('notifies once per step', () {
      var notifications = 0;
      ThemeModeController()
        ..addListener(() => notifications++)
        ..next()
        ..next();

      expect(notifications, 2);
    });
  });

  group('remembering', () {
    test('writes every step to the store', () async {
      ThemeModeController(store: store).next();
      await Future<void>.value();

      verify(() => box.put(ThemeModeStore.key, 'light')).called(1);
    });

    test('writes the mode it landed on, not the one it left', () async {
      ThemeModeController(initial: ThemeMode.dark, store: store).next();
      await Future<void>.value();

      verify(() => box.put(ThemeModeStore.key, 'system')).called(1);
    });

    test('works without a store at all', () {
      final controller = ThemeModeController()..next();

      expect(controller.value, ThemeMode.light);
      verifyNever(() => box.put(any<dynamic>(), any()));
    });
  });
}

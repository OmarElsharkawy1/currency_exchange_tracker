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

  group('round trip', () {
    for (final mode in ThemeMode.values) {
      test('survives a write and read of $mode', () async {
        await store.write(mode);

        final stored = verify(
          () => box.put(ThemeModeStore.key, captureAny()),
        ).captured.single;
        when(() => box.get(ThemeModeStore.key)).thenReturn(stored as String);

        expect(store.read(), mode);
      });
    }
  });

  group('reading nothing useful', () {
    test('an empty box follows the device', () {
      expect(store.read(), ThemeMode.system);
    });

    test('a value from a future version follows the device', () {
      when(() => box.get(ThemeModeStore.key)).thenReturn('sepia');

      expect(store.read(), ThemeMode.system);
    });

    test('an unreadable box follows the device', () {
      when(() => box.get(ThemeModeStore.key)).thenThrow(HiveError('closed'));

      expect(store.read(), ThemeMode.system);
    });
  });

  group('writing', () {
    test('stores the mode by name', () async {
      await store.write(ThemeMode.dark);

      verify(() => box.put(ThemeModeStore.key, 'dark')).called(1);
    });

    test('a failing write does not throw', () async {
      when(() => box.put(any<dynamic>(), any())).thenThrow(HiveError('full'));

      await expectLater(store.write(ThemeMode.light), completes);
    });
  });
}

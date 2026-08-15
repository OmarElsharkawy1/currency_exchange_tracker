import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_button.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ThemeModeController controller;
  late SemanticsHandle semantics;

  setUp(() {
    controller = ThemeModeController();
    // Semantics are off by default in widget tests; the label is the point
    // here, so switch the tree on.
    semantics = SemanticsBinding.instance.ensureSemantics();
  });

  tearDown(() {
    semantics.dispose();
    controller.dispose();
  });

  Future<void> pumpButton(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ThemeModeScope(
          controller: controller,
          child: const Scaffold(body: ThemeModeButton()),
        ),
      ),
    );
  }

  group('what it shows', () {
    testWidgets('names the mode, not the brightness on screen', (tester) async {
      await pumpButton(tester);

      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      expect(
        find.bySemanticsLabel('Theme: following the device'),
        findsOneWidget,
      );
    });

    testWidgets('shows light mode as light', (tester) async {
      controller.value = ThemeMode.light;
      await pumpButton(tester);

      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      expect(find.bySemanticsLabel('Theme: light'), findsOneWidget);
    });

    testWidgets('shows dark mode as dark', (tester) async {
      controller.value = ThemeMode.dark;
      await pumpButton(tester);

      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(find.bySemanticsLabel('Theme: dark'), findsOneWidget);
    });
  });

  group('what it does', () {
    testWidgets('walks the cycle a tap at a time', (tester) async {
      await pumpButton(tester);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(controller.value, ThemeMode.light);
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(controller.value, ThemeMode.dark);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(controller.value, ThemeMode.system);
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
    });
  });
}

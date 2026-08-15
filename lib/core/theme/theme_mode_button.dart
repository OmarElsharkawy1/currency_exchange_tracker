import 'package:currency_exchange_tracker/core/theme/theme_mode_scope.dart';
import 'package:flutter/material.dart';

/// Cycles the app through following the device, light, and dark.
///
/// The icon names the *mode*, not the brightness currently on screen, so
/// "following the device" is a state the user can see they are in rather than
/// one that masquerades as whichever theme it resolved to.
class ThemeModeButton extends StatelessWidget {
  /// Creates the button.
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeModeScope.of(context);
    final mode = controller.value;

    final label = _labelFor(mode);

    // The tooltip is the pointer affordance and the Semantics label is the
    // screen-reader one. The tooltip is excluded from semantics so assistive
    // tech announces the mode once, not twice.
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: IconButton(
          onPressed: controller.next,
          icon: Icon(_iconFor(mode)),
        ),
      ),
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };

  String _labelFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Theme: following the device',
    ThemeMode.light => 'Theme: light',
    ThemeMode.dark => 'Theme: dark',
  };
}

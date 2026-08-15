import 'dart:async';

import 'package:currency_exchange_tracker/core/theme/theme_mode_store.dart';
import 'package:flutter/material.dart';

/// Holds the theme the user has chosen, and remembers it.
///
/// A [ValueNotifier] rather than a cubit on purpose: the app has exactly three
/// blocs, and a theme choice is not a fourth piece of domain state. It is
/// provided at the composition root and read through `ThemeModeScope`.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  /// Creates a controller starting at [initial], persisting through [store].
  ///
  /// [store] is optional so tests that only care about the cycle need not
  /// bring storage with them; the composition root always supplies one.
  ThemeModeController({ThemeMode initial = ThemeMode.system, this.store})
    : super(initial);

  /// Where the choice is remembered, if anywhere.
  final ThemeModeStore? store;

  /// The order the button walks through.
  ///
  /// Deliberately returns to [ThemeMode.system]: without it, a user who tried
  /// the switch could never hand the decision back to the device.
  static const List<ThemeMode> cycle = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  /// Advances to the next mode in [cycle] and remembers it.
  void next() {
    final position = cycle.indexOf(value);
    value = cycle[(position + 1) % cycle.length];
    unawaited(store?.write(value));
  }
}

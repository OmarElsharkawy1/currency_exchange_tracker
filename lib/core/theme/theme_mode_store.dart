import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

/// Remembers the theme the user picked, across launches.
///
/// Shares the app's one Hive box of JSON-ish strings. It lives in `core/`
/// rather than the rates repository: a theme choice is not rate data, and
/// nothing in the feature module should have to know it exists.
class ThemeModeStore {
  /// Creates a store on an already-open [_box].
  const ThemeModeStore(this._box);

  final Box<String> _box;

  /// Key the chosen mode is stored under.
  static const String key = 'theme_mode';

  /// The stored mode, or [ThemeMode.system] when there is nothing readable.
  ///
  /// A missing, unrecognised or unreadable value all mean the same thing:
  /// the user has not chosen, so follow the device.
  ThemeMode read() {
    final String? stored;
    try {
      stored = _box.get(key);
      // Hive reports a closed or broken box as an Error; a preference we
      // cannot read is a preference we do not have.
      // ignore: avoid_catching_errors
    } on HiveError {
      return ThemeMode.system;
    }

    return switch (stored) {
      null => ThemeMode.system,
      final name => ThemeMode.values.firstWhere(
        (mode) => mode.name == name,
        orElse: () => ThemeMode.system,
      ),
    };
  }

  /// Stores [mode].
  ///
  /// Storage errors are swallowed: failing to remember a theme is not worth
  /// interrupting the app for.
  Future<void> write(ThemeMode mode) async {
    try {
      await _box.put(key, mode.name);
      // Same reasoning as read: storage trouble must not surface as a crash
      // over a theme switch.
      // ignore: avoid_catching_errors
    } on HiveError {
      // Nothing to recover: the choice still applies for this session.
    }
  }
}

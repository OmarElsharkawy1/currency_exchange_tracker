import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';

/// Makes the [ThemeModeController] reachable from the widget tree.
///
/// An [InheritedNotifier] rather than a `RepositoryProvider`: providers
/// deliberately refuse `Listenable`s, because they do not rebuild dependents
/// when one changes. This does, and it scopes that rebuild to the widgets
/// that actually asked for the theme.
class ThemeModeScope extends InheritedNotifier<ThemeModeController> {
  /// Creates the scope.
  const ThemeModeScope({
    required ThemeModeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The controller, registering the caller for rebuilds.
  static ThemeModeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    assert(scope != null, 'No ThemeModeScope above this widget.');
    return scope!.notifier!;
  }
}

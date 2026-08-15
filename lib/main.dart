import 'package:currency_exchange_tracker/app.dart';
import 'package:currency_exchange_tracker/core/di/injection.dart';
import 'package:currency_exchange_tracker/core/observers/app_bloc_observer.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Composition root: builds the object graph, then runs the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }

  await configureDependencies();

  // Read before the first frame so the app never paints the wrong theme and
  // then correct itself.
  final themeMode = getIt<ThemeModeStore>().read();

  runApp(CurrencyExchangeTrackerApp(initialThemeMode: themeMode));
}

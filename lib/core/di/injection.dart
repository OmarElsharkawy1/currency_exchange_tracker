import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:get_it/get_it.dart';

/// The app's service locator.
///
/// Only [configureDependencies] and the composition root in `main.dart` may
/// touch it. Widgets and blocs receive their collaborators through
/// constructors, never by reaching in here.
final GetIt getIt = GetIt.instance;

/// Registers everything the app needs at startup.
///
/// Async today only so later phases (Hive boxes, Dio) can await their own
/// initialization without changing the call site.
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<Clock>(SystemClock.new);
}

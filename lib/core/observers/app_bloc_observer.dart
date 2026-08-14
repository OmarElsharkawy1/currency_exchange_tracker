import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs bloc transitions and errors.
///
/// Wired into `Bloc.observer` only when [kDebugMode] is true, so release
/// builds pay nothing for it.
final class AppBlocObserver extends BlocObserver {
  /// Creates a debug bloc observer.
  const AppBlocObserver();

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    developer.log(
      '${transition.event.runtimeType} -> ${transition.nextState}',
      name: bloc.runtimeType.toString(),
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (bloc is Bloc) return; // Transitions already cover blocs.
    developer.log(
      '${change.currentState} -> ${change.nextState}',
      name: bloc.runtimeType.toString(),
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      'unhandled error',
      name: bloc.runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}

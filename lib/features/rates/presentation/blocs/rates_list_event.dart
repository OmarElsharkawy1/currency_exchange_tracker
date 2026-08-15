import 'package:equatable/equatable.dart';

/// Everything the rates list can be asked to do.
sealed class RatesListEvent extends Equatable {
  /// Creates an event.
  const RatesListEvent();

  @override
  List<Object?> get props => const [];
}

/// The list was opened: show whatever is available, cache included.
final class RatesRequested extends RatesListEvent {
  /// Creates the event.
  const RatesRequested();
}

/// The user pulled to refresh: go past the cache.
final class RatesRefreshed extends RatesListEvent {
  /// Creates the event.
  const RatesRefreshed();
}

/// Connectivity resolved to a new verdict.
///
/// The bloc reacts to the *transition*, not to the reading: coming back
/// online refreshes once, and nothing else about connectivity moves state.
final class RatesConnectivityChanged extends RatesListEvent {
  /// Creates the event.
  const RatesConnectivityChanged({required this.isOnline});

  /// Whether the device can now reach the network.
  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}

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

/// The user pulled to refresh, or connectivity came back: go past the cache.
final class RatesRefreshed extends RatesListEvent {
  /// Creates the event.
  const RatesRefreshed();
}

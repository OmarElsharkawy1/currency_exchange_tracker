import 'package:equatable/equatable.dart';

/// Whether the device can actually reach the network.
///
/// "Actually" is the point: a connected radio is not connectivity. This is
/// the merged verdict of the radio state and a reachability probe.
sealed class ConnectivityState extends Equatable {
  /// Creates a state.
  const ConnectivityState();

  @override
  List<Object?> get props => const [];
}

/// Nothing conclusive has been observed yet.
///
/// Emitted at cold start, and while a live radio has not been probed. Callers
/// treat it as "don't act", not as "offline".
final class ConnectivityUnknown extends ConnectivityState {
  /// Creates the state.
  const ConnectivityUnknown();
}

/// The radio is connected and the internet answered.
final class ConnectivityOnline extends ConnectivityState {
  /// Creates the state.
  const ConnectivityOnline();
}

/// Either the radio is down, or it is up and nothing routes.
final class ConnectivityOffline extends ConnectivityState {
  /// Creates the state.
  const ConnectivityOffline();
}

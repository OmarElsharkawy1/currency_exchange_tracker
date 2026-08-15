import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:equatable/equatable.dart';

/// What the rates list is showing.
///
/// One sealed family so the widget layer is a single exhaustive `switch` with
/// no other conditionals in it.
sealed class RatesListState extends Equatable {
  /// Creates a state.
  const RatesListState();

  @override
  List<Object?> get props => const [];
}

/// Rates are being loaded and the list shows skeletons.
final class RatesLoadInProgress extends RatesListState {
  /// Creates the state.
  const RatesLoadInProgress();
}

/// Rates are on screen.
final class RatesLoadSuccess extends RatesListState {
  /// Creates the state.
  const RatesLoadSuccess({
    required this.rates,
    required this.lastUpdated,
    required this.isFromCache,
  });

  /// One entry per tracked currency, already paired with its previous day.
  final List<RateComparison> rates;

  /// When the underlying payload was fetched — the "last updated" value.
  final DateTime lastUpdated;

  /// Whether these rates came from the cache rather than the network.
  final bool isFromCache;

  @override
  List<Object?> get props => [rates, lastUpdated, isFromCache];
}

/// The load succeeded but carried no rates.
///
/// Unreachable while the API publishes all five currencies; kept as its own
/// state so the empty case is a branch of the same `switch` rather than an
/// `isEmpty` check inside a widget.
final class RatesLoadEmpty extends RatesListState {
  /// Creates the state.
  const RatesLoadEmpty();
}

/// The load failed and there was nothing cached to fall back on.
final class RatesLoadFailure extends RatesListState {
  /// Creates the state.
  const RatesLoadFailure({required this.failure});

  /// What went wrong; the widget maps it to a message.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

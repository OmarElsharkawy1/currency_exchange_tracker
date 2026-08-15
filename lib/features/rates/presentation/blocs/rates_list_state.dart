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
    this.refreshFailure,
  });

  /// One entry per tracked currency, already paired with its previous day.
  final List<RateComparison> rates;

  /// When the underlying payload was fetched — the "last updated" value.
  final DateTime lastUpdated;

  /// Whether these rates came from the cache rather than the network.
  final bool isFromCache;

  /// Why the most recent refresh failed, if it did.
  ///
  /// The rates above are still the ones to show — a failed refresh never
  /// costs the user the data they already had. This field exists so the
  /// screen can *mention* the failure without becoming an error screen, and
  /// is cleared by the next successful load.
  final Failure? refreshFailure;

  @override
  List<Object?> get props => [
    rates,
    lastUpdated,
    isFromCache,
    refreshFailure,
  ];
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

/// The device is offline and the cache is empty.
///
/// Its own state rather than a [RatesLoadFailure]: nothing went wrong, there
/// is simply nothing to show yet, and the screen says so differently.
final class RatesUnavailableOffline extends RatesListState {
  /// Creates the state.
  const RatesUnavailableOffline();
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

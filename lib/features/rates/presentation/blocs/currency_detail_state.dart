import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:equatable/equatable.dart';

/// What the detail screen's chart is showing.
///
/// Covers the chart only. The header renders from the entity the route
/// carried, so it has no loading, empty or failure state of its own.
sealed class CurrencyDetailState extends Equatable {
  /// Creates a state.
  const CurrencyDetailState();

  @override
  List<Object?> get props => const [];
}

/// History is loading and the chart shows its skeleton.
final class HistoryLoadInProgress extends CurrencyDetailState {
  /// Creates the state.
  const HistoryLoadInProgress();
}

/// History is on screen.
final class HistoryLoadSuccess extends CurrencyDetailState {
  /// Creates the state.
  const HistoryLoadSuccess({required this.history, this.selectedIndex});

  /// The plotted days, oldest first.
  final RateHistory history;

  /// Which day the header is reading out, or `null` for the most recent.
  final int? selectedIndex;

  /// The day the header shows: the selected one, or the latest.
  ///
  /// The single thing the header reads, so a selected point and a resting
  /// header are the same shape of data and render through the same widget.
  RateHistoryPoint get selectedPoint => switch (selectedIndex) {
    null => history.latest,
    final index => history.pointAt(index) ?? history.latest,
  };

  /// Whether the header is showing the most recent day.
  bool get isShowingLatest => selectedIndex == null;

  @override
  List<Object?> get props => [history, selectedIndex];
}

/// The history came back with too few days to draw a line.
///
/// A walk-back can collapse several requested days onto one published
/// snapshot, so this is reachable — a single point is not a chart.
final class HistoryLoadEmpty extends CurrencyDetailState {
  /// Creates the state.
  const HistoryLoadEmpty();
}

/// The history could not be loaded.
final class HistoryLoadFailure extends CurrencyDetailState {
  /// Creates the state.
  const HistoryLoadFailure({required this.failure});

  /// What went wrong; the widget maps it to a message.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

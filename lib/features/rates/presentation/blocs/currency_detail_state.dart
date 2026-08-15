import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
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
  const HistoryLoadSuccess({required this.points});

  /// The published days, oldest first.
  final List<ExchangeRate> points;

  @override
  List<Object?> get props => [points];
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

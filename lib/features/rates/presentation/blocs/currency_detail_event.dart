import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:equatable/equatable.dart';

/// Everything the detail screen can be asked to do.
sealed class CurrencyDetailEvent extends Equatable {
  /// Creates an event.
  const CurrencyDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// The chart needs its history — on open, and again on retry.
///
/// Only the history: the current rate arrived through the route and is
/// already on screen.
final class HistoryRequested extends CurrencyDetailEvent {
  /// Requests the history of [currency].
  const HistoryRequested(this.currency);

  /// The currency being charted.
  final Currency currency;

  @override
  List<Object?> get props => [currency];
}

/// A point was tapped. The selection stays until cleared.
final class HistoryPointSelected extends CurrencyDetailEvent {
  /// Selects the point at [index].
  const HistoryPointSelected(this.index);

  /// Position in the history, oldest first.
  final int index;

  @override
  List<Object?> get props => [index];
}

/// The user asked to go back to the most recent day.
final class HistoryPointCleared extends CurrencyDetailEvent {
  /// Creates the event.
  const HistoryPointCleared();
}

/// A finger is being dragged across the chart.
///
/// Transient: what it shows lasts only as long as the touch, unless a tap
/// had already pinned a point.
final class HistoryScrubbed extends CurrencyDetailEvent {
  /// Reports the point at [index] as being under the finger.
  const HistoryScrubbed(this.index);

  /// Position in the history, oldest first.
  final int index;

  @override
  List<Object?> get props => [index];
}

/// The finger left the chart.
final class HistoryScrubEnded extends CurrencyDetailEvent {
  /// Creates the event.
  const HistoryScrubEnded();
}

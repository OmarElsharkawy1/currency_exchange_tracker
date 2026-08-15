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

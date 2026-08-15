import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:equatable/equatable.dart';

/// A currency's plotted history, oldest first.
///
/// Every point except possibly the oldest carries its predecessor, so the
/// chart can report a movement for each day it draws.
class RateHistory extends Equatable {
  /// Creates a history from [points], which must run oldest to newest.
  const RateHistory({required this.points});

  /// The plotted days, oldest first.
  final List<RateHistoryPoint> points;

  /// The most recent day — the one the resting header shows.
  RateHistoryPoint get latest => points.last;

  /// How many days are plotted.
  int get length => points.length;

  /// The point at [index], or `null` when there is none.
  ///
  /// Returning `null` rather than throwing keeps out-of-range selections —
  /// a stale index after a refresh, a touch past the last dot — from being
  /// an error the UI has to guard against.
  RateHistoryPoint? pointAt(int index) {
    if (index < 0 || index >= points.length) return null;
    return points[index];
  }

  @override
  List<Object?> get props => [points];
}

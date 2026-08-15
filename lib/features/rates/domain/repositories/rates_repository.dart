import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rates_snapshot.dart';

/// The one way into rate data.
///
/// Implementations own the cache policies, the host fallback and the date
/// anchoring; callers see entities and failures only.
abstract class RatesRepository {
  /// The latest rates for every tracked currency, each paired with the
  /// previous published day.
  ///
  /// Serves a recent cache without touching the network. When the cache is
  /// stale (or [forceRefresh] is set, as on pull-to-refresh and on
  /// reconnect) it refetches, and falls back to whatever the cache holds if
  /// the network is unreachable.
  Future<Result<RatesSnapshot>> getLatestRates({bool forceRefresh = false});

  /// The last [days] published rates for [currency], oldest first.
  ///
  /// Every returned point carries the day before it, so the chart can report
  /// a movement for each day it draws. That costs one extra fetch: `days + 1`
  /// dates are read, and the oldest is used only as the first point's
  /// predecessor.
  ///
  /// Dates are anchored on the `date` field of the latest payload, never on
  /// device local time, and the newest point is that same anchor date — the
  /// resting header and the last plotted dot are the same rate. Days already
  /// in the immutable cache are never refetched.
  Future<Result<RateHistory>> getHistory(Currency currency, {int days = 7});
}

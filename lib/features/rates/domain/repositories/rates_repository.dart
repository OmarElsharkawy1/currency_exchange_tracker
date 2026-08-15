import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
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
  /// Dates are anchored on the `date` field of the latest payload, never on
  /// device local time. Days already in the immutable cache are never
  /// refetched.
  Future<Result<List<ExchangeRate>>> getHistory(
    Currency currency, {
    int days = 7,
  });
}

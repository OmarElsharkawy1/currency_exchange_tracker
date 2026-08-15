import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:equatable/equatable.dart';

/// The rates list as of one moment: every tracked currency, plus where the
/// data came from.
class RatesSnapshot extends Equatable {
  /// Creates a snapshot.
  const RatesSnapshot({
    required this.rates,
    required this.fetchedAt,
    required this.isFromCache,
  });

  /// One entry per tracked currency, ordered by `Currency.values`.
  final List<RateComparison> rates;

  /// When the underlying payload was fetched from the network.
  ///
  /// This is what the "last updated" indicator shows — for cached data it is
  /// the original fetch time, not the time it was read back.
  final DateTime fetchedAt;

  /// Whether these rates were served from the cache rather than the network.
  final bool isFromCache;

  @override
  List<Object?> get props => [rates, fetchedAt, isFromCache];
}

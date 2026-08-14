import 'package:equatable/equatable.dart';

/// Base type for every recoverable error that crosses the data-layer
/// boundary.
///
/// Raw exceptions (`DioException`, `SocketException`, parse errors) are
/// mapped to one of these subtypes inside the data sources, so blocs and
/// widgets only ever switch over this sealed hierarchy.
sealed class Failure extends Equatable {
  /// Creates a failure.
  const Failure();

  @override
  List<Object?> get props => const [];
}

/// The device could not reach the currency API at all.
///
/// Covers DNS resolution errors, socket errors, connection refusals and
/// non-2xx responses that are not tied to a specific missing rate file.
final class NetworkFailure extends Failure {
  /// Creates a network failure, optionally carrying the HTTP [statusCode]
  /// that produced it.
  const NetworkFailure({this.statusCode});

  /// HTTP status code of the failed response, when the request reached the
  /// server. `null` for transport-level errors.
  final int? statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// A request exceeded its connect, send or receive timeout.
final class TimeoutFailure extends Failure {
  /// Creates a timeout failure.
  const TimeoutFailure();
}

/// The cache was asked for an entry it does not hold.
final class CacheMissFailure extends Failure {
  /// Creates a cache-miss failure for the entry stored under [key].
  const CacheMissFailure({this.key});

  /// Cache key that was requested, when known.
  final String? key;

  @override
  List<Object?> get props => [key];
}

/// A response was reached and read, but its payload did not match the
/// expected shape.
final class ParseFailure extends Failure {
  /// Creates a parse failure.
  const ParseFailure();
}

/// No rate exists for the requested currency on the requested date, and the
/// walk-back budget was exhausted without finding one.
final class RateUnavailableFailure extends Failure {
  /// Creates a rate-unavailable failure for [currencyCode] on
  /// [requestedDate] (`YYYY-MM-DD`).
  const RateUnavailableFailure({this.currencyCode, this.requestedDate});

  /// Currency the rate was requested for, when known.
  final String? currencyCode;

  /// The `YYYY-MM-DD` date the walk-back started from, when known.
  final String? requestedDate;

  @override
  List<Object?> get props => [currencyCode, requestedDate];
}

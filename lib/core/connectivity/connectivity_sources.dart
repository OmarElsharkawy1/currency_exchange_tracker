import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:currency_exchange_tracker/core/network/currency_api_endpoints.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Adapters turning the two connectivity packages into plain `bool` streams.
///
/// Keeping the package types at this boundary is what lets `ConnectivityCubit`
/// be tested with two `StreamController`s instead of platform channels.
abstract final class ConnectivitySources {
  /// How long the probe waits before calling the API unreachable.
  static const Duration probeTimeout = Duration(seconds: 5);

  /// Whether the device has *any* radio connection.
  ///
  /// This is the optimistic half: a `wifi` result here says a network was
  /// joined, not that anything routes. Pair it with [internetReachable].
  static Stream<bool> radioConnected(Connectivity connectivity) =>
      connectivity.onConnectivityChanged.map(
        (results) => results.any(
          (result) => result != ConnectivityResult.none,
        ),
      );

  /// A probe that asks the currency API itself, and nothing else.
  ///
  /// The package's default hosts answer a different question — "does some
  /// well-known server respond?" — which can be true on a network that blocks
  /// the API, and false on one that only allows it.
  ///
  /// Both mirrors are probed, and the checker reports success if either
  /// answers, because the Dio host-fallback interceptor makes either one
  /// enough to serve rates. Probing only jsDelivr would report offline on a
  /// network where the app can still work through `pages.dev`. Both URLs come
  /// from [CurrencyApiEndpoints], so the hosts stay a single source of truth
  /// with the data source.
  static InternetConnection currencyApiProbe() =>
      InternetConnection.createInstance(
        useDefaultOptions: false,
        customCheckOptions: [
          InternetCheckOption(
            uri: CurrencyApiEndpoints.primary(
              CurrencyApiEndpoints.latestVersion,
            ),
            timeout: probeTimeout,
          ),
          InternetCheckOption(
            uri: CurrencyApiEndpoints.fallback(
              CurrencyApiEndpoints.latestVersion,
            ),
            timeout: probeTimeout,
          ),
        ],
      );

  /// Whether a real request actually reached the API.
  static Stream<bool> internetReachable(InternetConnection checker) =>
      checker.onStatusChange.map(
        (status) => status == InternetStatus.connected,
      );
}

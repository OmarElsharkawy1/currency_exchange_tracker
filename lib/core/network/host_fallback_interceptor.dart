import 'package:currency_exchange_tracker/core/network/currency_api_endpoints.dart';
import 'package:dio/dio.dart';

/// Retries a failed primary-mirror request against the fallback mirror.
///
/// The two mirrors serve the same documents, so a transport error or a server
/// error on jsDelivr is worth one retry on `currency-api.pages.dev`.
///
/// A `404` is *not* retried: it means the requested dated snapshot does not
/// exist upstream, which is equally true on both mirrors. Retrying it would
/// double every request of the historical walk-back for nothing, and would
/// slow the walk-back down over weekends, when files are legitimately
/// absent.
class HostFallbackInterceptor extends Interceptor {
  /// Creates the interceptor.
  ///
  /// The callback returns the client the retry is issued on; it is a callback
  /// because the interceptor is installed on the very client it needs.
  HostFallbackInterceptor(this._dioRef);

  final Dio Function() _dioRef;

  /// Marks a request that already went through the fallback, so a failure on
  /// the second mirror is not retried again.
  static const String _fallbackAttemptedKey = 'hostFallbackAttempted';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (options.extra[_fallbackAttemptedKey] == true) {
      return handler.next(err);
    }
    if (err.response?.statusCode == 404) {
      return handler.next(err);
    }

    final fallbackUri = CurrencyApiEndpoints.fallbackFor(options.uri);
    if (fallbackUri == null) {
      return handler.next(err);
    }

    try {
      final response = await _dioRef().fetch<dynamic>(
        options.copyWith(
          path: fallbackUri.toString(),
          queryParameters: const <String, dynamic>{},
          extra: <String, dynamic>{
            ...options.extra,
            _fallbackAttemptedKey: true,
          },
        ),
      );
      return handler.resolve(response);
    } on DioException catch (fallbackError) {
      return handler.next(fallbackError);
    }
  }
}

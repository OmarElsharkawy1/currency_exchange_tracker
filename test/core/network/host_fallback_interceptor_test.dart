import 'package:currency_exchange_tracker/core/network/currency_api_endpoints.dart';
import 'package:currency_exchange_tracker/core/network/host_fallback_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

const _body = '{"date":"2024-03-06","egp":{"usd":0.019227}}';

ResponseBody _ok(String body) => ResponseBody.fromString(
  body,
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _status(int statusCode) => ResponseBody.fromString(
  '',
  statusCode,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  late MockHttpClientAdapter adapter;
  late Dio dio;
  late List<Uri> requestedUris;

  setUp(() {
    adapter = MockHttpClientAdapter();
    dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(HostFallbackInterceptor(() => dio));
    requestedUris = [];
  });

  /// Answers every request by consulting [byHost], keyed on the request host.
  void stub(Map<String, ResponseBody Function()> byHost) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) {
      final options = invocation.positionalArguments.first as RequestOptions;
      requestedUris.add(options.uri);
      final answer = byHost[options.uri.host];
      if (answer == null) {
        throw StateError('Unstubbed host: ${options.uri.host}');
      }
      return Future.value(answer());
    });
  }

  final latestPrimary = CurrencyApiEndpoints.primary(
    CurrencyApiEndpoints.latestVersion,
  );
  final latestFallback = CurrencyApiEndpoints.fallback(
    CurrencyApiEndpoints.latestVersion,
  );

  test('leaves a successful primary request alone', () async {
    stub({latestPrimary.host: () => _ok(_body)});

    final response = await dio.getUri<String>(latestPrimary);

    expect(response.statusCode, 200);
    expect(requestedUris, [latestPrimary]);
  });

  test(
    'retries on the fallback host when the primary connection fails',
    () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) {
        final options = invocation.positionalArguments.first as RequestOptions;
        requestedUris.add(options.uri);
        if (options.uri.host == latestPrimary.host) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return Future.value(_ok(_body));
      });

      final response = await dio.getUri<String>(latestPrimary);

      expect(response.data, _body);
      expect(requestedUris, [latestPrimary, latestFallback]);
    },
  );

  test('retries on the fallback host when the primary returns 500', () async {
    stub({
      latestPrimary.host: () => _status(500),
      latestFallback.host: () => _ok(_body),
    });

    final response = await dio.getUri<String>(latestPrimary);

    expect(response.data, _body);
    expect(requestedUris, [latestPrimary, latestFallback]);
  });

  test('does not fall back on 404 — a missing date file is missing on both '
      'mirrors', () async {
    stub({latestPrimary.host: () => _status(404)});

    await expectLater(
      dio.getUri<String>(latestPrimary),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          404,
        ),
      ),
    );
    expect(requestedUris, [latestPrimary]);
  });

  test('surfaces the fallback failure when both hosts fail', () async {
    stub({
      latestPrimary.host: () => _status(500),
      latestFallback.host: () => _status(503),
    });

    await expectLater(
      dio.getUri<String>(latestPrimary),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'statusCode',
          503,
        ),
      ),
    );
    expect(requestedUris, [latestPrimary, latestFallback]);
  });

  test(
    'does not retry a request that already went to the fallback host',
    () async {
      stub({latestFallback.host: () => _status(500)});

      await expectLater(
        dio.getUri<String>(latestFallback),
        throwsA(isA<DioException>()),
      );
      expect(requestedUris, [latestFallback]);
    },
  );

  test('ignores failures for URLs outside the currency API', () async {
    final unrelated = Uri.parse('https://example.com/thing.json');
    stub({unrelated.host: () => _status(500)});

    await expectLater(
      dio.getUri<String>(unrelated),
      throwsA(isA<DioException>()),
    );
    expect(requestedUris, [unrelated]);
  });

  test(
    'carries the dated snapshot version across to the fallback host',
    () async {
      final datedPrimary = CurrencyApiEndpoints.primary('2024-03-06');
      stub({
        datedPrimary.host: () => _status(500),
        CurrencyApiEndpoints.fallback('2024-03-06').host: () => _ok(_body),
      });

      await dio.getUri<String>(datedPrimary);

      expect(requestedUris, [
        datedPrimary,
        CurrencyApiEndpoints.fallback('2024-03-06'),
      ]);
    },
  );
}

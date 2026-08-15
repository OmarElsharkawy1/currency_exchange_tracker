import 'dart:io';

import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/core/network/currency_api_endpoints.dart';
import 'package:currency_exchange_tracker/core/network/host_fallback_interceptor.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

String bodyFor(String date, {double usd = 0.019227}) =>
    '{"date":"$date","egp":{"usd":$usd,"eur":0.017821,"gbp":0.015231,'
    '"sar":0.072103,"jpy":2.9012,"aed":0.070624}}';

ResponseBody okBody(String body) => ResponseBody.fromString(
  body,
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody statusBody(int statusCode) => ResponseBody.fromString(
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
  late RatesRemoteDataSource dataSource;

  setUp(() {
    adapter = MockHttpClientAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    requestedUris = [];
    dataSource = RatesRemoteDataSourceImpl(dio);
  });

  /// Answers every request from [answer], recording what was asked for.
  void stubByUri(ResponseBody Function(Uri uri) answer) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) {
      final options = invocation.positionalArguments.first as RequestOptions;
      requestedUris.add(options.uri);
      return Future.value(answer(options.uri));
    });
  }

  /// Makes every request fail with [error].
  void stubThrowing(DioException Function(RequestOptions options) error) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) {
      final options = invocation.positionalArguments.first as RequestOptions;
      requestedUris.add(options.uri);
      throw error(options);
    });
  }

  final latestUri = CurrencyApiEndpoints.primary(
    CurrencyApiEndpoints.latestVersion,
  );

  group('fetchLatest', () {
    test(
      'requests the primary latest endpoint and parses the payload',
      () async {
        stubByUri((_) => okBody(bodyFor('2024-03-06')));

        final (rates, failure) = await dataSource.fetchLatest();

        expect(failure, isNull);
        expect(rates!.date, DateTime.utc(2024, 3, 6));
        expect(rates.rates[Currency.usd], 0.019227);
        expect(requestedUris, [latestUri]);
      },
    );

    test(
      'succeeds through the fallback mirror when the primary is down',
      () async {
        dio.interceptors.add(HostFallbackInterceptor(() => dio));
        stubByUri(
          (uri) => uri.host == CurrencyApiEndpoints.primaryHost
              ? statusBody(500)
              : okBody(bodyFor('2024-03-06')),
        );

        final (rates, failure) = await dataSource.fetchLatest();

        expect(failure, isNull);
        expect(rates!.date, DateTime.utc(2024, 3, 6));
        expect(requestedUris, [
          latestUri,
          CurrencyApiEndpoints.fallback(CurrencyApiEndpoints.latestVersion),
        ]);
      },
    );

    test('maps a malformed payload to ParseFailure', () async {
      stubByUri((_) => okBody('{"date":"2024-03-06","egp":{"usd":0.019227}}'));

      final (rates, failure) = await dataSource.fetchLatest();

      expect(rates, isNull);
      expect(failure, const ParseFailure());
    });

    test('maps a non-JSON body to ParseFailure', () async {
      stubByUri((_) => ResponseBody.fromString('<html>nope</html>', 200));

      final (rates, failure) = await dataSource.fetchLatest();

      expect(rates, isNull);
      expect(failure, const ParseFailure());
    });

    test(
      'maps a 404 on latest to NetworkFailure carrying the status',
      () async {
        stubByUri((_) => statusBody(404));

        final (rates, failure) = await dataSource.fetchLatest();

        expect(rates, isNull);
        expect(failure, const NetworkFailure(statusCode: 404));
      },
    );
  });

  group('DioException -> Failure mapping', () {
    final mappings = <String, (DioExceptionType, Failure)>{
      'connectionTimeout': (
        DioExceptionType.connectionTimeout,
        const TimeoutFailure(),
      ),
      'sendTimeout': (DioExceptionType.sendTimeout, const TimeoutFailure()),
      'receiveTimeout': (
        DioExceptionType.receiveTimeout,
        const TimeoutFailure(),
      ),
      'transformTimeout': (
        DioExceptionType.transformTimeout,
        const TimeoutFailure(),
      ),
      'connectionError': (
        DioExceptionType.connectionError,
        const NetworkFailure(),
      ),
      'badCertificate': (
        DioExceptionType.badCertificate,
        const NetworkFailure(),
      ),
      'cancel': (DioExceptionType.cancel, const NetworkFailure()),
      'unknown': (DioExceptionType.unknown, const NetworkFailure()),
    };

    for (final entry in mappings.entries) {
      test('${entry.key} maps to ${entry.value.$2.runtimeType}', () async {
        final (type, expectedFailure) = entry.value;
        stubThrowing(
          (options) => DioException(requestOptions: options, type: type),
        );

        final (rates, failure) = await dataSource.fetchLatest();

        expect(rates, isNull);
        expect(failure, expectedFailure);
      });
    }

    test('a wrapped SocketException maps to NetworkFailure', () async {
      stubThrowing(
        (options) => DioException(
          requestOptions: options,
          error: const SocketException('No route to host'),
        ),
      );

      final (rates, failure) = await dataSource.fetchLatest();

      expect(rates, isNull);
      expect(failure, const NetworkFailure());
    });

    test('a 500 response maps to NetworkFailure carrying the status', () async {
      stubByUri((_) => statusBody(500));

      final (rates, failure) = await dataSource.fetchLatest();

      expect(rates, isNull);
      expect(failure, const NetworkFailure(statusCode: 500));
    });

    test('no raw exception escapes the data source', () async {
      stubThrowing(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(dataSource.fetchLatest(), completes);
      await expectLater(
        dataSource.fetchForDate(DateTime.utc(2024, 3, 6)),
        completes,
      );
    });
  });

  group('fetchForDate', () {
    test('requests the dated snapshot and parses it', () async {
      stubByUri((_) => okBody(bodyFor('2024-03-06')));

      final (rates, failure) = await dataSource.fetchForDate(
        DateTime.utc(2024, 3, 6),
      );

      expect(failure, isNull);
      expect(rates!.date, DateTime.utc(2024, 3, 6));
      expect(requestedUris, [CurrencyApiEndpoints.primary('2024-03-06')]);
    });

    test('walks back one day at a time while the snapshot 404s', () async {
      // Sunday and Saturday are missing; Friday resolves.
      stubByUri(
        (uri) => uri.toString().contains('2024-03-01')
            ? okBody(bodyFor('2024-03-01'))
            : statusBody(404),
      );

      final (rates, failure) = await dataSource.fetchForDate(
        DateTime.utc(2024, 3, 3),
      );

      expect(failure, isNull);
      expect(rates!.date, DateTime.utc(2024, 3));
      expect(requestedUris.map((uri) => uri.toString()), [
        CurrencyApiEndpoints.primary('2024-03-03').toString(),
        CurrencyApiEndpoints.primary('2024-03-02').toString(),
        CurrencyApiEndpoints.primary('2024-03-01').toString(),
      ]);
    });

    test('takes at most three extra steps before giving up', () async {
      stubByUri((_) => statusBody(404));

      final (rates, failure) = await dataSource.fetchForDate(
        DateTime.utc(2024, 3, 6),
      );

      expect(rates, isNull);
      expect(
        failure,
        const RateUnavailableFailure(requestedDate: '2024-03-06'),
      );
      expect(requestedUris.length, 4);
      expect(requestedUris.last, CurrencyApiEndpoints.primary('2024-03-03'));
    });

    test('resolves on the last allowed step', () async {
      stubByUri(
        (uri) => uri.toString().contains('2024-03-03')
            ? okBody(bodyFor('2024-03-03'))
            : statusBody(404),
      );

      final (rates, failure) = await dataSource.fetchForDate(
        DateTime.utc(2024, 3, 6),
      );

      expect(failure, isNull);
      expect(rates!.date, DateTime.utc(2024, 3, 3));
      expect(requestedUris.length, 4);
    });

    test('does not walk back on a non-404 failure', () async {
      stubByUri((_) => statusBody(500));

      final (rates, failure) = await dataSource.fetchForDate(
        DateTime.utc(2024, 3, 6),
      );

      expect(rates, isNull);
      expect(failure, const NetworkFailure(statusCode: 500));
      expect(requestedUris, [CurrencyApiEndpoints.primary('2024-03-06')]);
    });

    test('does not walk back on a parse failure', () async {
      stubByUri((_) => okBody('{"date":"2024-03-06"}'));

      final (rates, failure) = await dataSource.fetchForDate(
        DateTime.utc(2024, 3, 6),
      );

      expect(rates, isNull);
      expect(failure, const ParseFailure());
      expect(requestedUris.length, 1);
    });
  });
}

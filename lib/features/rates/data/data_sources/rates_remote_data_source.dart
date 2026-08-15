import 'dart:convert';

import 'package:currency_exchange_tracker/core/extensions/date_time_extensions.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/core/network/currency_api_endpoints.dart';
import 'package:currency_exchange_tracker/features/rates/data/dtos/rates_response_dto.dart';
import 'package:dio/dio.dart';

/// Reads exchange rates off the network.
///
/// Every implementation is responsible for turning transport and parsing
/// errors into a [Failure]; no raw exception may cross this boundary.
abstract class RatesRemoteDataSource {
  /// The most recently published rates.
  Future<Result<RatesResponseDto>> fetchLatest();

  /// The snapshot published for [date].
  ///
  /// Dated files are missing on days the upstream feed did not publish, so a
  /// `404` steps one day back and retries, up to
  /// [RatesRemoteDataSourceImpl.maxWalkBackSteps] extra days, before
  /// returning a [RateUnavailableFailure].
  Future<Result<RatesResponseDto>> fetchForDate(DateTime date);
}

/// [RatesRemoteDataSource] backed by Dio.
///
/// The host fallback lives in an interceptor on the injected client, so this
/// class only ever addresses the primary mirror.
class RatesRemoteDataSourceImpl implements RatesRemoteDataSource {
  /// Creates the data source on [_dio].
  const RatesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  /// How many extra days back a missing snapshot may be searched for.
  static const int maxWalkBackSteps = 3;

  @override
  Future<Result<RatesResponseDto>> fetchLatest() =>
      _get(CurrencyApiEndpoints.latestVersion);

  @override
  Future<Result<RatesResponseDto>> fetchForDate(DateTime date) async {
    var candidate = date;
    for (var step = 0; step <= maxWalkBackSteps; step++) {
      final (rates, failure) = await _get(candidate.toApiDate());
      if (rates != null) return success(rates);
      if (failure is! NetworkFailure || failure.statusCode != 404) {
        return failed(failure!);
      }
      candidate = candidate.subtract(const Duration(days: 1));
    }
    return failed(RateUnavailableFailure(requestedDate: date.toApiDate()));
  }

  Future<Result<RatesResponseDto>> _get(String version) async {
    try {
      final response = await _dio.getUri<dynamic>(
        CurrencyApiEndpoints.primary(version),
      );
      return success(_parse(response.data));
    } on DioException catch (error) {
      return failed(_failureFor(error));
    } on FormatException {
      return failed(const ParseFailure());
    }
  }

  RatesResponseDto _parse(dynamic data) {
    final decoded = data is String ? jsonDecode(data) : data;
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response body is not a JSON object.');
    }
    return RatesResponseDto.fromJson(decoded);
  }

  Failure _failureFor(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const TimeoutFailure(),
      DioExceptionType.badResponse => NetworkFailure(
        statusCode: error.response?.statusCode,
      ),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel => const NetworkFailure(),
      // `unknown` wraps whatever escaped the transport: a SocketException on
      // a dead radio, or a decode error from Dio's own JSON transformer.
      DioExceptionType.unknown =>
        error.error is FormatException
            ? const ParseFailure()
            : const NetworkFailure(),
    };
  }
}

import 'dart:convert';

import 'package:currency_exchange_tracker/core/extensions/date_time_extensions.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/data/dtos/rates_response_dto.dart';
import 'package:hive_ce/hive.dart';

/// A cached `latest` payload together with the moment it was fetched.
///
/// The timestamp is what the "last updated" banner shows when the app is
/// offline.
typedef CachedLatestRates = ({RatesResponseDto rates, DateTime fetchedAt});

/// Reads and writes rate payloads in the on-device cache.
///
/// Two policies, deliberately different:
///
/// * `latest` is mutable and timestamped — every refresh overwrites it.
/// * a dated snapshot is written once and never touched again. Historical
///   rates cannot change, so re-fetching or expiring them would be a bug.
abstract class RatesLocalDataSource {
  /// The cached `latest` payload, or a [CacheMissFailure] when there is none.
  Future<Result<CachedLatestRates>> readLatest();

  /// Stores [rates] as the `latest` payload, stamped [fetchedAt].
  ///
  /// Overwrites any previous entry. Storage errors are swallowed: a cache
  /// write that fails costs a later network call, it does not fail the
  /// operation that produced the data.
  Future<void> writeLatest(
    RatesResponseDto rates, {
    required DateTime fetchedAt,
  });

  /// The cached snapshot for [date], or a [CacheMissFailure].
  Future<Result<RatesResponseDto>> readForDate(DateTime date);

  /// Stores [rates] under its own [RatesResponseDto.date], unless a snapshot
  /// for that date is already held.
  Future<void> writeForDate(RatesResponseDto rates);
}

/// [RatesLocalDataSource] backed by a Hive box of JSON strings.
///
/// No adapters and no generated code: the box holds exactly the JSON the API
/// speaks, plus a timestamp envelope for `latest`.
class RatesLocalDataSourceImpl implements RatesLocalDataSource {
  /// Creates the data source on an already-open [_box].
  const RatesLocalDataSourceImpl(this._box);

  final Box<String> _box;

  /// Key the mutable `latest` envelope is stored under.
  static const String latestKey = 'latest';

  /// Prefix for the immutable dated snapshots.
  static const String historicalKeyPrefix = 'historical_';

  /// Cache key for the snapshot of [date].
  static String historicalKeyFor(DateTime date) =>
      '$historicalKeyPrefix${date.toApiDate()}';

  @override
  Future<Result<CachedLatestRates>> readLatest() async {
    final raw = _read(latestKey);
    if (raw == null) return failed(const CacheMissFailure(key: latestKey));

    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) {
        throw const FormatException('Cache envelope is not a JSON object.');
      }
      final fetchedAt = envelope['fetchedAt'];
      final payload = envelope['rates'];
      if (fetchedAt is! String || payload is! Map<String, dynamic>) {
        throw const FormatException('Cache envelope is missing fields.');
      }
      return success((
        rates: RatesResponseDto.fromJson(payload),
        fetchedAt: DateTime.parse(fetchedAt),
      ));
    } on FormatException {
      // A cache entry we cannot read is a cache entry we do not have.
      return failed(const CacheMissFailure(key: latestKey));
    }
  }

  @override
  Future<void> writeLatest(
    RatesResponseDto rates, {
    required DateTime fetchedAt,
  }) async {
    await _write(
      latestKey,
      jsonEncode(<String, dynamic>{
        'fetchedAt': fetchedAt.toIso8601String(),
        'rates': rates.toJson(),
      }),
    );
  }

  @override
  Future<Result<RatesResponseDto>> readForDate(DateTime date) async {
    final key = historicalKeyFor(date);
    final raw = _read(key);
    if (raw == null) return failed(CacheMissFailure(key: key));

    try {
      final payload = jsonDecode(raw);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Cached snapshot is not a JSON object.');
      }
      return success(RatesResponseDto.fromJson(payload));
    } on FormatException {
      return failed(CacheMissFailure(key: key));
    }
  }

  @override
  Future<void> writeForDate(RatesResponseDto rates) async {
    final key = historicalKeyFor(rates.date);
    try {
      if (_box.containsKey(key)) return;
      // Hive reports a closed or broken box as an Error; a cache that cannot
      // answer is simply a cache we skip.
      // ignore: avoid_catching_errors
    } on HiveError {
      return;
    }
    await _write(key, jsonEncode(rates.toJson()));
  }

  String? _read(String key) {
    try {
      return _box.get(key);
      // ignore: avoid_catching_errors — see writeForDate.
    } on HiveError {
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _box.put(key, value);
      // ignore: avoid_catching_errors — see writeForDate.
    } on HiveError {
      // Nothing to recover: the caller already holds the data in memory.
    }
  }
}

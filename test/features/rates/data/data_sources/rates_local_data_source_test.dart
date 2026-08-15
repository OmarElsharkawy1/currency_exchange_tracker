import 'dart:convert';

import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_local_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/dtos/rates_response_dto.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<String> {}

RatesResponseDto dtoFor(String date, {double usd = 0.019227}) =>
    RatesResponseDto.fromJson(<String, dynamic>{
      'date': date,
      'egp': <String, dynamic>{
        'usd': usd,
        'eur': 0.017821,
        'gbp': 0.015231,
        'sar': 0.072103,
        'jpy': 2.9012,
      },
    });

void main() {
  late MockBox box;
  late RatesLocalDataSource dataSource;

  setUp(() {
    box = MockBox();
    dataSource = RatesLocalDataSourceImpl(box);
    when(() => box.put(any<dynamic>(), any())).thenAnswer((_) async {});
    when(() => box.containsKey(any<dynamic>())).thenReturn(false);
    when(() => box.get(any<dynamic>())).thenReturn(null);
  });

  group('latest — refreshable, timestamped', () {
    final fetchedAt = DateTime.utc(2024, 3, 6, 9, 30);

    test(
      'writes an envelope carrying the payload and the fetch time',
      () async {
        await dataSource.writeLatest(
          dtoFor('2024-03-06'),
          fetchedAt: fetchedAt,
        );

        final stored = verify(
          () => box.put(RatesLocalDataSourceImpl.latestKey, captureAny()),
        ).captured.single;
        final decoded = jsonDecode(stored as String) as Map<String, dynamic>;
        expect(decoded['fetchedAt'], fetchedAt.toIso8601String());
        expect((decoded['rates'] as Map)['date'], '2024-03-06');
      },
    );

    test('reads the payload and the fetch time back', () async {
      await dataSource.writeLatest(dtoFor('2024-03-06'), fetchedAt: fetchedAt);
      final stored = verify(
        () => box.put(RatesLocalDataSourceImpl.latestKey, captureAny()),
      ).captured.single;
      when(
        () => box.get(RatesLocalDataSourceImpl.latestKey),
      ).thenReturn(stored as String);

      final (cached, failure) = await dataSource.readLatest();

      expect(failure, isNull);
      expect(cached!.fetchedAt, fetchedAt);
      expect(cached.rates.date, DateTime.utc(2024, 3, 6));
      expect(cached.rates.rates[Currency.usd], 0.019227);
    });

    test('overwrites an existing entry — latest is refreshable', () async {
      when(
        () => box.containsKey(RatesLocalDataSourceImpl.latestKey),
      ).thenReturn(true);

      await dataSource.writeLatest(dtoFor('2024-03-07'), fetchedAt: fetchedAt);

      verify(
        () => box.put(RatesLocalDataSourceImpl.latestKey, any()),
      ).called(1);
    });

    test('reports a cache miss when nothing is stored', () async {
      final (cached, failure) = await dataSource.readLatest();

      expect(cached, isNull);
      expect(
        failure,
        const CacheMissFailure(key: RatesLocalDataSourceImpl.latestKey),
      );
    });

    test('treats a corrupt entry as a cache miss', () async {
      when(
        () => box.get(RatesLocalDataSourceImpl.latestKey),
      ).thenReturn('not json at all');

      final (cached, failure) = await dataSource.readLatest();

      expect(cached, isNull);
      expect(
        failure,
        const CacheMissFailure(key: RatesLocalDataSourceImpl.latestKey),
      );
    });

    test(
      'treats an envelope with a missing timestamp as a cache miss',
      () async {
        when(() => box.get(RatesLocalDataSourceImpl.latestKey)).thenReturn(
          jsonEncode(<String, dynamic>{'rates': dtoFor('2024-03-06').toJson()}),
        );

        final (cached, failure) = await dataSource.readLatest();

        expect(cached, isNull);
        expect(
          failure,
          const CacheMissFailure(key: RatesLocalDataSourceImpl.latestKey),
        );
      },
    );

    test('treats an unreadable box as a cache miss', () async {
      when(
        () => box.get(RatesLocalDataSourceImpl.latestKey),
      ).thenThrow(HiveError('box is closed'));

      final (cached, failure) = await dataSource.readLatest();

      expect(cached, isNull);
      expect(
        failure,
        const CacheMissFailure(key: RatesLocalDataSourceImpl.latestKey),
      );
    });

    test('a failing box write does not throw', () async {
      when(
        () => box.put(any<dynamic>(), any()),
      ).thenThrow(HiveError('disk full'));

      await expectLater(
        dataSource.writeLatest(dtoFor('2024-03-06'), fetchedAt: fetchedAt),
        completes,
      );
    });
  });

  group('historical — write-once and immutable', () {
    final date = DateTime.utc(2024, 3, 6);
    const key = 'historical_2024-03-06';

    test('writes a dated snapshot under its own key', () async {
      await dataSource.writeForDate(dtoFor('2024-03-06'));

      final stored = verify(() => box.put(key, captureAny())).captured.single;
      final decoded = jsonDecode(stored as String) as Map<String, dynamic>;
      expect(decoded['date'], '2024-03-06');
      expect((decoded['egp'] as Map)['usd'], 0.019227);
    });

    test('never overwrites a snapshot it already holds', () async {
      when(() => box.containsKey(key)).thenReturn(true);

      await dataSource.writeForDate(dtoFor('2024-03-06', usd: 0.0191));

      verifyNever(() => box.put(key, any()));
    });

    test(
      'keys the snapshot by the payload date, not by the requested date',
      () async {
        // A walk-back can answer a Sunday request with Friday's file.
        await dataSource.writeForDate(dtoFor('2024-03-01'));

        verify(() => box.put('historical_2024-03-01', any())).called(1);
      },
    );

    test('reads a stored snapshot back', () async {
      when(
        () => box.get(key),
      ).thenReturn(jsonEncode(dtoFor('2024-03-06').toJson()));

      final (rates, failure) = await dataSource.readForDate(date);

      expect(failure, isNull);
      expect(rates, dtoFor('2024-03-06'));
    });

    test('reports a cache miss for a date it does not hold', () async {
      final (rates, failure) = await dataSource.readForDate(date);

      expect(rates, isNull);
      expect(failure, const CacheMissFailure(key: key));
    });

    test('treats a corrupt snapshot as a cache miss', () async {
      when(() => box.get(key)).thenReturn('{"date":"2024-03-06"}');

      final (rates, failure) = await dataSource.readForDate(date);

      expect(rates, isNull);
      expect(failure, const CacheMissFailure(key: key));
    });
  });
}

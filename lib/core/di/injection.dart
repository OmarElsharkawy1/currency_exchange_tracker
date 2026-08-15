import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/network/host_fallback_interceptor.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_local_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/data_sources/rates_remote_data_source.dart';
import 'package:currency_exchange_tracker/features/rates/data/repositories/rates_repository_impl.dart';
import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// The app's service locator.
///
/// Only [configureDependencies] and the composition root in `main.dart` may
/// touch it. Widgets and blocs receive their collaborators through
/// constructors, never by reaching in here.
final GetIt getIt = GetIt.instance;

/// Name of the Hive box holding cached rate payloads as JSON strings.
const String ratesCacheBoxName = 'rates_cache';

/// Registers everything the app needs at startup.
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<Clock>(SystemClock.new);

  await Hive.initFlutter();
  final ratesBox = await Hive.openBox<String>(ratesCacheBoxName);
  getIt
    ..registerSingleton<Box<String>>(ratesBox)
    ..registerLazySingleton<Dio>(() {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      // The interceptor retries on the client it is installed on, hence the
      // callback rather than the instance.
      return dio..interceptors.add(HostFallbackInterceptor(() => dio));
    })
    ..registerLazySingleton<RatesRemoteDataSource>(
      () => RatesRemoteDataSourceImpl(getIt<Dio>()),
    )
    ..registerLazySingleton<RatesLocalDataSource>(
      () => RatesLocalDataSourceImpl(getIt<Box<String>>()),
    )
    ..registerLazySingleton<RatesRepository>(
      () => RatesRepositoryImpl(
        remoteDataSource: getIt<RatesRemoteDataSource>(),
        localDataSource: getIt<RatesLocalDataSource>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerFactory<RatesListBloc>(
      () => RatesListBloc(repository: getIt<RatesRepository>()),
    );
}

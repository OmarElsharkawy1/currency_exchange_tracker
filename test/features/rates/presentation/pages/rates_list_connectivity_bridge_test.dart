import 'dart:async';

import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_scope.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rates_snapshot.dart';
import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/rates_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/fake_clock.dart';

class MockRatesRepository extends Mock implements RatesRepository {}

/// End-to-end over the connectivity seam: a real [ConnectivityCubit] feeding a
/// real [RatesListBloc] through the page's listener.
///
/// The other tests cover the halves — the page test verifies the cubit's
/// emission reaches `bloc.add`, the bloc test verifies the event reaches the
/// repository — and nothing joined them until this one. Everything asserted
/// here is produced by delivery, not by a hand-added event.
void main() {
  late MockRatesRepository repository;
  late StreamController<bool> radio;
  late StreamController<bool> internet;
  late FakeClock clock;
  late ConnectivityCubit connectivity;
  late RatesListBloc bloc;

  final fetchedAt = DateTime(2024, 3, 6, 9, 5);
  final rates = [
    RateComparison(
      current: ExchangeRate(
        currency: Currency.usd,
        rawRate: 0.019100,
        date: DateTime.utc(2024, 3, 6),
      ),
      previous: ExchangeRate(
        currency: Currency.usd,
        rawRate: 0.019227,
        date: DateTime.utc(2024, 3, 5),
      ),
    ),
  ];

  /// Builds the real object graph.
  ///
  /// Called inside each test body, not in `setUp`: a bloc created outside the
  /// widget-test's async zone never advances when the tester pumps.
  void buildDependencies() {
    repository = MockRatesRepository();
    radio = StreamController<bool>.broadcast(sync: true);
    internet = StreamController<bool>.broadcast(sync: true);
    clock = FakeClock(DateTime(2024, 3, 6, 9, 10));
    connectivity = ConnectivityCubit(
      radioConnected: radio.stream,
      internetReachable: internet.stream,
      clock: clock,
    );
    bloc = RatesListBloc(repository: repository);

    when(
      () => repository.getLatestRates(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer(
      (_) async => success(
        RatesSnapshot(
          rates: rates,
          fetchedAt: fetchedAt,
          isFromCache: false,
        ),
      ),
    );
  }

  tearDown(() {
    // Not awaited: these complete through the widget-test binding, which is
    // no longer pumping by the time teardown runs.
    unawaited(bloc.close());
    unawaited(connectivity.close());
    unawaited(radio.close());
    unawaited(internet.close());
    clock.dispose();
  });

  /// Lets the event queue drain and the widget tree rebuild.
  ///
  /// Not `pumpAndSettle`: the loading skeleton shimmers forever, so "settled"
  /// never arrives.
  Future<void> settle(WidgetTester tester) async {
    // A bloc event reaches the widget tree across several microtask hops:
    // event queue, handler await, state emission, rebuild.
    for (var pump = 0; pump < 5; pump++) {
      await tester.pump();
    }
    // Past the row entrance animations, which otherwise leave timers pending.
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> pumpPage(WidgetTester tester) async {
    buildDependencies();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ThemeModeScope(
          controller: ThemeModeController(),
          child: RepositoryProvider<Clock>.value(
            value: clock,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<RatesListBloc>.value(value: bloc),
                BlocProvider<ConnectivityCubit>.value(value: connectivity),
              ],
              child: const RatesListPage(),
            ),
          ),
        ),
      ),
    );
    bloc.add(const RatesRequested());
    await settle(tester);
  }

  testWidgets('a real reconnect drives a real refresh, exactly once', (
    tester,
  ) async {
    await pumpPage(tester);
    clearInteractions(repository);

    // Radio drops: the cubit resolves offline on its first conclusive reading.
    radio.add(false);
    await settle(tester);

    expect(find.textContaining('Offline'), findsOneWidget);
    verifyNever(
      () => repository.getLatestRates(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    );

    // Radio and probe both come back. The verdict is debounced, so nothing
    // has happened yet.
    radio.add(true);
    internet.add(true);
    await settle(tester);

    verifyNever(
      () => repository.getLatestRates(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    );

    // Elapsing the debounce is what lets the verdict out of the cubit.
    clock.firePendingTimers();
    await settle(tester);

    verify(() => repository.getLatestRates(forceRefresh: true)).called(1);
    expect(find.textContaining('Offline'), findsNothing);
  });

  testWidgets('a flap that never settles never reaches the repository', (
    tester,
  ) async {
    await pumpPage(tester);
    clearInteractions(repository);

    radio.add(false);
    await settle(tester);
    clearInteractions(repository);

    // Up and down again inside one debounce window: the cubit cancels its own
    // pending transition, so nothing is delivered and nothing refreshes.
    radio.add(true);
    internet.add(true);
    radio.add(false);
    clock.firePendingTimers();
    await settle(tester);

    verifyNever(
      () => repository.getLatestRates(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    );
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('the offline banner is driven by delivery, not by the state '
      'the bloc happens to hold', (tester) async {
    await pumpPage(tester);

    expect(find.textContaining('Last updated'), findsOneWidget);

    radio.add(true);
    internet.add(false);
    await settle(tester);

    expect(
      find.text('Offline — last updated 5 minutes ago'),
      findsOneWidget,
    );
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_state.dart';
import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/core/navigation/app_routes.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_scope.dart';
import 'package:currency_exchange_tracker/core/theme/trend_colors.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/rates_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../support/fake_clock.dart';

class MockRatesListBloc extends MockBloc<RatesListEvent, RatesListState>
    implements RatesListBloc {}

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

RateComparison comparison(
  Currency currency, {
  required double rawRate,
  double? previousRawRate,
}) {
  return RateComparison(
    current: ExchangeRate(
      currency: currency,
      rawRate: rawRate,
      date: DateTime.utc(2024, 3, 6),
    ),
    previous: previousRawRate == null
        ? null
        : ExchangeRate(
            currency: currency,
            rawRate: previousRawRate,
            date: DateTime.utc(2024, 3, 5),
          ),
  );
}

/// USD: raw fell, so a dollar costs more pounds — the pound weakened.
final RateComparison weakeningUsd = comparison(
  Currency.usd,
  rawRate: 0.019100,
  previousRawRate: 0.019227,
);

/// EUR: the mirror case — the pound strengthened.
final RateComparison strengtheningEur = comparison(
  Currency.eur,
  rawRate: 0.019227,
  previousRawRate: 0.019100,
);

final lastUpdated = DateTime(2024, 3, 6, 9, 5);

void main() {
  setUpAll(() {
    registerFallbackValue(const RatesRequested());
  });

  late MockRatesListBloc bloc;
  late MockConnectivityCubit connectivity;
  late FakeClock clock;
  late ThemeModeController themeMode;

  setUp(() {
    bloc = MockRatesListBloc();
    connectivity = MockConnectivityCubit();
    clock = FakeClock(DateTime(2024, 3, 6, 9, 10));
    themeMode = ThemeModeController();
  });

  tearDown(() => themeMode.dispose());

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: ThemeModeScope(
      controller: themeMode,
      child: RepositoryProvider<Clock>.value(
        value: clock,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RatesListBloc>.value(value: bloc),
            BlocProvider<ConnectivityCubit>.value(value: connectivity),
          ],
          child: child,
        ),
      ),
    ),
  );

  Future<void> pumpPage(
    WidgetTester tester,
    RatesListState state, {
    ConnectivityState connectivityState = const ConnectivityOnline(),
  }) async {
    bloc = MockRatesListBloc();
    when(() => bloc.state).thenReturn(state);
    when(() => connectivity.state).thenReturn(connectivityState);
    await tester.pumpWidget(wrap(const RatesListPage()));
  }

  group('while loading', () {
    testWidgets('shows skeleton rows, never a spinner', (tester) async {
      await pumpPage(tester, const RatesLoadInProgress());

      final skeletonizer = tester
          .widgetList<Skeletonizer>(
            find.byWidgetPredicate((widget) => widget is Skeletonizer),
          )
          .single;
      expect(skeletonizer.enabled, isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('with rates', () {
    testWidgets('states the rate as a sentence', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('US Dollar'), findsOneWidget);
    });

    testWidgets('shows the absolute and percentage movement', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.text('+0.35'), findsOneWidget);
      expect(find.text('+0.66%'), findsOneWidget);
    });

    testWidgets('paints a weakening pound with the weakening color', (
      tester,
    ) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      final percent = tester.widget<Text>(find.text('+0.66%'));
      expect(percent.style?.color, TrendColors.light.weakening);
    });

    testWidgets('paints a strengthening pound with the strengthening color', (
      tester,
    ) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [strengtheningEur],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      final percent = tester.widget<Text>(find.text('-0.66%'));
      expect(percent.style?.color, TrendColors.light.strengthening);
    });

    testWidgets('labels each row for a screen reader', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(
        find.bySemanticsLabel(
          'US Dollar, 52.36 Egyptian pounds, up 0.66 '
          'percent',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says unchanged when there is no previous day', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [comparison(Currency.usd, rawRate: 0.019100)],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(
        find.bySemanticsLabel('US Dollar, 52.36 Egyptian pounds, unchanged'),
        findsOneWidget,
      );
    });

    testWidgets('renders one row per currency', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd, strengtheningEur],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.text('US Dollar'), findsOneWidget);
      expect(find.text('Euro'), findsOneWidget);
    });

    testWidgets('shows when the data was last updated', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      expect(find.textContaining('Mar 6, 09:05'), findsOneWidget);
    });

    testWidgets('says the rates were saved, without claiming offline', (
      tester,
    ) async {
      // Cache-served while online is stale, not disconnected: only the
      // connectivity cubit gets to say "Offline".
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: true,
        ),
      );

      expect(find.textContaining('Showing saved rates'), findsOneWidget);
      expect(find.textContaining('Offline'), findsNothing);
    });

    testWidgets('pulling down asks for a refresh', (tester) async {
      await pumpPage(
        tester,
        RatesLoadSuccess(
          rates: [weakeningUsd, strengtheningEur],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );

      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => bloc.add(const RatesRefreshed())).called(1);
    });
  });

  group('a refresh that fails while rates are on screen', () {
    final loaded = RatesLoadSuccess(
      rates: [weakeningUsd],
      lastUpdated: lastUpdated,
      isFromCache: false,
    );
    final failedRefresh = RatesLoadSuccess(
      rates: [weakeningUsd],
      lastUpdated: lastUpdated,
      isFromCache: false,
      refreshFailure: const TimeoutFailure(),
    );

    testWidgets('says so in a snack bar', (tester) async {
      whenListen(
        bloc,
        Stream<RatesListState>.fromIterable([loaded, failedRefresh]),
        initialState: loaded,
      );
      when(() => connectivity.state).thenReturn(const ConnectivityOnline());

      await tester.pumpWidget(wrap(const RatesListPage()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('took too long'), findsOneWidget);
    });

    testWidgets('keeps the rates visible behind it', (tester) async {
      whenListen(
        bloc,
        Stream<RatesListState>.fromIterable([loaded, failedRefresh]),
        initialState: loaded,
      );
      when(() => connectivity.state).thenReturn(const ConnectivityOnline());

      await tester.pumpWidget(wrap(const RatesListPage()));
      await tester.pump();

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('says nothing when the refresh succeeds', (tester) async {
      whenListen(
        bloc,
        Stream<RatesListState>.fromIterable([loaded, loaded]),
        initialState: loaded,
      );
      when(() => connectivity.state).thenReturn(const ConnectivityOnline());

      await tester.pumpWidget(wrap(const RatesListPage()));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('does not repeat itself while the failure stands', (
      tester,
    ) async {
      whenListen(
        bloc,
        Stream<RatesListState>.fromIterable([
          loaded,
          failedRefresh,
          // Same failure still standing, e.g. a connectivity event rebuilt it.
          failedRefresh,
        ]),
        initialState: loaded,
      );
      when(() => connectivity.state).thenReturn(const ConnectivityOnline());

      await tester.pumpWidget(wrap(const RatesListPage()));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('the route contract', () {
    testWidgets('tapping a row hands the entity to the detail route', (
      tester,
    ) async {
      final pushed = <RouteSettings>[];
      bloc = MockRatesListBloc();
      when(() => bloc.state).thenReturn(
        RatesLoadSuccess(
          rates: [weakeningUsd],
          lastUpdated: lastUpdated,
          isFromCache: false,
        ),
      );
      when(() => connectivity.state).thenReturn(const ConnectivityOnline());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          onGenerateRoute: (settings) {
            pushed.add(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ThemeModeScope(
                controller: themeMode,
                child: RepositoryProvider<Clock>.value(
                  value: clock,
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<RatesListBloc>.value(value: bloc),
                      BlocProvider<ConnectivityCubit>.value(
                        value: connectivity,
                      ),
                    ],
                    child: const RatesListPage(),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('US Dollar'));
      await tester.pumpAndSettle();

      expect(pushed.last.name, AppRoutes.currencyDetail);
      expect(pushed.last.arguments, weakeningUsd);
    });
  });

  group('offline', () {
    final loaded = RatesLoadSuccess(
      rates: [weakeningUsd],
      lastUpdated: DateTime(2024, 3, 6, 9, 5),
      isFromCache: true,
    );

    testWidgets('banners the offline state with a relative timestamp', (
      tester,
    ) async {
      await pumpPage(
        tester,
        loaded,
        connectivityState: const ConnectivityOffline(),
      );

      expect(find.text('Offline — last updated 5 minutes ago'), findsOneWidget);
    });

    testWidgets('keeps the rates on screen while offline', (tester) async {
      await pumpPage(
        tester,
        loaded,
        connectivityState: const ConnectivityOffline(),
      );

      expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
    });

    testWidgets('shows an absolute timestamp once back online', (tester) async {
      await pumpPage(tester, loaded);

      expect(find.textContaining('Mar 6, 09:05'), findsOneWidget);
      expect(find.textContaining('Offline'), findsNothing);
    });

    testWidgets('an empty cache offline is its own screen, not an error', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const RatesUnavailableOffline(),
        connectivityState: const ConnectivityOffline(),
      );

      expect(find.textContaining('No connection'), findsOneWidget);
      expect(find.textContaining("Couldn't connect"), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tells the bloc when connectivity resolves', (tester) async {
      whenListen(
        connectivity,
        Stream<ConnectivityState>.fromIterable([
          const ConnectivityOffline(),
          const ConnectivityOnline(),
        ]),
        initialState: const ConnectivityUnknown(),
      );
      when(() => bloc.state).thenReturn(loaded);

      await tester.pumpWidget(wrap(const RatesListPage()));
      await tester.pump();

      verify(
        () => bloc.add(const RatesConnectivityChanged(isOnline: false)),
      ).called(1);
      verify(
        () => bloc.add(const RatesConnectivityChanged(isOnline: true)),
      ).called(1);
    });

    testWidgets('says nothing to the bloc while connectivity is unknown', (
      tester,
    ) async {
      whenListen(
        connectivity,
        const Stream<ConnectivityState>.empty(),
        initialState: const ConnectivityUnknown(),
      );
      when(() => bloc.state).thenReturn(loaded);

      await tester.pumpWidget(wrap(const RatesListPage()));
      await tester.pump();

      verifyNever(() => bloc.add(any(that: isA<RatesConnectivityChanged>())));
    });
  });

  group('when empty', () {
    testWidgets('explains that there is nothing to show', (tester) async {
      await pumpPage(tester, const RatesLoadEmpty());

      expect(find.textContaining('No rates'), findsOneWidget);
    });
  });

  group('when it fails', () {
    testWidgets('shows a friendly message, never the exception', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const RatesLoadFailure(failure: NetworkFailure(statusCode: 500)),
      );

      expect(find.textContaining('connect'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('500'), findsNothing);
    });

    testWidgets('maps each failure type to its own message', (tester) async {
      await pumpPage(tester, const RatesLoadFailure(failure: TimeoutFailure()));
      expect(find.textContaining('took too long'), findsOneWidget);

      await pumpPage(
        tester,
        const RatesLoadFailure(failure: RateUnavailableFailure()),
      );
      expect(find.textContaining('not published'), findsOneWidget);

      await pumpPage(tester, const RatesLoadFailure(failure: ParseFailure()));
      expect(find.textContaining("couldn't be read"), findsOneWidget);
    });

    testWidgets('retrying asks for a refresh', (tester) async {
      await pumpPage(
        tester,
        const RatesLoadFailure(failure: NetworkFailure()),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => bloc.add(const RatesRefreshed())).called(1);
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_state.dart';
import 'package:currency_exchange_tracker/core/navigation/app_routes.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_controller.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_scope.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/currency_detail_page.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/rates_list_page.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/currency_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/fake_clock.dart';

class MockRatesListBloc extends MockBloc<RatesListEvent, RatesListState>
    implements RatesListBloc {}

class MockCurrencyDetailBloc
    extends MockBloc<CurrencyDetailEvent, CurrencyDetailState>
    implements CurrencyDetailBloc {}

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

final RateComparison usd = RateComparison(
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
);

void main() {
  late MockRatesListBloc listBloc;
  late MockCurrencyDetailBloc detailBloc;
  late MockConnectivityCubit connectivity;
  late ThemeModeController themeMode;
  late FakeClock clock;

  setUp(() {
    listBloc = MockRatesListBloc();
    detailBloc = MockCurrencyDetailBloc();
    connectivity = MockConnectivityCubit();
    themeMode = ThemeModeController();
    clock = FakeClock(DateTime(2024, 3, 6, 9, 10));

    when(() => listBloc.state).thenReturn(
      RatesLoadSuccess(
        rates: [usd],
        lastUpdated: DateTime(2024, 3, 6, 9, 5),
        isFromCache: false,
      ),
    );
    when(() => detailBloc.state).thenReturn(const HistoryLoadInProgress());
    when(() => connectivity.state).thenReturn(const ConnectivityOnline());
  });

  tearDown(() {
    themeMode.dispose();
    clock.dispose();
  });

  Widget scope(Widget child) => ThemeModeScope(
    controller: themeMode,
    child: RepositoryProvider<Clock>.value(value: clock, child: child),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: AppRoutes.ratesList,
        onGenerateRoute: (settings) => switch (settings.name) {
          AppRoutes.currencyDetail => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => scope(
              BlocProvider<CurrencyDetailBloc>.value(
                value: detailBloc,
                child: CurrencyDetailPage(
                  comparison: settings.arguments! as RateComparison,
                ),
              ),
            ),
          ),
          _ => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => scope(
              MultiBlocProvider(
                providers: [
                  BlocProvider<RatesListBloc>.value(value: listBloc),
                  BlocProvider<ConnectivityCubit>.value(value: connectivity),
                ],
                child: const RatesListPage(),
              ),
            ),
          ),
        },
      ),
    );
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.byType(CurrencyBadge));
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.pageBack();
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  group('the hero tag', () {
    testWidgets('appears exactly once on the list', (tester) async {
      await pumpApp(tester);

      final heroes = tester
          .widgetList<Hero>(find.byType(Hero))
          .where(
            (hero) =>
                hero.tag ==
                CurrencyDetailPage.heroTagFor(
                  Currency.usd,
                ),
          );
      expect(heroes.length, 1);
    });

    testWidgets('appears exactly once on the detail screen', (tester) async {
      await pumpApp(tester);
      await openDetail(tester);

      final heroes = tester
          .widgetList<Hero>(find.byType(Hero))
          .where(
            (hero) =>
                hero.tag ==
                CurrencyDetailPage.heroTagFor(
                  Currency.usd,
                ),
          );
      expect(heroes.length, 1);
    });

    testWidgets('carries the badge, not text', (tester) async {
      await pumpApp(tester);

      final hero = tester.widget<Hero>(find.byType(Hero).first);
      expect(hero.child, isA<CurrencyBadge>());
    });
  });

  group('the flight', () {
    testWidgets('measures the same at both ends', (tester) async {
      await pumpApp(tester);
      final onList = tester.getSize(find.byType(CurrencyBadge));

      await openDetail(tester);
      final onDetail = tester.getSize(find.byType(CurrencyBadge));

      // Equal rects mean the hero has nothing to interpolate, which is what
      // stops the code clipping to "US" halfway across.
      expect(onDetail, onList);
      expect(onList, const Size.square(CurrencyBadge.size));
    });

    testWidgets('holds its size on every frame in between', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(CurrencyBadge));

      final sizes = <Size>{};
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
        for (final badge in find.byType(CurrencyBadge).evaluate()) {
          sizes.add(tester.getSize(find.byWidget(badge.widget)));
        }
      }

      expect(sizes, {const Size.square(CurrencyBadge.size)});
    });

    testWidgets('survives repeated pushes and pops', (tester) async {
      await pumpApp(tester);

      for (var trip = 0; trip < 3; trip++) {
        await openDetail(tester);
        expect(find.byType(CurrencyDetailPage), findsOneWidget);
        expect(find.byType(CurrencyBadge), findsOneWidget);

        await goBack(tester);
        expect(find.byType(RatesListPage), findsOneWidget);
        expect(find.byType(CurrencyBadge), findsOneWidget);
      }

      expect(tester.takeException(), isNull);
    });
  });
}

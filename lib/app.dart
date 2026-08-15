import 'package:currency_exchange_tracker/core/di/injection.dart';
import 'package:currency_exchange_tracker/core/navigation/app_routes.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/currency_detail_page.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/rates_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root widget: theming and navigation host.
///
/// The composition root reaches into the service locator here, once, so no
/// widget or bloc below has to. Every screen gets its bloc from a route.
class CurrencyExchangeTrackerApp extends StatelessWidget {
  /// Creates the app root.
  const CurrencyExchangeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Exchange Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: AppRoutes.ratesList,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<void>? _onGenerateRoute(RouteSettings settings) =>
      switch (settings.name) {
        AppRoutes.ratesList => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<RatesListBloc>(
            create: (_) => getIt<RatesListBloc>()..add(const RatesRequested()),
            child: const RatesListPage(),
          ),
        ),
        AppRoutes.currencyDetail => _currencyDetailRoute(settings),
        _ => null,
      };

  /// The detail route carries the currency's [RateComparison] as its
  /// argument, so the screen paints the rate without refetching it.
  Route<void> _currencyDetailRoute(RouteSettings settings) {
    final comparison = settings.arguments! as RateComparison;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => BlocProvider<CurrencyDetailBloc>(
        create: (_) =>
            getIt<CurrencyDetailBloc>()
              ..add(HistoryRequested(comparison.currency)),
        child: CurrencyDetailPage(comparison: comparison),
      ),
    );
  }
}

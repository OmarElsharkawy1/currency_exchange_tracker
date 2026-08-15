import 'package:currency_exchange_tracker/core/di/injection.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/pages/rates_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root widget: theming and navigation host.
///
/// The composition root reaches into the service locator here, once, so no
/// widget or bloc below has to.
class CurrencyExchangeTrackerApp extends StatelessWidget {
  /// Creates the app root.
  const CurrencyExchangeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Exchange Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: BlocProvider<RatesListBloc>(
        create: (_) => getIt<RatesListBloc>()..add(const RatesRequested()),
        child: const RatesListPage(),
      ),
    );
  }
}

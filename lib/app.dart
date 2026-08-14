import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Root widget: theming and navigation host.
///
/// The rates feature is wired in a later phase; the placeholder home below
/// exists only so the scaffold runs.
class CurrencyExchangeTrackerApp extends StatelessWidget {
  /// Creates the app root.
  const CurrencyExchangeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Exchange Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Currency Exchange Tracker')),
    );
  }
}

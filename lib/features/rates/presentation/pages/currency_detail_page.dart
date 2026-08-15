import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/exchange_rate.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/currency_detail_header.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart_skeleton.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rates_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One currency's detail screen: the rate now, and the last seven days.
///
/// The rate, its movement and its date arrive through the route inside
/// [comparison] and are painted on the first frame. Only the chart loads.
class CurrencyDetailPage extends StatefulWidget {
  /// Creates the screen for [comparison].
  const CurrencyDetailPage({required this.comparison, super.key});

  /// Today's rate and the previous day, as the list already had them.
  final RateComparison comparison;

  /// Hero tag shared between the list row and this screen's header.
  static String heroTagFor(Currency currency) =>
      'currency-code-${currency.code}';

  @override
  State<CurrencyDetailPage> createState() => _CurrencyDetailPageState();
}

class _CurrencyDetailPageState extends State<CurrencyDetailPage> {
  /// The day under the finger while scrubbing the chart.
  ExchangeRate? _scrubbedPoint;

  void _onPointScrubbed(ExchangeRate? point) {
    setState(() => _scrubbedPoint = point);
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.comparison.currency;

    return Scaffold(
      appBar: AppBar(title: Text(currency.englishName)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CurrencyDetailHeader(
              comparison: widget.comparison,
              scrubbedPoint: _scrubbedPoint,
              heroTag: CurrencyDetailPage.heroTagFor(currency),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.sectionGap,
                  AppSpacing.pageHorizontal,
                  AppSpacing.pageBottom,
                ),
                child: BlocBuilder<CurrencyDetailBloc, CurrencyDetailState>(
                  builder: (context, state) => switch (state) {
                    HistoryLoadInProgress() => const RateHistoryChartSkeleton(),
                    HistoryLoadSuccess() => RateHistoryChart(
                      points: state.points,
                      onPointScrubbed: _onPointScrubbed,
                    ),
                    HistoryLoadEmpty() => const _NoHistory(),
                    HistoryLoadFailure() => RatesErrorView(
                      failure: state.failure,
                      onRetry: () => context.read<CurrencyDetailBloc>().add(
                        HistoryRequested(currency),
                      ),
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when too few days came back to draw a line.
class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No history to chart for these days yet.',
        textAlign: TextAlign.center,
        style: context.textStyles.bodyLarge?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:currency_exchange_tracker/core/theme/app_spacing.dart';
import 'package:currency_exchange_tracker/core/theme/theme_mode_button.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/currency.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_direction.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_history_point.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/formatting/rate_semantics.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/currency_badge.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_history_chart_skeleton.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rates_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One currency's detail screen: a rate readout, and the last seven days.
///
/// The rate arrives through the route inside [comparison] and is painted on
/// the first frame as a [RateHistoryPoint], the same type the chart hands
/// back when a day is touched — so the resting header and the touched header
/// are one widget rendering one shape of data.
class CurrencyDetailPage extends StatelessWidget {
  /// Creates the screen for [comparison].
  const CurrencyDetailPage({required this.comparison, super.key});

  /// Today's rate and the previous day, as the list already had them.
  final RateComparison comparison;

  /// Hero tag shared between the list row and this screen's header.
  static String heroTagFor(Currency currency) =>
      'currency-code-${currency.code}';

  /// The route's rate as a history point, for the frames before history
  /// arrives — and for every frame after a load fails.
  RateHistoryPoint get _routePoint =>
      RateHistoryPoint(rate: comparison.current, previous: comparison.previous);

  @override
  Widget build(BuildContext context) {
    final currency = comparison.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(currency.englishName),
        actions: const [ThemeModeButton()],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only the header rebuilds when the selection moves.
            BlocBuilder<CurrencyDetailBloc, CurrencyDetailState>(
              buildWhen: _headerNeedsRebuild,
              builder: (context, state) => _RateHeader(
                point: switch (state) {
                  HistoryLoadSuccess() => state.selectedPoint,
                  _ => _routePoint,
                },
                isShowingLatest: switch (state) {
                  HistoryLoadSuccess() => state.isShowingLatest,
                  _ => true,
                },
                heroTag: heroTagFor(currency),
              ),
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
                      history: state.history,
                      selectedIndex: state.selectedIndex,
                      onPointTapped: (index) => context
                          .read<CurrencyDetailBloc>()
                          .add(HistoryPointSelected(index)),
                      onScrubbed: (index) => context
                          .read<CurrencyDetailBloc>()
                          .add(HistoryScrubbed(index)),
                      onScrubEnded: () => context
                          .read<CurrencyDetailBloc>()
                          .add(const HistoryScrubEnded()),
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

  /// The header only cares about which day is being read out.
  static bool _headerNeedsRebuild(
    CurrencyDetailState previous,
    CurrencyDetailState current,
  ) {
    return switch ((previous, current)) {
      (HistoryLoadSuccess(), HistoryLoadSuccess()) => true,
      _ => previous.runtimeType != current.runtimeType,
    };
  }
}

/// The screen's readout: one widget, whichever day it is showing.
///
/// The resting header and a touched day render through this same tree with
/// the same styles — only the values differ. A day with no predecessor keeps
/// the movement slot and fills it with an em-dash, so nothing shifts.
class _RateHeader extends StatelessWidget {
  const _RateHeader({
    required this.point,
    required this.isShowingLatest,
    required this.heroTag,
  });

  /// The day being read out.
  final RateHistoryPoint point;

  /// Whether that day is the most recent one.
  final bool isShowingLatest;

  /// Hero tag shared with the list row.
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageHorizontal,
        AppSpacing.pageTop,
        AppSpacing.pageHorizontal,
        AppSpacing.sectionGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sized by the badge, which is the tallest thing in the row and is
          // always present: the chip comes and goes with the selection, and
          // nothing below may move when it does. Sizing to the badge also
          // keeps its rect identical to the list row's, so the hero flight
          // has nothing to interpolate.
          SizedBox(
            height: CurrencyBadge.size,
            child: Row(
              children: [
                // The badge is what flies in from the list row; the app bar
                // already names the currency, so nothing else is repeated.
                Hero(
                  tag: heroTag,
                  child: CurrencyBadge(currency: point.currency),
                ),
                const Spacer(),
                switch (isShowingLatest) {
                  true => const SizedBox.shrink(),
                  false => const _LatestChip(),
                },
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            RateFormatter.rateSentence(
              point.currency.code,
              point.displayRate,
            ),
            style: context.textStyles.headlineSmall,
          ),
          const SizedBox(height: 4),
          _Movement(point: point),
        ],
      ),
    );
  }
}

/// The movement line: change, percentage and the day it belongs to.
class _Movement extends StatelessWidget {
  const _Movement({required this.point});

  final RateHistoryPoint point;

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.bodyMedium?.copyWith(
      color: switch (point.direction) {
        RateDirection.egpWeakening => context.trendColors.weakening,
        RateDirection.egpStrengthening => context.trendColors.strengthening,
        RateDirection.flat => context.colors.onSurfaceVariant,
      },
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      label: RateSemantics.describe(point),
      excludeSemantics: true,
      child: Row(
        children: [
          Text(_changeText(point), style: style),
          const SizedBox(width: 6),
          Text(_percentText(point), style: style),
          const SizedBox(width: 8),
          Text(
            RateFormatter.rateDate(point.date),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns to the most recent day.
class _LatestChip extends StatelessWidget {
  const _LatestChip();

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: const Text('Latest'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () =>
          context.read<CurrencyDetailBloc>().add(const HistoryPointCleared()),
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

/// An em-dash keeps the slot — and the layout — when there is no movement to
/// report.
const String _noValue = '—';

String _changeText(RateHistoryPoint point) => switch (point.change) {
  null => _noValue,
  final change => RateFormatter.signedChange(change),
};

String _percentText(RateHistoryPoint point) => switch (point.percentChange) {
  null => _noValue,
  final percent => RateFormatter.signedPercent(percent),
};

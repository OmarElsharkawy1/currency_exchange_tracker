import 'package:currency_exchange_tracker/core/navigation/app_routes.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rate_comparison.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_bloc.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_state.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/last_updated_banner.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rate_row.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rates_empty_view.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rates_error_view.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rates_loading_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The rates list screen: five currencies against the Egyptian pound.
class RatesListPage extends StatelessWidget {
  /// Creates the screen.
  const RatesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exchange rates')),
      body: BlocBuilder<RatesListBloc, RatesListState>(
        builder: (context, state) => switch (state) {
          RatesLoadInProgress() => const RatesLoadingList(),
          RatesLoadSuccess() => _LoadedRates(state: state),
          RatesLoadEmpty() => RatesEmptyView(onRetry: () => _refresh(context)),
          RatesLoadFailure() => RatesErrorView(
            failure: state.failure,
            onRetry: () => _refresh(context),
          ),
        },
      ),
    );
  }
}

/// The rates themselves, with their freshness banner and pull-to-refresh.
class _LoadedRates extends StatelessWidget {
  const _LoadedRates({required this.state});

  final RatesLoadSuccess state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LastUpdatedBanner(
          lastUpdated: state.lastUpdated,
          isFromCache: state.isFromCache,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(context),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.rates.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => InkWell(
                onTap: () => _openDetail(context, state.rates[index]),
                child: RateRow(comparison: state.rates[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _refresh(BuildContext context) =>
    context.read<RatesListBloc>().add(const RatesRefreshed());

void _openDetail(BuildContext context, RateComparison comparison) =>
    Navigator.of(context).pushNamed(
      AppRoutes.currencyDetail,
      arguments: comparison,
    );

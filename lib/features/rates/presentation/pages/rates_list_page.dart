import 'package:currency_exchange_tracker/core/connectivity/connectivity_cubit.dart';
import 'package:currency_exchange_tracker/core/connectivity/connectivity_state.dart';
import 'package:currency_exchange_tracker/core/failures/failure.dart';
import 'package:currency_exchange_tracker/core/failures/failure_messages.dart';
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
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rates_offline_view.dart';
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
      body: MultiBlocListener(
        listeners: [
          BlocListener<RatesListBloc, RatesListState>(
            // Only the moment a refresh starts failing is news; a failure
            // that merely persists across rebuilds is not.
            listenWhen: (previous, current) => switch ((previous, current)) {
              (
                RatesLoadSuccess(refreshFailure: null),
                RatesLoadSuccess(refreshFailure: final Failure _),
              ) =>
                true,
              _ => false,
            },
            listener: _showRefreshFailure,
          ),
          BlocListener<ConnectivityCubit, ConnectivityState>(
            // An unresolved verdict is not news; only Online/Offline reach
            // the bloc, which turns the transition into exactly one refresh.
            listenWhen: (previous, current) => switch (current) {
              ConnectivityUnknown() => false,
              _ => true,
            },
            listener: (context, state) => context.read<RatesListBloc>().add(
              RatesConnectivityChanged(isOnline: state is ConnectivityOnline),
            ),
          ),
        ],
        child: BlocBuilder<RatesListBloc, RatesListState>(
          builder: (context, state) => switch (state) {
            RatesLoadInProgress() => const RatesLoadingList(),
            RatesLoadSuccess() => _LoadedRates(state: state),
            RatesLoadEmpty() => RatesEmptyView(
              onRetry: () => _refresh(context),
            ),
            RatesUnavailableOffline() => RatesOfflineView(
              onRetry: () => _refresh(context),
            ),
            RatesLoadFailure() => RatesErrorView(
              failure: state.failure,
              onRetry: () => _refresh(context),
            ),
          },
        ),
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
          isOffline:
              context.watch<ConnectivityCubit>().state is ConnectivityOffline,
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

/// Reports a refresh that failed over rates the user can still see.
///
/// The copy is the same `Failure` mapping the error screen uses; there is one
/// place failures become English.
void _showRefreshFailure(BuildContext context, RatesListState state) {
  final failure = switch (state) {
    RatesLoadSuccess(:final refreshFailure?) => refreshFailure,
    _ => null,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(failure!.userMessage)));
}

void _refresh(BuildContext context) =>
    context.read<RatesListBloc>().add(const RatesRefreshed());

void _openDetail(BuildContext context, RateComparison comparison) =>
    Navigator.of(context).pushNamed(
      AppRoutes.currencyDetail,
      arguments: comparison,
    );

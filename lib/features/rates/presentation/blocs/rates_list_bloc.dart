import 'package:currency_exchange_tracker/core/failures/failures.dart';
import 'package:currency_exchange_tracker/features/rates/domain/entities/rates_snapshot.dart';
import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/rates_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the rates list screen.
///
/// State transitions only: no arithmetic, no formatting, no clock, no colors.
/// Everything it emits was computed by the domain or the repository.
class RatesListBloc extends Bloc<RatesListEvent, RatesListState> {
  /// Creates the bloc on [repository].
  RatesListBloc({required RatesRepository repository})
    : _repository = repository,
      super(const RatesLoadInProgress()) {
    on<RatesRequested>(_onRatesRequested);
    on<RatesRefreshed>(_onRatesRefreshed);
    on<RatesConnectivityChanged>(_onConnectivityChanged);
  }

  final RatesRepository _repository;

  /// Last connectivity verdict seen. Optimistic until told otherwise, so a
  /// cold start never mislabels a real failure as "offline".
  bool _isOnline = true;

  Future<void> _onRatesRequested(
    RatesRequested event,
    Emitter<RatesListState> emit,
  ) async {
    emit(const RatesLoadInProgress());
    final (snapshot, failure) = await _repository.getLatestRates();
    emit(_stateFor(snapshot, failure));
  }

  Future<void> _onConnectivityChanged(
    RatesConnectivityChanged event,
    Emitter<RatesListState> emit,
  ) async {
    final hasReconnected = !_isOnline && event.isOnline;
    _isOnline = event.isOnline;

    // Exactly one refresh per reconnect: the transition fires it, not the
    // reading, so a flapping radio cannot stampede the network.
    if (hasReconnected) await _refresh(emit);
  }

  Future<void> _onRatesRefreshed(
    RatesRefreshed event,
    Emitter<RatesListState> emit,
  ) => _refresh(emit);

  Future<void> _refresh(Emitter<RatesListState> emit) async {
    // Rates already on screen stay there: a pull-to-refresh has its own
    // indicator, and replacing the list with skeletons would fight it.
    final ratesOnScreen = state is RatesLoadSuccess;
    if (!ratesOnScreen) emit(const RatesLoadInProgress());

    final (snapshot, failure) = await _repository.getLatestRates(
      forceRefresh: true,
    );

    // A failed refresh over live rates keeps the live rates and reports the
    // failure alongside them: the repository already falls back to the cache,
    // so there is nothing better to show, but the user still gets told.
    final loaded = state;
    if (snapshot == null && loaded is RatesLoadSuccess) {
      emit(
        RatesLoadSuccess(
          rates: loaded.rates,
          lastUpdated: loaded.lastUpdated,
          isFromCache: loaded.isFromCache,
          refreshFailure: failure,
        ),
      );
      return;
    }

    emit(_stateFor(snapshot, failure));
  }

  RatesListState _stateFor(RatesSnapshot? snapshot, Failure? failure) {
    if (snapshot == null) {
      // Offline with an empty cache is not an error to apologise for.
      return switch (_isOnline) {
        false => const RatesUnavailableOffline(),
        true => RatesLoadFailure(failure: failure!),
      };
    }
    if (snapshot.rates.isEmpty) return const RatesLoadEmpty();
    return RatesLoadSuccess(
      rates: snapshot.rates,
      lastUpdated: snapshot.fetchedAt,
      isFromCache: snapshot.isFromCache,
    );
  }
}

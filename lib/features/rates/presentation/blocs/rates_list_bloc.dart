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
  }

  final RatesRepository _repository;

  Future<void> _onRatesRequested(
    RatesRequested event,
    Emitter<RatesListState> emit,
  ) async {
    emit(const RatesLoadInProgress());
    final (snapshot, failure) = await _repository.getLatestRates();
    emit(_stateFor(snapshot, failure));
  }

  Future<void> _onRatesRefreshed(
    RatesRefreshed event,
    Emitter<RatesListState> emit,
  ) async {
    // Rates already on screen stay there: a pull-to-refresh has its own
    // indicator, and replacing the list with skeletons would fight it.
    final ratesOnScreen = state is RatesLoadSuccess;
    if (!ratesOnScreen) emit(const RatesLoadInProgress());

    final (snapshot, failure) = await _repository.getLatestRates(
      forceRefresh: true,
    );

    // A failed refresh over live rates keeps the live rates; the repository
    // already falls back to the cache, so a failure here means there is
    // nothing better to show.
    if (snapshot == null && ratesOnScreen) return;

    emit(_stateFor(snapshot, failure));
  }

  RatesListState _stateFor(RatesSnapshot? snapshot, Failure? failure) {
    if (snapshot == null) return RatesLoadFailure(failure: failure!);
    if (snapshot.rates.isEmpty) return const RatesLoadEmpty();
    return RatesLoadSuccess(
      rates: snapshot.rates,
      lastUpdated: snapshot.fetchedAt,
      isFromCache: snapshot.isFromCache,
    );
  }
}

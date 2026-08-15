import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the detail screen's chart.
///
/// It fetches the history and nothing else: the current rate came through the
/// route with the entity, so this bloc never refetches it and never puts the
/// header into a loading state.
class CurrencyDetailBloc
    extends Bloc<CurrencyDetailEvent, CurrencyDetailState> {
  /// Creates the bloc on [repository].
  CurrencyDetailBloc({required RatesRepository repository})
    : _repository = repository,
      super(const HistoryLoadInProgress()) {
    on<HistoryRequested>(_onHistoryRequested);
  }

  final RatesRepository _repository;

  /// Fewer points than this cannot be drawn as a line.
  static const int _minimumPlottablePoints = 2;

  Future<void> _onHistoryRequested(
    HistoryRequested event,
    Emitter<CurrencyDetailState> emit,
  ) async {
    emit(const HistoryLoadInProgress());

    // The window is the repository contract's default: one source of truth
    // for "seven days".
    final (points, failure) = await _repository.getHistory(event.currency);

    if (points == null) {
      emit(HistoryLoadFailure(failure: failure!));
      return;
    }
    if (points.length < _minimumPlottablePoints) {
      emit(const HistoryLoadEmpty());
      return;
    }
    emit(HistoryLoadSuccess(points: points));
  }
}

import 'package:currency_exchange_tracker/features/rates/domain/repositories/rates_repository.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_event.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/blocs/currency_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the detail screen's chart and which day it is reading out.
///
/// It fetches the history and tracks a selection index; the current rate came
/// through the route, so this bloc never refetches it and never puts the
/// header into a loading state. Indices in, points out — no arithmetic.
class CurrencyDetailBloc
    extends Bloc<CurrencyDetailEvent, CurrencyDetailState> {
  /// Creates the bloc on [repository].
  CurrencyDetailBloc({required RatesRepository repository})
    : _repository = repository,
      super(const HistoryLoadInProgress()) {
    on<HistoryRequested>(_onHistoryRequested);
    on<HistoryPointSelected>(_onPointSelected);
    on<HistoryPointCleared>(_onPointCleared);
    on<HistoryScrubbed>(_onScrubbed);
    on<HistoryScrubEnded>(_onScrubEnded);
  }

  final RatesRepository _repository;

  /// Fewer points than this cannot be drawn as a line.
  static const int _minimumPlottablePoints = 2;

  /// The selection a tap pinned, which a scrub borrows and then gives back.
  ///
  /// Kept beside the state rather than inside it: it is not what the screen
  /// is showing, it is what the screen returns to when the finger lifts.
  int? _pinnedIndex;

  Future<void> _onHistoryRequested(
    HistoryRequested event,
    Emitter<CurrencyDetailState> emit,
  ) async {
    emit(const HistoryLoadInProgress());
    _pinnedIndex = null;

    // The window is the repository contract's default: one source of truth
    // for "seven days".
    final (history, failure) = await _repository.getHistory(event.currency);

    if (history == null) {
      emit(HistoryLoadFailure(failure: failure!));
      return;
    }
    if (history.length < _minimumPlottablePoints) {
      emit(const HistoryLoadEmpty());
      return;
    }
    emit(HistoryLoadSuccess(history: history));
  }

  void _onPointSelected(
    HistoryPointSelected event,
    Emitter<CurrencyDetailState> emit,
  ) {
    final loaded = state;
    if (loaded is! HistoryLoadSuccess) return;
    if (loaded.history.pointAt(event.index) == null) return;

    _pinnedIndex = event.index;
    emit(
      HistoryLoadSuccess(
        history: loaded.history,
        selectedIndex: event.index,
      ),
    );
  }

  void _onPointCleared(
    HistoryPointCleared event,
    Emitter<CurrencyDetailState> emit,
  ) {
    final loaded = state;
    if (loaded is! HistoryLoadSuccess) return;

    _pinnedIndex = null;
    emit(HistoryLoadSuccess(history: loaded.history));
  }

  void _onScrubbed(HistoryScrubbed event, Emitter<CurrencyDetailState> emit) {
    final loaded = state;
    if (loaded is! HistoryLoadSuccess) return;
    if (loaded.history.pointAt(event.index) == null) return;

    // A scrub does not pin anything; it only moves what is on screen.
    emit(
      HistoryLoadSuccess(
        history: loaded.history,
        selectedIndex: event.index,
      ),
    );
  }

  void _onScrubEnded(
    HistoryScrubEnded event,
    Emitter<CurrencyDetailState> emit,
  ) {
    final loaded = state;
    if (loaded is! HistoryLoadSuccess) return;

    // Back to whatever a tap had pinned, or to the latest if nothing had.
    emit(
      HistoryLoadSuccess(
        history: loaded.history,
        selectedIndex: _pinnedIndex,
      ),
    );
  }
}

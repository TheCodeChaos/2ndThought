import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'schulte_models.dart';
import '../stroop/stroop_models.dart'; // GameStatus, GameResult

class SchulteState {
  final List<SchulteCell> cells;
  final int nextExpected;
  final int elapsedMs;
  final GameStatus status;
  final int? wrongCellIndex;

  const SchulteState({
    this.cells = const [],
    this.nextExpected = 1,
    this.elapsedMs = 0,
    this.status = GameStatus.idle,
    this.wrongCellIndex,
  });

  SchulteState copyWith({
    List<SchulteCell>? cells,
    int? nextExpected,
    int? elapsedMs,
    GameStatus? status,
    int? wrongCellIndex,
    bool clearWrong = false,
  }) {
    return SchulteState(
      cells: cells ?? this.cells,
      nextExpected: nextExpected ?? this.nextExpected,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      status: status ?? this.status,
      wrongCellIndex: clearWrong
          ? null
          : (wrongCellIndex ?? this.wrongCellIndex),
    );
  }
}

class SchulteController extends StateNotifier<SchulteState> {
  final Stopwatch _stopwatch = Stopwatch();
  static const _timeLimitMs = 60000;

  SchulteController() : super(const SchulteState()) {
    _generateGrid();
  }

  void _generateGrid() {
    final numbers = List.generate(25, (i) => i + 1);
    numbers.shuffle(Random());

    final cells = <SchulteCell>[];
    for (int i = 0; i < 25; i++) {
      cells.add(SchulteCell(number: numbers[i], gridIndex: i));
    }

    state = state.copyWith(cells: cells);
  }

  void start() {
    _stopwatch.start();
    state = state.copyWith(status: GameStatus.running);
  }

  void onCellTap(int number) {
    if (state.status != GameStatus.running) return;

    final elapsed = _stopwatch.elapsedMilliseconds;

    if (elapsed > _timeLimitMs) {
      _stopwatch.stop();
      state = state.copyWith(status: GameStatus.failure, elapsedMs: elapsed);
      return;
    }

    if (number == state.nextExpected) {
      final newCells = state.cells.map((cell) {
        if (cell.number == number) {
          return cell.copyWith(tapped: true);
        }
        return cell;
      }).toList();

      final newNext = state.nextExpected + 1;

      if (newNext > 25 && elapsed <= _timeLimitMs) {
        _stopwatch.stop();
        state = state.copyWith(
          cells: newCells,
          nextExpected: newNext,
          elapsedMs: elapsed,
          status: GameStatus.success,
        );
      } else {
        state = state.copyWith(
          cells: newCells,
          nextExpected: newNext,
          elapsedMs: elapsed,
        );
      }
    } else {
      // Wrong tap — flash
      final wrongIndex = state.cells.indexWhere(
        (cell) => cell.number == number,
      );
      state = state.copyWith(wrongCellIndex: wrongIndex);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          state = state.copyWith(clearWrong: true);
        }
      });
    }
  }

  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }
}

final schulteControllerProvider =
    StateNotifierProvider.autoDispose<SchulteController, SchulteState>((ref) {
      return SchulteController();
    });

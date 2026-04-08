import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stroop_models.dart';

class StroopState {
  final List<StroopRound> rounds;
  final int currentIndex;
  final int correctCount;
  final int elapsedMs;
  final GameStatus status;

  const StroopState({
    this.rounds = const [],
    this.currentIndex = 0,
    this.correctCount = 0,
    this.elapsedMs = 0,
    this.status = GameStatus.idle,
  });

  StroopState copyWith({
    List<StroopRound>? rounds,
    int? currentIndex,
    int? correctCount,
    int? elapsedMs,
    GameStatus? status,
  }) {
    return StroopState(
      rounds: rounds ?? this.rounds,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      status: status ?? this.status,
    );
  }

  StroopRound? get currentRound =>
      currentIndex < rounds.length ? rounds[currentIndex] : null;
}

class StroopController extends StateNotifier<StroopState> {
  final Stopwatch _stopwatch = Stopwatch();
  final Random _random = Random();

  StroopController() : super(const StroopState()) {
    _generateRounds();
  }

  void _generateRounds() {
    final rounds = <StroopRound>[];
    const colors = StroopColor.values;

    for (int i = 0; i < 25; i++) {
      final wordColor = colors[_random.nextInt(colors.length)];
      StroopColor inkColor;
      do {
        inkColor = colors[_random.nextInt(colors.length)];
      } while (inkColor == wordColor);

      rounds.add(StroopRound(
        word: wordColor.label,
        inkColor: inkColor,
        wordColor: wordColor,
      ));
    }

    state = state.copyWith(rounds: rounds);
  }

  void start() {
    _stopwatch.start();
    state = state.copyWith(status: GameStatus.running);
  }

  void onTap(StroopColor tapped) {
    if (state.status != GameStatus.running) return;

    final elapsed = _stopwatch.elapsedMilliseconds;

    if (elapsed > 20000) {
      _stopwatch.stop();
      state = state.copyWith(
        status: GameStatus.failure,
        elapsedMs: elapsed,
      );
      return;
    }

    final currentRound = state.currentRound;
    if (currentRound == null) return;

    if (tapped == currentRound.inkColor) {
      final newCorrect = state.correctCount + 1;
      final newIndex = state.currentIndex + 1;

      if (newCorrect >= 15 && elapsed <= 20000) {
        _stopwatch.stop();
        state = state.copyWith(
          correctCount: newCorrect,
          currentIndex: newIndex,
          elapsedMs: elapsed,
          status: GameStatus.success,
        );
      } else {
        state = state.copyWith(
          correctCount: newCorrect,
          currentIndex: newIndex,
          elapsedMs: elapsed,
        );
      }
    } else {
      _stopwatch.stop();
      state = state.copyWith(
        status: GameStatus.failure,
        elapsedMs: elapsed,
      );
    }
  }

  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }
}

final stroopControllerProvider =
    StateNotifierProvider.autoDispose<StroopController, StroopState>((ref) {
  return StroopController();
});

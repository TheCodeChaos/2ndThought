import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mental_math_models.dart';
import '../stroop/stroop_models.dart'; // GameStatus, GameResult

class MentalMathState {
  final MathQuestion? currentQuestion;
  final int consecutiveCorrect;
  final GameStatus status;
  final String userInput;
  final bool lastWasWrong;

  const MentalMathState({
    this.currentQuestion,
    this.consecutiveCorrect = 0,
    this.status = GameStatus.idle,
    this.userInput = '',
    this.lastWasWrong = false,
  });

  MentalMathState copyWith({
    MathQuestion? currentQuestion,
    int? consecutiveCorrect,
    GameStatus? status,
    String? userInput,
    bool? lastWasWrong,
  }) {
    return MentalMathState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      status: status ?? this.status,
      userInput: userInput ?? this.userInput,
      lastWasWrong: lastWasWrong ?? this.lastWasWrong,
    );
  }
}

class MentalMathController extends StateNotifier<MentalMathState> {
  final Random _random = Random();

  MentalMathController() : super(const MentalMathState()) {
    _generateQuestion();
  }

  MathQuestion _createQuestion() {
    final op = MathOp.values[_random.nextInt(MathOp.values.length)];
    int a, b;

    switch (op) {
      case MathOp.add:
        a = 10 + _random.nextInt(90); // [10, 99]
        b = 10 + _random.nextInt(90);
        break;
      case MathOp.subtract:
        a = 20 + _random.nextInt(80); // [20, 99]
        b = 10 + _random.nextInt(max(1, a - 14)); // [10, a-5]
        if (b > a - 5) b = a - 5;
        if (b < 10) b = 10;
        break;
      case MathOp.multiply:
        a = 2 + _random.nextInt(11); // [2, 12]
        b = 2 + _random.nextInt(11);
        break;
    }

    return MathQuestion(a: a, b: b, op: op);
  }

  void _generateQuestion() {
    final question = _createQuestion();
    state = state.copyWith(
      currentQuestion: question,
      userInput: '',
      lastWasWrong: false,
    );
  }

  void start() {
    state = state.copyWith(status: GameStatus.running);
    _generateQuestion();
  }

  void onDigitTap(String digit) {
    if (state.status != GameStatus.running) return;
    if (state.userInput.length >= 6) return; // prevent overflow
    
    // Handle negative sign
    if (digit == '-' && state.userInput.isEmpty) {
      state = state.copyWith(userInput: '-');
      return;
    }

    state = state.copyWith(userInput: state.userInput + digit);
  }

  void onBackspace() {
    if (state.status != GameStatus.running) return;
    if (state.userInput.isEmpty) return;
    state = state.copyWith(
      userInput: state.userInput.substring(0, state.userInput.length - 1),
    );
  }

  void onSubmit() {
    if (state.status != GameStatus.running) return;
    if (state.userInput.isEmpty) return;

    final parsed = int.tryParse(state.userInput);
    if (parsed == null) {
      state = state.copyWith(userInput: '');
      return;
    }

    if (parsed == state.currentQuestion?.correctAnswer) {
      final newStreak = state.consecutiveCorrect + 1;
      if (newStreak >= 5) {
        state = state.copyWith(
          consecutiveCorrect: newStreak,
          status: GameStatus.success,
        );
      } else {
        state = state.copyWith(
          consecutiveCorrect: newStreak,
          lastWasWrong: false,
        );
        _generateQuestion();
      }
    } else {
      state = state.copyWith(
        consecutiveCorrect: 0,
        lastWasWrong: true,
      );
      _generateQuestion();
    }
  }
}

final mentalMathControllerProvider =
    StateNotifierProvider.autoDispose<MentalMathController, MentalMathState>(
        (ref) {
  return MentalMathController();
});

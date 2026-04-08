import 'package:flutter_test/flutter_test.dart';
import 'package:neurogate/features/games/mental_math/mental_math_controller.dart';
import 'package:neurogate/features/games/stroop/stroop_models.dart';

void main() {
  group('MentalMathController', () {
    late MentalMathController controller;

    setUp(() {
      controller = MentalMathController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('generates a question on init', () {
      expect(controller.state.currentQuestion, isNotNull);
    });

    test('starts in idle state', () {
      expect(controller.state.status, GameStatus.idle);
    });

    test('digit input appends to userInput', () {
      controller.start();
      controller.onDigitTap('5');
      expect(controller.state.userInput, '5');
      controller.onDigitTap('3');
      expect(controller.state.userInput, '53');
    });

    test('backspace removes last character', () {
      controller.start();
      controller.onDigitTap('1');
      controller.onDigitTap('2');
      controller.onBackspace();
      expect(controller.state.userInput, '1');
    });

    test('correct answer increments streak', () {
      controller.start();
      final answer = controller.state.currentQuestion!.correctAnswer;
      for (final digit in answer.toString().split('')) {
        controller.onDigitTap(digit);
      }
      controller.onSubmit();
      expect(controller.state.consecutiveCorrect, 1);
    });

    test('wrong answer resets streak to 0', () {
      controller.start();
      // Answer correctly once
      final answer1 = controller.state.currentQuestion!.correctAnswer;
      for (final digit in answer1.toString().split('')) {
        controller.onDigitTap(digit);
      }
      controller.onSubmit();
      expect(controller.state.consecutiveCorrect, 1);

      // Now answer wrong
      controller.onDigitTap('0');
      controller.onSubmit();
      expect(controller.state.consecutiveCorrect, 0);
    });

    test('5 consecutive correct answers sets success', () {
      controller.start();
      for (int i = 0; i < 5; i++) {
        final answer = controller.state.currentQuestion!.correctAnswer;
        for (final digit in answer.toString().split('')) {
          controller.onDigitTap(digit);
        }
        controller.onSubmit();
      }
      expect(controller.state.status, GameStatus.success);
    });

    test('input is cleared after submit', () {
      controller.start();
      controller.onDigitTap('9');
      controller.onDigitTap('9');
      controller.onDigitTap('9');
      controller.onSubmit();
      expect(controller.state.userInput, '');
    });
  });
}

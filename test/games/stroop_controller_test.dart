import 'package:flutter_test/flutter_test.dart';
import 'package:neurogate/features/games/stroop/stroop_controller.dart';
import 'package:neurogate/features/games/stroop/stroop_models.dart';

void main() {
  group('StroopController', () {
    late StroopController controller;

    setUp(() {
      controller = StroopController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('generates 25 rounds on init', () {
      expect(controller.state.rounds.length, 25);
    });

    test('all rounds have mismatched ink and word colors', () {
      for (final round in controller.state.rounds) {
        expect(round.inkColor, isNot(equals(round.wordColor)));
      }
    });

    test('starts in idle state', () {
      expect(controller.state.status, GameStatus.idle);
    });

    test('transitions to running on start', () {
      controller.start();
      expect(controller.state.status, GameStatus.running);
    });

    test('correct tap increments correctCount', () {
      controller.start();
      final firstRound = controller.state.currentRound!;
      controller.onTap(firstRound.inkColor);
      expect(controller.state.correctCount, 1);
      expect(controller.state.currentIndex, 1);
    });

    test('wrong tap sets status to failure', () {
      controller.start();
      final firstRound = controller.state.currentRound!;
      // Find a wrong color
      final wrongColor = StroopColor.values
          .firstWhere((c) => c != firstRound.inkColor);
      controller.onTap(wrongColor);
      expect(controller.state.status, GameStatus.failure);
    });

    test('15 correct answers within time sets success', () {
      controller.start();
      // Simulate 15 correct answers quickly
      for (int i = 0; i < 15; i++) {
        final round = controller.state.currentRound;
        if (round != null && controller.state.status == GameStatus.running) {
          controller.onTap(round.inkColor);
        }
      }
      expect(controller.state.status, GameStatus.success);
    });

    test('taps are ignored when not running', () {
      final firstRound = controller.state.currentRound!;
      controller.onTap(firstRound.inkColor);
      expect(controller.state.correctCount, 0);
    });
  });
}

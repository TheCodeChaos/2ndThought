import 'package:flutter_test/flutter_test.dart';
import 'package:neurogate/features/games/schulte/schulte_controller.dart';
import 'package:neurogate/features/games/stroop/stroop_models.dart';

void main() {
  group('SchulteController', () {
    late SchulteController controller;

    setUp(() {
      controller = SchulteController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('generates 25 cells on init', () {
      expect(controller.state.cells.length, 25);
    });

    test('cells contain numbers 1-25', () {
      final numbers = controller.state.cells
          .map((c) => c.number)
          .toSet();
      expect(numbers, containsAll(List.generate(25, (i) => i + 1)));
    });

    test('starts expecting 1', () {
      expect(controller.state.nextExpected, 1);
    });

    test('correct tap advances nextExpected', () {
      controller.start();
      controller.onCellTap(1);
      expect(controller.state.nextExpected, 2);
    });

    test('wrong tap does not advance nextExpected', () {
      controller.start();
      controller.onCellTap(5); // Wrong - expected 1
      expect(controller.state.nextExpected, 1);
    });

    test('sequential taps complete the board', () {
      controller.start();
      for (int i = 1; i <= 25; i++) {
        controller.onCellTap(i);
      }
      expect(controller.state.status, GameStatus.success);
    });

    test('tapped cells are marked', () {
      controller.start();
      controller.onCellTap(1);
      final cell1 = controller.state.cells
          .firstWhere((c) => c.number == 1);
      expect(cell1.tapped, isTrue);
    });
  });
}

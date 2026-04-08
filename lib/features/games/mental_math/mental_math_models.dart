enum MathOp { add, subtract, multiply }

class MathQuestion {
  final int a;
  final int b;
  final MathOp op;

  const MathQuestion({required this.a, required this.b, required this.op});

  int get correctAnswer {
    switch (op) {
      case MathOp.add:
        return a + b;
      case MathOp.subtract:
        return a - b;
      case MathOp.multiply:
        return a * b;
    }
  }

  String get displayString {
    String opSymbol;
    switch (op) {
      case MathOp.add:
        opSymbol = '+';
        break;
      case MathOp.subtract:
        opSymbol = '−';
        break;
      case MathOp.multiply:
        opSymbol = '×';
        break;
    }
    return '$a $opSymbol $b = ?';
  }
}

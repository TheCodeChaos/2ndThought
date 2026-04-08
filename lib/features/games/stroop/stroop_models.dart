import 'package:flutter/material.dart';

enum StroopColor { red, green, blue, yellow }

extension StroopColorExtension on StroopColor {
  Color get flutterColor {
    switch (this) {
      case StroopColor.red:
        return const Color(0xFFFF1744);
      case StroopColor.green:
        return const Color(0xFF00E676);
      case StroopColor.blue:
        return const Color(0xFF448AFF);
      case StroopColor.yellow:
        return const Color(0xFFFFD600);
    }
  }

  String get label {
    switch (this) {
      case StroopColor.red:
        return 'RED';
      case StroopColor.green:
        return 'GREEN';
      case StroopColor.blue:
        return 'BLUE';
      case StroopColor.yellow:
        return 'YELLOW';
    }
  }
}

class StroopRound {
  final String word;
  final StroopColor inkColor;
  final StroopColor wordColor;

  const StroopRound({
    required this.word,
    required this.inkColor,
    required this.wordColor,
  });
}

enum GameStatus { idle, running, success, failure }

enum GameResult { success, failure }

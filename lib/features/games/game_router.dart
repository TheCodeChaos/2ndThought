import 'dart:math';
import 'package:flutter/material.dart';
import 'stroop/stroop_models.dart';
import 'stroop/stroop_screen.dart';
import 'schulte/schulte_screen.dart';
import 'mental_math/mental_math_screen.dart';

enum GameType { stroop, schulte, mentalMath }

extension GameTypeExtension on GameType {
  String get displayName {
    switch (this) {
      case GameType.stroop:
        return 'Stroop Effect';
      case GameType.schulte:
        return 'Schulte Table';
      case GameType.mentalMath:
        return 'Mental Math';
    }
  }

  String get dbKey {
    switch (this) {
      case GameType.stroop:
        return 'stroop';
      case GameType.schulte:
        return 'schulte';
      case GameType.mentalMath:
        return 'mental_math';
    }
  }

  IconData get icon {
    switch (this) {
      case GameType.stroop:
        return Icons.palette;
      case GameType.schulte:
        return Icons.grid_on;
      case GameType.mentalMath:
        return Icons.calculate;
    }
  }

  int get successPoints {
    switch (this) {
      case GameType.stroop:
        return 30;
      case GameType.schulte:
        return 25;
      case GameType.mentalMath:
        return 20;
    }
  }

  int get rewardMinutes {
    switch (this) {
      case GameType.stroop:
        return 8;
      case GameType.schulte:
        return 10;
      case GameType.mentalMath:
        return 6;
    }
  }

  static GameType fromDbKey(String key) {
    switch (key) {
      case 'stroop':
        return GameType.stroop;
      case 'schulte':
        return GameType.schulte;
      case 'mental_math':
        return GameType.mentalMath;
      default:
        return GameType.stroop;
    }
  }
}

class GameRouterService {
  static final _random = Random();

  static GameType selectRandom() {
    return GameType.values[_random.nextInt(GameType.values.length)];
  }

  static Widget buildGame(
    GameType type, {
    Key? key,
    required void Function(GameResult) onResult,
  }) {
    switch (type) {
      case GameType.stroop:
        return StroopScreen(key: key, onResult: onResult);
      case GameType.schulte:
        return SchulteScreen(key: key, onResult: onResult);
      case GameType.mentalMath:
        return MentalMathScreen(key: key, onResult: onResult);
    }
  }
}

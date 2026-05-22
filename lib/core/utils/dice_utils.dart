import 'dart:math';

import '../constants/game_constants.dart';

class DiceUtils {
  static final Random _random = Random();

  static int roll() {
    return _random.nextInt(GameConstants.maxDice) + GameConstants.minDice;
  }
}

class GameConstants {
  static const int minPlayers = 2;
  static const int maxPlayers = 4;
  static const int pawnsPerPlayer = 4;

  static const int minDice = 1;
  static const int maxDice = 6;

  // 0 = base, 1..51 = piste principale, 52..56 = couloir final, 57 = centre.
  static const int initialSteps = 0;
  static const int trackStartSteps = 1;
  static const int trackEndSteps = 51;
  static const int homeLaneStartSteps = 52;
  static const int homeLaneEndSteps = 56;
  static const int finishedSteps = 57;

  static const int defaultPort = 4545;
}

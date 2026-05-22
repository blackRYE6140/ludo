import 'package:flutter/material.dart';

import '../../models/player.dart';

@immutable
class GridPosition {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  Offset toOffset(double cellSize) {
    return Offset(col * cellSize, row * cellSize);
  }
}

class BoardConstants {
  static const int boardSize = 15;

  static const List<GridPosition> track = <GridPosition>[
    GridPosition(6, 1),
    GridPosition(6, 2),
    GridPosition(6, 3),
    GridPosition(6, 4),
    GridPosition(6, 5),
    GridPosition(5, 6),
    GridPosition(4, 6),
    GridPosition(3, 6),
    GridPosition(2, 6),
    GridPosition(1, 6),
    GridPosition(0, 6),
    GridPosition(0, 7),
    GridPosition(0, 8),
    GridPosition(1, 8),
    GridPosition(2, 8),
    GridPosition(3, 8),
    GridPosition(4, 8),
    GridPosition(5, 8),
    GridPosition(6, 9),
    GridPosition(6, 10),
    GridPosition(6, 11),
    GridPosition(6, 12),
    GridPosition(6, 13),
    GridPosition(6, 14),
    GridPosition(7, 14),
    GridPosition(8, 14),
    GridPosition(8, 13),
    GridPosition(8, 12),
    GridPosition(8, 11),
    GridPosition(8, 10),
    GridPosition(8, 9),
    GridPosition(9, 8),
    GridPosition(10, 8),
    GridPosition(11, 8),
    GridPosition(12, 8),
    GridPosition(13, 8),
    GridPosition(14, 8),
    GridPosition(14, 7),
    GridPosition(14, 6),
    GridPosition(13, 6),
    GridPosition(12, 6),
    GridPosition(11, 6),
    GridPosition(10, 6),
    GridPosition(9, 6),
    GridPosition(8, 5),
    GridPosition(8, 4),
    GridPosition(8, 3),
    GridPosition(8, 2),
    GridPosition(8, 1),
    GridPosition(8, 0),
    GridPosition(7, 0),
    GridPosition(6, 0),
  ];

  // Cases protégées = 4 départs + 4 étoiles.
  static const Set<int> safeTrackIndices = <int>{0, 13, 26, 39, 8, 21, 34, 47};

  static const Map<PlayerColor, List<GridPosition>> homeLanes =
      <PlayerColor, List<GridPosition>>{
    PlayerColor.red: <GridPosition>[
      GridPosition(7, 1),
      GridPosition(7, 2),
      GridPosition(7, 3),
      GridPosition(7, 4),
      GridPosition(7, 5),
    ],
    PlayerColor.green: <GridPosition>[
      GridPosition(1, 7),
      GridPosition(2, 7),
      GridPosition(3, 7),
      GridPosition(4, 7),
      GridPosition(5, 7),
    ],
    PlayerColor.yellow: <GridPosition>[
      GridPosition(7, 13),
      GridPosition(7, 12),
      GridPosition(7, 11),
      GridPosition(7, 10),
      GridPosition(7, 9),
    ],
    PlayerColor.blue: <GridPosition>[
      GridPosition(13, 7),
      GridPosition(12, 7),
      GridPosition(11, 7),
      GridPosition(10, 7),
      GridPosition(9, 7),
    ],
  };

  static const GridPosition center = GridPosition(7, 7);

  static const Map<PlayerColor, List<GridPosition>> yardPositions =
      <PlayerColor, List<GridPosition>>{
    PlayerColor.red: <GridPosition>[
      GridPosition(2, 2),
      GridPosition(2, 4),
      GridPosition(4, 2),
      GridPosition(4, 4),
    ],
    PlayerColor.green: <GridPosition>[
      GridPosition(2, 10),
      GridPosition(2, 12),
      GridPosition(4, 10),
      GridPosition(4, 12),
    ],
    PlayerColor.yellow: <GridPosition>[
      GridPosition(10, 10),
      GridPosition(10, 12),
      GridPosition(12, 10),
      GridPosition(12, 12),
    ],
    PlayerColor.blue: <GridPosition>[
      GridPosition(10, 2),
      GridPosition(10, 4),
      GridPosition(12, 2),
      GridPosition(12, 4),
    ],
  };
}

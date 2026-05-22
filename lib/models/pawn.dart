import 'package:flutter/foundation.dart';

import '../core/constants/game_constants.dart';
import 'player.dart';

@immutable
class Pawn {
  final String id;
  final PlayerColor color;
  final int steps;

  const Pawn({
    required this.id,
    required this.color,
    required this.steps,
  });

  bool get isInYard => steps == GameConstants.initialSteps;

  bool get isOnTrack =>
      steps >= GameConstants.trackStartSteps && steps <= GameConstants.trackEndSteps;

  bool get isInHomeLane =>
      steps >= GameConstants.homeLaneStartSteps && steps <= GameConstants.homeLaneEndSteps;

  bool get isFinished => steps == GameConstants.finishedSteps;

  Pawn copyWith({
    int? steps,
  }) {
    return Pawn(
      id: id,
      color: color,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'color': color.code,
      'steps': steps,
    };
  }

  factory Pawn.fromJson(Map<String, dynamic> json) {
    return Pawn(
      id: (json['id'] ?? '') as String,
      color: PlayerColorX.fromCode((json['color'] ?? 'red') as String),
      steps: (json['steps'] ?? 0) as int,
    );
  }
}

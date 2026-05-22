import 'package:flutter/foundation.dart';

import 'player.dart';

enum GameMode { local, wifiHost, wifiClient }

enum GameStatus { lobby, inProgress, finished }

@immutable
class GameState {
  final GameMode mode;
  final GameStatus status;
  final List<Player> players;
  final int currentTurnIndex;
  final int? diceValue;
  final bool hasRolled;
  final bool isRolling;
  final List<String> movablePawnIds;
  final PlayerColor? winner;
  final String infoMessage;
  final int turnCount;
  final String? lastMovedPawnId;
  final List<int> lastMovedPathSteps;
  final int moveSerial;

  const GameState({
    required this.mode,
    required this.status,
    required this.players,
    required this.currentTurnIndex,
    required this.diceValue,
    required this.hasRolled,
    required this.isRolling,
    required this.movablePawnIds,
    required this.winner,
    required this.infoMessage,
    required this.turnCount,
    required this.lastMovedPawnId,
    required this.lastMovedPathSteps,
    required this.moveSerial,
  });

  Player get currentPlayer => players[currentTurnIndex];

  bool get isFinished => status == GameStatus.finished;

  bool get canRoll => status == GameStatus.inProgress && !hasRolled && !isRolling;

  GameState copyWith({
    GameMode? mode,
    GameStatus? status,
    List<Player>? players,
    int? currentTurnIndex,
    int? diceValue,
    bool? hasRolled,
    bool? isRolling,
    List<String>? movablePawnIds,
    Object? winner = _unset,
    String? infoMessage,
    int? turnCount,
    Object? lastMovedPawnId = _unset,
    List<int>? lastMovedPathSteps,
    int? moveSerial,
  }) {
    return GameState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      players: players ?? this.players,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      diceValue: diceValue ?? this.diceValue,
      hasRolled: hasRolled ?? this.hasRolled,
      isRolling: isRolling ?? this.isRolling,
      movablePawnIds: movablePawnIds ?? this.movablePawnIds,
      winner: identical(winner, _unset) ? this.winner : winner as PlayerColor?,
      infoMessage: infoMessage ?? this.infoMessage,
      turnCount: turnCount ?? this.turnCount,
      lastMovedPawnId: identical(lastMovedPawnId, _unset)
          ? this.lastMovedPawnId
          : lastMovedPawnId as String?,
      lastMovedPathSteps: lastMovedPathSteps ?? this.lastMovedPathSteps,
      moveSerial: moveSerial ?? this.moveSerial,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode.name,
      'status': status.name,
      'players': players.map((Player player) => player.toJson()).toList(),
      'currentTurnIndex': currentTurnIndex,
      'diceValue': diceValue,
      'hasRolled': hasRolled,
      'isRolling': isRolling,
      'movablePawnIds': movablePawnIds,
      'winner': winner?.name,
      'infoMessage': infoMessage,
      'turnCount': turnCount,
      'lastMovedPawnId': lastMovedPawnId,
      'lastMovedPathSteps': lastMovedPathSteps,
      'moveSerial': moveSerial,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final List<Player> players = ((json['players'] ?? <dynamic>[]) as List<dynamic>)
        .map((dynamic raw) => Player.fromJson(raw as Map<String, dynamic>))
        .toList();

    return GameState(
      mode: GameMode.values.byName((json['mode'] ?? 'local') as String),
      status: GameStatus.values.byName((json['status'] ?? 'lobby') as String),
      players: players,
      currentTurnIndex: (json['currentTurnIndex'] ?? 0) as int,
      diceValue: json['diceValue'] as int?,
      hasRolled: (json['hasRolled'] ?? false) as bool,
      isRolling: (json['isRolling'] ?? false) as bool,
      movablePawnIds:
          ((json['movablePawnIds'] ?? <dynamic>[]) as List<dynamic>).cast<String>(),
      winner: _winnerFromJson(json['winner']),
      infoMessage: (json['infoMessage'] ?? '') as String,
      turnCount: (json['turnCount'] ?? 1) as int,
      lastMovedPawnId: json['lastMovedPawnId'] as String?,
      lastMovedPathSteps: ((json['lastMovedPathSteps'] ?? <dynamic>[]) as List<dynamic>)
          .cast<int>(),
      moveSerial: (json['moveSerial'] ?? 0) as int,
    );
  }

  static PlayerColor? _winnerFromJson(dynamic value) {
    if (value == null) {
      return null;
    }
    return PlayerColor.values.byName(value as String);
  }
}

const Object _unset = Object();

import '../core/constants/board_constants.dart';
import '../core/constants/game_constants.dart';
import '../models/game_state.dart';
import '../models/pawn.dart';
import '../models/player.dart';

class LocalGameService {
  GameState createInitialState({
    required int playerCount,
    required GameMode mode,
    required GameStatus status,
    List<String>? playerNames,
  }) {
    final List<PlayerColor> activeColors;
    if (playerCount == 2) {
      activeColors = <PlayerColor>[PlayerColor.red, PlayerColor.yellow];
    } else if (playerCount == 3) {
      activeColors = <PlayerColor>[PlayerColor.red, PlayerColor.green, PlayerColor.yellow];
    } else {
      activeColors = <PlayerColor>[PlayerColor.red, PlayerColor.green, PlayerColor.yellow, PlayerColor.blue];
    }

    final List<Player> players = <Player>[];
    for (int i = 0; i < activeColors.length; i++) {
      final PlayerColor color = activeColors[i];
      final String fallbackName = 'Joueur ${i + 1}';
      final String name = playerNames != null && i < playerNames.length
          ? playerNames[i]
          : fallbackName;

      final List<Pawn> pawns = List<Pawn>.generate(
        GameConstants.pawnsPerPlayer,
        (int pawnIndex) => Pawn(
          id: '${color.name}_$pawnIndex',
          color: color,
          steps: GameConstants.initialSteps,
        ),
      );

      players.add(Player(color: color, name: name, pawns: pawns));
    }

    return GameState(
      mode: mode,
      status: status,
      players: players,
      currentTurnIndex: 0,
      diceValue: null,
      hasRolled: false,
      isRolling: false,
      movablePawnIds: const <String>[],
      winner: null,
      infoMessage: status == GameStatus.lobby
          ? 'En attente des joueurs...'
          : 'Partie démarrée',
      turnCount: 1,
      lastMovedPawnId: null,
      lastMovedPathSteps: const <int>[],
      moveSerial: 0,
    );
  }

  GameState startGame(GameState state) {
    return state.copyWith(
      status: GameStatus.inProgress,
      diceValue: null,
      hasRolled: false,
      isRolling: false,
      movablePawnIds: const <String>[],
      winner: null,
      infoMessage: 'À ${state.players[state.currentTurnIndex].name} de jouer',
      turnCount: 1,
      lastMovedPawnId: null,
      lastMovedPathSteps: const <int>[],
      moveSerial: 0,
    );
  }

  List<String> getMovablePawnIds(GameState state, int dice) {
    final Player currentPlayer = state.currentPlayer;
    final List<String> movable = <String>[];

    for (final Pawn pawn in currentPlayer.pawns) {
      if (_canMovePawn(pawn, dice)) {
        movable.add(pawn.id);
      }
    }

    return movable;
  }

  GameState setRolling(GameState state, bool isRolling) {
    return state.copyWith(isRolling: isRolling);
  }

  GameState applyDiceRoll(GameState state, int dice) {
    final List<String> movablePawnIds = getMovablePawnIds(state, dice);
    final String info = movablePawnIds.isEmpty
        ? 'Aucun déplacement possible'
        : 'Sélectionnez un pion';

    return state.copyWith(
      diceValue: dice,
      hasRolled: true,
      movablePawnIds: movablePawnIds,
      infoMessage: info,
    );
  }

  GameState resolveNoMoveTurn(GameState state) {
    final bool extraTurn = state.diceValue == GameConstants.maxDice;
    return _advanceTurn(state, keepCurrentPlayer: extraTurn);
  }

  GameState moveSelectedPawn(GameState state, String pawnId) {
    return moveSelectedPawnDetailed(state, pawnId).state;
  }

  MoveResolution moveSelectedPawnDetailed(GameState state, String pawnId) {
    final int dice = state.diceValue ?? 0;
    final Player player = state.currentPlayer;
    final Pawn pawn = player.pawns.firstWhere((Pawn value) => value.id == pawnId);

    if (!_canMovePawn(pawn, dice)) {
      return MoveResolution(
        state: state.copyWith(infoMessage: 'Déplacement invalide'),
        movedPawnId: null,
        pathSteps: const <int>[],
      );
    }

    final List<int> pathSteps = _buildPathSteps(pawn.steps, pawn.isInYard, dice);
    final int nextSteps = pawn.isInYard ? 1 : pawn.steps + dice;
    final Pawn movedPawn = pawn.copyWith(steps: nextSteps);

    final List<Pawn> updatedPawns = player.pawns
        .map((Pawn value) => value.id == pawn.id ? movedPawn : value)
        .toList(growable: false);

    List<Player> updatedPlayers = state.players
        .map((Player value) => value.color == player.color
            ? value.copyWith(pawns: updatedPawns)
            : value)
        .toList(growable: false);

    final CaptureResult captureResult = _captureOpponentsIfNeeded(
      players: updatedPlayers,
      movedPawn: movedPawn,
      movingColor: player.color,
    );

    updatedPlayers = captureResult.players;

    final Player updatedCurrentPlayer =
        updatedPlayers.firstWhere((Player value) => value.color == player.color);

    final bool winner = updatedCurrentPlayer.hasWon;
    final bool rolledSix = dice == GameConstants.maxDice;
    final bool extraTurn = rolledSix || captureResult.captured;

    GameState newState = state.copyWith(
      players: updatedPlayers,
      infoMessage: _buildMoveMessage(
        currentPlayerName: player.name,
        rolledSix: rolledSix,
        capture: captureResult.captured,
        winner: winner,
      ),
      lastMovedPawnId: pawn.id,
      lastMovedPathSteps: pathSteps,
      moveSerial: state.moveSerial + 1,
    );

    if (winner) {
      return MoveResolution(
        state: newState.copyWith(
          status: GameStatus.finished,
          winner: player.color,
          hasRolled: false,
          diceValue: null,
          movablePawnIds: const <String>[],
          isRolling: false,
        ),
        movedPawnId: pawn.id,
        pathSteps: pathSteps,
      );
    }

    return MoveResolution(
      state: _advanceTurn(newState, keepCurrentPlayer: extraTurn),
      movedPawnId: pawn.id,
      pathSteps: pathSteps,
    );
  }

  GridPosition pawnGridPosition(Pawn pawn) {
    if (pawn.isInYard) {
      final int pawnIndex = int.tryParse(pawn.id.split('_').last) ?? 0;
      final List<GridPosition> positions = BoardConstants.yardPositions[pawn.color]!;
      return positions[pawnIndex % positions.length];
    }

    if (pawn.isOnTrack) {
      final int trackIndex = trackIndexForPawn(pawn)!;
      return BoardConstants.track[trackIndex];
    }

    if (pawn.isInHomeLane) {
      final int laneIndex = pawn.steps - GameConstants.homeLaneStartSteps;
      return BoardConstants.homeLanes[pawn.color]![laneIndex];
    }

    return BoardConstants.center;
  }

  int? trackIndexForPawn(Pawn pawn) {
    if (!pawn.isOnTrack) {
      return null;
    }

    return (pawn.color.startTrackIndex + pawn.steps - 1) % 52;
  }

  bool isSafePawnPosition(Pawn pawn) {
    final int? trackIndex = trackIndexForPawn(pawn);
    if (trackIndex == null) {
      return true;
    }
    return BoardConstants.safeTrackIndices.contains(trackIndex);
  }

  bool _canMovePawn(Pawn pawn, int dice) {
    if (pawn.isFinished || dice < GameConstants.minDice || dice > GameConstants.maxDice) {
      return false;
    }

    if (pawn.isInYard) {
      return dice == GameConstants.maxDice;
    }

    return pawn.steps + dice <= GameConstants.finishedSteps;
  }

  List<int> _buildPathSteps(int startSteps, bool fromYard, int dice) {
    if (fromYard) {
      return <int>[GameConstants.initialSteps, 1];
    }

    final List<int> path = <int>[startSteps];
    for (int step = 1; step <= dice; step++) {
      path.add(startSteps + step);
    }
    return path;
  }

  CaptureResult _captureOpponentsIfNeeded({
    required List<Player> players,
    required Pawn movedPawn,
    required PlayerColor movingColor,
  }) {
    if (!movedPawn.isOnTrack || isSafePawnPosition(movedPawn)) {
      return CaptureResult(players: players, captured: false);
    }

    final int landingTrackIndex = trackIndexForPawn(movedPawn)!;
    bool captured = false;

    final List<Player> updatedPlayers = players.map((Player player) {
      if (player.color == movingColor) {
        return player;
      }

      final List<Pawn> updatedPawns = player.pawns.map((Pawn pawn) {
        final int? trackIndex = trackIndexForPawn(pawn);
        if (trackIndex == null) {
          return pawn;
        }

        if (trackIndex == landingTrackIndex && !isSafePawnPosition(pawn)) {
          captured = true;
          return pawn.copyWith(steps: GameConstants.initialSteps);
        }

        return pawn;
      }).toList(growable: false);

      return player.copyWith(pawns: updatedPawns);
    }).toList(growable: false);

    return CaptureResult(players: updatedPlayers, captured: captured);
  }

  GameState _advanceTurn(GameState state, {required bool keepCurrentPlayer}) {
    final int nextTurnIndex = keepCurrentPlayer
        ? state.currentTurnIndex
        : (state.currentTurnIndex + 1) % state.players.length;

    final int nextTurnCount = keepCurrentPlayer ? state.turnCount : state.turnCount + 1;
    final String nextMessage = keepCurrentPlayer
        ? 'Même joueur: ${state.players[nextTurnIndex].name}'
        : 'À ${state.players[nextTurnIndex].name} de jouer';

    return state.copyWith(
      currentTurnIndex: nextTurnIndex,
      turnCount: nextTurnCount,
      hasRolled: false,
      diceValue: null,
      movablePawnIds: const <String>[],
      isRolling: false,
      infoMessage: nextMessage,
    );
  }

  String _buildMoveMessage({
    required String currentPlayerName,
    required bool rolledSix,
    required bool capture,
    required bool winner,
  }) {
    if (winner) {
      return '$currentPlayerName a gagné la partie';
    }

    if (capture && rolledSix) {
      return '$currentPlayerName capture et rejoue';
    }

    if (capture) {
      return '$currentPlayerName a capturé un pion';
    }

    if (rolledSix) {
      return '$currentPlayerName a fait 6 et rejoue';
    }

    return '$currentPlayerName a déplacé un pion';
  }
}

class CaptureResult {
  final List<Player> players;
  final bool captured;

  const CaptureResult({
    required this.players,
    required this.captured,
  });
}

class MoveResolution {
  final GameState state;
  final String? movedPawnId;
  final List<int> pathSteps;

  const MoveResolution({
    required this.state,
    required this.movedPawnId,
    required this.pathSteps,
  });
}

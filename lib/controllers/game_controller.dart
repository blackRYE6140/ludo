import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/constants/game_constants.dart';
import '../core/constants/network_constants.dart';
import '../core/utils/dice_utils.dart';
import '../core/utils/network_utils.dart';
import '../models/game_state.dart';
import '../models/pawn.dart';
import '../models/player.dart';
import '../services/audio_service.dart';
import '../services/local_game_service.dart';
import '../services/socket_service.dart';

class GameController extends ChangeNotifier {
  GameController({
    LocalGameService? localGameService,
    SocketService? socketService,
    AudioService? audioService,
  })  : _localGameService = localGameService ?? LocalGameService(),
        _socketService = socketService ?? SocketService(),
        _audioService = audioService ?? AudioService() {
    unawaited(_audioService.initialize());
  }

  final LocalGameService _localGameService;
  final SocketService _socketService;
  final AudioService _audioService;

  GameState? _state;
  String _networkInfo = '';
  String _lastError = '';
  int _desiredPlayers = 2;
  int? _localPlayerIndex;

  final Map<String, int> _peerPlayerIndexById = <String, int>{};

  GameState? get state => _state;

  String get networkInfo => _networkInfo;

  String get lastError => _lastError;

  int get desiredPlayers => _desiredPlayers;

  int? get localPlayerIndex => _localPlayerIndex;

  LocalGameService get localGameService => _localGameService;

  bool get hasState => _state != null;

  bool get isWifiMode {
    final GameMode? mode = _state?.mode;
    return mode == GameMode.wifiHost || mode == GameMode.wifiClient;
  }

  bool get isLocalPlayersTurn {
    final GameState? current = _state;
    if (current == null) {
      return false;
    }

    if (current.mode == GameMode.local) {
      return true;
    }

    if (_localPlayerIndex == null) {
      return false;
    }

    return _localPlayerIndex == current.currentTurnIndex;
  }

  bool get canRoll {
    final GameState? current = _state;
    return current != null && current.canRoll && isLocalPlayersTurn;
  }

  bool get canStartHostedGame {
    final GameState? current = _state;
    if (current == null || current.mode != GameMode.wifiHost) {
      return false;
    }

    if (current.status != GameStatus.lobby) {
      return false;
    }

    return connectedPlayersCount >= 2 && connectedPlayersCount == _desiredPlayers;
  }

  int get connectedPlayersCount {
    final GameState? current = _state;
    if (current == null) {
      return 0;
    }

    return current.players.where((Player player) => !player.name.startsWith('En attente')).length;
  }

  Future<void> createLocalGame({required int playerCount}) async {
    _resetErrors();
    _desiredPlayers = playerCount;
    _localPlayerIndex = 0;

    final GameState base = _localGameService.createInitialState(
      playerCount: playerCount,
      mode: GameMode.local,
      status: GameStatus.inProgress,
    );

    _state = _localGameService.startGame(base);
    _networkInfo = '';
    await _socketService.stop();
    notifyListeners();
  }

  Future<void> hostWifiGame({
    required int playerCount,
    required String playerName,
    int port = NetworkConstants.defaultPort,
  }) async {
    _resetErrors();
    _desiredPlayers = playerCount;
    _localPlayerIndex = 0;
    _peerPlayerIndexById.clear();

    _configureSocketCallbacks();

    try {
      await _socketService.startHost(port: port);
    } catch (e) {
      _lastError = 'Impossible de démarrer l\'hôte: $e';
      notifyListeners();
      return;
    }

    final List<String> addresses = await NetworkUtils.getLocalIPv4Addresses();
    final String primaryAddress = addresses.isNotEmpty ? addresses.first : 'Adresse introuvable';
    _networkInfo = 'Hôte: $primaryAddress:$port';

    final List<String> names = <String>[playerName];
    for (int i = 1; i < playerCount; i++) {
      names.add('En attente ${i + 1}');
    }

    _state = _localGameService.createInitialState(
      playerCount: playerCount,
      mode: GameMode.wifiHost,
      status: GameStatus.lobby,
      playerNames: names,
    );
    notifyListeners();

    await _broadcastLobbyUpdate();
  }

  Future<void> joinWifiGame({
    required String host,
    required int port,
    required String playerName,
  }) async {
    _resetErrors();
    _localPlayerIndex = null;
    _peerPlayerIndexById.clear();

    _configureSocketCallbacks();

    try {
      await _socketService.connectToHost(host: host, port: port);
    } catch (e) {
      _lastError = 'Connexion impossible: $e';
      notifyListeners();
      return;
    }

    _networkInfo = 'Connecté à $host:$port';

    _state = _localGameService.createInitialState(
      playerCount: GameConstants.minPlayers,
      mode: GameMode.wifiClient,
      status: GameStatus.lobby,
      playerNames: <String>['Vous', 'Hôte'],
    );

    notifyListeners();

    await _socketService.sendToHost(<String, dynamic>{
      'type': NetworkConstants.typeJoinRequest,
      'name': playerName,
      'protocol': NetworkConstants.protocolVersion,
    });
  }

  Future<void> startHostedGame() async {
    final GameState? current = _state;
    if (current == null || current.mode != GameMode.wifiHost) {
      return;
    }

    if (!canStartHostedGame) {
      _lastError = 'Tous les joueurs ne sont pas encore connectés.';
      notifyListeners();
      return;
    }

    _state = _localGameService.startGame(current);
    notifyListeners();

    await _broadcastState(messageType: NetworkConstants.typeStartGame);
  }

  Future<void> rollDice() async {
    final GameState? current = _state;
    if (current == null || !canRoll) {
      return;
    }

    if (current.mode == GameMode.wifiClient) {
      await _socketService.sendToHost(<String, dynamic>{
        'type': NetworkConstants.typeActionRoll,
      });
      return;
    }

    await _executeRoll();
  }

  Future<void> movePawn(String pawnId) async {
    final GameState? current = _state;
    if (current == null || !isLocalPlayersTurn) {
      return;
    }

    if (current.mode == GameMode.wifiClient) {
      await _socketService.sendToHost(<String, dynamic>{
        'type': NetworkConstants.typeActionMove,
        'pawnId': pawnId,
      });
      return;
    }

    await _executeMove(pawnId);
  }

  Future<void> leaveGame() async {
    if (_state?.mode == GameMode.wifiClient) {
      await _socketService.sendToHost(<String, dynamic>{
        'type': NetworkConstants.typeDisconnect,
      });
    }

    await _socketService.stop();
    _peerPlayerIndexById.clear();
    _state = null;
    _networkInfo = '';
    _lastError = '';
    notifyListeners();
  }

  Player? pawnOwner(String pawnId) {
    final GameState? current = _state;
    if (current == null) {
      return null;
    }

    for (final Player player in current.players) {
      if (player.pawns.any((Pawn pawn) => pawn.id == pawnId)) {
        return player;
      }
    }

    return null;
  }

  Future<void> _executeRoll() async {
    final GameState? currentState = _state;
    if (currentState == null || !currentState.canRoll) {
      return;
    }

    _state = _localGameService.setRolling(currentState, true);
    notifyListeners();
    unawaited(HapticFeedback.selectionClick());

    await Future<void>.delayed(const Duration(milliseconds: 450));

    final int dice = DiceUtils.roll();
    final GameState rolledState = _localGameService.applyDiceRoll(_state!, dice);
    _state = rolledState.copyWith(isRolling: false);
    notifyListeners();
    unawaited(HapticFeedback.lightImpact());
    unawaited(_audioService.playDiceRoll());

    if (_state!.movablePawnIds.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _state = _localGameService.resolveNoMoveTurn(_state!);
      notifyListeners();
    }

    await _broadcastState();
  }

  Future<void> _executeMove(String pawnId) async {
    final GameState? currentState = _state;
    if (currentState == null || !currentState.movablePawnIds.contains(pawnId)) {
      return;
    }

    final MoveResolution resolution =
        _localGameService.moveSelectedPawnDetailed(currentState, pawnId);
    _state = resolution.state;
    notifyListeners();
    unawaited(HapticFeedback.mediumImpact());

    if (_state!.status == GameStatus.finished && _state!.winner != null) {
      unawaited(_audioService.playVictory());
    } else if (_state!.infoMessage.contains('captur')) {
      unawaited(_audioService.playCapture());
    } else {
      unawaited(_audioService.playPawnMove());
    }

    await _broadcastState();
  }

  void _configureSocketCallbacks() {
    _socketService.onMessage = (Map<String, dynamic> message, String senderId) {
      unawaited(_handleSocketMessage(message, senderId));
    };
    _socketService.onPeerConnected = _handlePeerConnected;
    _socketService.onPeerDisconnected = _handlePeerDisconnected;
  }

  Future<void> _handleSocketMessage(Map<String, dynamic> message, String senderId) async {
    final String type = (message['type'] ?? '') as String;

    switch (type) {
      case NetworkConstants.typeJoinRequest:
        await _handleJoinRequest(message, senderId);
        break;
      case NetworkConstants.typeJoinAccepted:
        _handleJoinAccepted(message);
        break;
      case NetworkConstants.typeLobbyUpdate:
      case NetworkConstants.typeStateUpdate:
      case NetworkConstants.typeStartGame:
        _applyStateFromNetwork(message);
        break;
      case NetworkConstants.typeActionRoll:
        await _handleRemoteRoll(senderId);
        break;
      case NetworkConstants.typeActionMove:
        await _handleRemoteMove(message, senderId);
        break;
      case NetworkConstants.typeDisconnect:
        _handleRemoteDisconnect(senderId);
        break;
      case NetworkConstants.typeError:
        _lastError = (message['message'] ?? 'Erreur réseau inconnue') as String;
        notifyListeners();
        break;
      default:
        break;
    }
  }

  void _handlePeerConnected(String peerId) {
    if (_state?.mode != GameMode.wifiHost) {
      return;
    }

    _state = _state?.copyWith(infoMessage: 'Nouveau joueur connecté');
    notifyListeners();
  }

  void _handlePeerDisconnected(String peerId) {
    final GameState? current = _state;
    if (current == null) {
      return;
    }

    if (current.mode == GameMode.wifiHost) {
      final int? playerIndex = _peerPlayerIndexById.remove(peerId);
      if (playerIndex != null && playerIndex < current.players.length) {
        final List<Player> players = List<Player>.from(current.players);
        final Player player = players[playerIndex];
        players[playerIndex] = player.copyWith(name: 'En attente ${playerIndex + 1}');

        final bool gameInterrupted = current.status == GameStatus.inProgress;
        _state = current.copyWith(
          players: players,
          status: gameInterrupted ? GameStatus.finished : current.status,
          infoMessage: gameInterrupted
              ? 'Partie interrompue: un joueur s\'est déconnecté.'
              : 'Un joueur a quitté le lobby.',
          winner: gameInterrupted ? null : current.winner,
          hasRolled: false,
          diceValue: null,
          movablePawnIds: const <String>[],
        );
      }

      notifyListeners();
      unawaited(_broadcastState());
      return;
    }

    if (current.mode == GameMode.wifiClient) {
      _state = current.copyWith(
        status: GameStatus.finished,
        infoMessage: 'Connexion perdue avec l\'hôte.',
        hasRolled: false,
        diceValue: null,
        movablePawnIds: const <String>[],
      );
      notifyListeners();
    }
  }

  Future<void> _handleJoinRequest(Map<String, dynamic> message, String senderId) async {
    final GameState? current = _state;
    if (current == null || current.mode != GameMode.wifiHost) {
      return;
    }

    if (current.status != GameStatus.lobby) {
      await _socketService.sendToClient(senderId, <String, dynamic>{
        'type': NetworkConstants.typeError,
        'message': 'La partie est déjà démarrée.',
      });
      return;
    }

    if (_peerPlayerIndexById.containsKey(senderId)) {
      return;
    }

    final int nextIndex = _nextAvailablePlayerIndex(current);
    if (nextIndex == -1) {
      await _socketService.sendToClient(senderId, <String, dynamic>{
        'type': NetworkConstants.typeError,
        'message': 'Lobby complet.',
      });
      return;
    }

    _peerPlayerIndexById[senderId] = nextIndex;

    final String requestedName = (message['name'] ?? 'Joueur ${nextIndex + 1}') as String;
    final List<Player> players = List<Player>.from(current.players);
    players[nextIndex] = players[nextIndex].copyWith(name: requestedName);

    _state = current.copyWith(
      players: players,
      infoMessage: '$requestedName a rejoint la partie',
    );

    notifyListeners();

    await _socketService.sendToClient(senderId, <String, dynamic>{
      'type': NetworkConstants.typeJoinAccepted,
      'playerIndex': nextIndex,
      'color': players[nextIndex].color.code,
      'desiredPlayers': _desiredPlayers,
      'state': _state!.toJson(),
    });

    await _broadcastLobbyUpdate();
  }

  void _handleJoinAccepted(Map<String, dynamic> message) {
    final int playerIndex = (message['playerIndex'] ?? -1) as int;
    if (playerIndex < 0) {
      _lastError = 'Réponse hôte invalide.';
      notifyListeners();
      return;
    }

    _localPlayerIndex = playerIndex;
    _desiredPlayers = (message['desiredPlayers'] ?? _desiredPlayers) as int;

    _applyStateFromNetwork(message);

    final String color = (message['color'] ?? 'red') as String;
    _networkInfo = 'Vous êtes ${PlayerColorX.fromCode(color).label}';
    notifyListeners();
  }

  Future<void> _handleRemoteRoll(String senderId) async {
    final GameState? current = _state;
    if (current == null || current.mode != GameMode.wifiHost) {
      return;
    }

    final int? requestedIndex = _peerPlayerIndexById[senderId];
    if (requestedIndex == null || requestedIndex != current.currentTurnIndex) {
      return;
    }

    if (!current.canRoll) {
      return;
    }

    await _executeRoll();
  }

  Future<void> _handleRemoteMove(Map<String, dynamic> message, String senderId) async {
    final GameState? current = _state;
    if (current == null || current.mode != GameMode.wifiHost) {
      return;
    }

    final int? requestedIndex = _peerPlayerIndexById[senderId];
    if (requestedIndex == null || requestedIndex != current.currentTurnIndex) {
      return;
    }

    final String pawnId = (message['pawnId'] ?? '') as String;
    if (pawnId.isEmpty || !current.movablePawnIds.contains(pawnId)) {
      return;
    }

    await _executeMove(pawnId);
  }

  void _handleRemoteDisconnect(String senderId) {
    if (_state?.mode != GameMode.wifiHost) {
      return;
    }

    _handlePeerDisconnected(senderId);
  }

  void _applyStateFromNetwork(Map<String, dynamic> message) {
    final dynamic rawState = message['state'];
    if (rawState is! Map<String, dynamic>) {
      return;
    }

    final GameState remoteState = GameState.fromJson(rawState);
    _state = remoteState;
    notifyListeners();
  }

  Future<void> _broadcastLobbyUpdate() async {
    if (_state == null || _state!.mode != GameMode.wifiHost) {
      return;
    }

    await _socketService.broadcast(<String, dynamic>{
      'type': NetworkConstants.typeLobbyUpdate,
      'state': _state!.toJson(),
    });
  }

  Future<void> _broadcastState({
    String messageType = NetworkConstants.typeStateUpdate,
  }) async {
    if (_state == null || _state!.mode != GameMode.wifiHost) {
      return;
    }

    await _socketService.broadcast(<String, dynamic>{
      'type': messageType,
      'state': _state!.toJson(),
    });
  }

  int _nextAvailablePlayerIndex(GameState current) {
    for (int index = 1; index < current.players.length; index++) {
      final Player player = current.players[index];
      if (player.name.startsWith('En attente')) {
        return index;
      }
    }

    return -1;
  }

  void _resetErrors() {
    _lastError = '';
    _networkInfo = '';
  }

  @override
  void dispose() {
    unawaited(_socketService.stop());
    unawaited(_audioService.dispose());
    super.dispose();
  }
}

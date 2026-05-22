class NetworkConstants {
  static const int defaultPort = 4545;
  static const String protocolVersion = '1.0';

  static const String typeJoinRequest = 'join_request';
  static const String typeJoinAccepted = 'join_accepted';
  static const String typeLobbyUpdate = 'lobby_update';
  static const String typeStartGame = 'start_game';
  static const String typeStateUpdate = 'state_update';
  static const String typeActionRoll = 'action_roll';
  static const String typeActionMove = 'action_move';
  static const String typeDisconnect = 'disconnect';
  static const String typeError = 'error';
}

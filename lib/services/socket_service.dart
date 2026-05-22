import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef SocketMessageHandler = void Function(
  Map<String, dynamic> message,
  String senderId,
);

typedef SocketDisconnectHandler = void Function(String peerId);

typedef SocketConnectHandler = void Function(String peerId);

class SocketService {
  ServerSocket? _server;
  Socket? _hostSocket;

  final Map<String, Socket> _clientSockets = <String, Socket>{};
  final Map<String, StreamSubscription<String>> _lineSubscriptions =
      <String, StreamSubscription<String>>{};

  SocketMessageHandler? onMessage;
  SocketConnectHandler? onPeerConnected;
  SocketDisconnectHandler? onPeerDisconnected;

  bool get isHosting => _server != null;

  bool get isConnectedAsClient => _hostSocket != null;

  List<String> get connectedClientIds => _clientSockets.keys.toList(growable: false);

  Future<void> startHost({required int port}) async {
    await stop();
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);

    _server!.listen((Socket socket) {
      final String peerId = _peerIdForSocket(socket);
      _clientSockets[peerId] = socket;
      _listenToSocket(socket: socket, peerId: peerId, isHostConnection: false);
      onPeerConnected?.call(peerId);
    });
  }

  Future<void> connectToHost({required String host, required int port}) async {
    await stop();
    _hostSocket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    _listenToSocket(socket: _hostSocket!, peerId: 'host', isHostConnection: true);
  }

  Future<void> sendToHost(Map<String, dynamic> message) async {
    final Socket? socket = _hostSocket;
    if (socket == null) {
      return;
    }
    socket.write('${jsonEncode(message)}\n');
    await socket.flush();
  }

  Future<void> sendToClient(String peerId, Map<String, dynamic> message) async {
    final Socket? socket = _clientSockets[peerId];
    if (socket == null) {
      return;
    }

    socket.write('${jsonEncode(message)}\n');
    await socket.flush();
  }

  Future<void> broadcast(
    Map<String, dynamic> message, {
    String? excludePeerId,
  }) async {
    final List<Future<void>> sends = <Future<void>>[];
    for (final MapEntry<String, Socket> entry in _clientSockets.entries) {
      if (excludePeerId != null && entry.key == excludePeerId) {
        continue;
      }

      entry.value.write('${jsonEncode(message)}\n');
      sends.add(entry.value.flush());
    }

    await Future.wait(sends);
  }

  Future<void> stop() async {
    for (final StreamSubscription<String> subscription in _lineSubscriptions.values) {
      await subscription.cancel();
    }
    _lineSubscriptions.clear();

    for (final Socket socket in _clientSockets.values) {
      await socket.close();
      socket.destroy();
    }
    _clientSockets.clear();

    if (_hostSocket != null) {
      await _hostSocket!.close();
      _hostSocket!.destroy();
      _hostSocket = null;
    }

    if (_server != null) {
      await _server!.close();
      _server = null;
    }
  }

  void _listenToSocket({
    required Socket socket,
    required String peerId,
    required bool isHostConnection,
  }) {
    final Stream<String> lineStream = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final StreamSubscription<String> subscription = lineStream.listen(
      (String line) {
        try {
          final dynamic data = jsonDecode(line);
          if (data is Map<String, dynamic>) {
            onMessage?.call(data, peerId);
          }
        } catch (_) {
          // Ignore invalid network payloads.
        }
      },
      onError: (_) {
        _handleDisconnect(peerId: peerId, isHostConnection: isHostConnection);
      },
      onDone: () {
        _handleDisconnect(peerId: peerId, isHostConnection: isHostConnection);
      },
      cancelOnError: true,
    );

    _lineSubscriptions[peerId] = subscription;
  }

  Future<void> _handleDisconnect({
    required String peerId,
    required bool isHostConnection,
  }) async {
    final StreamSubscription<String>? subscription = _lineSubscriptions.remove(peerId);
    await subscription?.cancel();

    if (isHostConnection) {
      await _hostSocket?.close();
      _hostSocket?.destroy();
      _hostSocket = null;
      onPeerDisconnected?.call(peerId);
      return;
    }

    final Socket? socket = _clientSockets.remove(peerId);
    if (socket != null) {
      await socket.close();
      socket.destroy();
    }

    onPeerDisconnected?.call(peerId);
  }

  String _peerIdForSocket(Socket socket) {
    return '${socket.remoteAddress.address}:${socket.remotePort}';
  }
}

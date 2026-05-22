import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService();

  final AudioPlayer _dicePlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _capturePlayer = AudioPlayer();
  final AudioPlayer _victoryPlayer = AudioPlayer();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final List<AudioPlayer> players = <AudioPlayer>[
      _dicePlayer,
      _movePlayer,
      _capturePlayer,
      _victoryPlayer,
    ];

    for (final AudioPlayer player in players) {
      await _safeSetLowLatency(player);
      await _safeSetReleaseMode(player, ReleaseMode.stop);
    }
    await _safeSetVolume(_dicePlayer, 0.85);
    await _safeSetVolume(_movePlayer, 0.70);
    await _safeSetVolume(_capturePlayer, 0.88);
    await _safeSetVolume(_victoryPlayer, 0.82);

    _initialized = true;
  }

  Future<void> playDiceRoll() => _play(_dicePlayer, 'audio/dice_roll.wav');

  Future<void> playPawnMove() => _play(_movePlayer, 'audio/pawn_move.wav');

  Future<void> playCapture() => _play(_capturePlayer, 'audio/capture.wav');

  Future<void> playVictory() => _play(_victoryPlayer, 'audio/victory.wav');

  Future<void> dispose() async {
    await _dicePlayer.dispose();
    await _movePlayer.dispose();
    await _capturePlayer.dispose();
    await _victoryPlayer.dispose();
  }

  Future<void> _play(AudioPlayer player, String assetPath) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Best effort: audio failure must never block gameplay.
    }
  }

  Future<void> _safeSetLowLatency(AudioPlayer player) async {
    try {
      await player.setPlayerMode(PlayerMode.lowLatency);
    } catch (_) {
      // Some platforms ignore low latency mode.
    }
  }

  Future<void> _safeSetVolume(AudioPlayer player, double volume) async {
    try {
      await player.setVolume(volume);
    } catch (_) {
      // Ignore on platforms that don't support this call yet.
    }
  }

  Future<void> _safeSetReleaseMode(AudioPlayer player, ReleaseMode mode) async {
    try {
      await player.setReleaseMode(mode);
    } catch (_) {
      // Ignore on platforms that don't support this call yet.
    }
  }
}

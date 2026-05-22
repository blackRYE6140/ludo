import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import '../widgets/ludo_board.dart';
import '../widgets/player_status_bar.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final GameState? state = controller.state;
        if (state == null) {
          return const Scaffold(
            body: Center(child: Text('Aucune partie en cours')),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) {
              return;
            }
            _leaveGame(context);
          },
          child: Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF092261), Color(0xFF06164A)],
                ),
              ),
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _BackgroundPatternPainter()),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        children: <Widget>[
                          _TopBar(
                            title: _titleForMode(state.mode),
                            onBack: () async {
                              await _leaveGame(context);
                            },
                            onExit: () => _leaveGame(context),
                          ),
                          const SizedBox(height: 10),
                          PlayerStatusBar(
                            state: state,
                            localPlayerIndex: controller.localPlayerIndex,
                            diceValue: state.diceValue,
                            isRolling: state.isRolling,
                            isLocalPlayersTurn: controller.isLocalPlayersTurn,
                            canRoll: controller.canRoll,
                            rowSlots: const <int>[0, 1],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Center(
                              child: LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints constraints,
                                    ) {
                                      final double maxBoard = math.min(
                                        constraints.maxWidth,
                                        constraints.maxHeight,
                                      );

                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: math.min(680, maxBoard),
                                        ),
                                        child: LudoBoard(
                                          state: state,
                                          gameService:
                                              controller.localGameService,
                                          isLocalPlayersTurn:
                                              controller.isLocalPlayersTurn,
                                          onPawnTap: (String pawnId) {
                                            controller.movePawn(pawnId);
                                          },
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          PlayerStatusBar(
                            state: state,
                            localPlayerIndex: controller.localPlayerIndex,
                            diceValue: state.diceValue,
                            isRolling: state.isRolling,
                            isLocalPlayersTurn: controller.isLocalPlayersTurn,
                            canRoll: controller.canRoll,
                            rowSlots: const <int>[2, 3],
                          ),
                          const SizedBox(height: 10),
                          _ActionStrip(controller: controller, state: state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _leaveGame(BuildContext context) async {
    await controller.leaveGame();
    if (context.mounted) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
  }

  String _titleForMode(GameMode mode) {
    switch (mode) {
      case GameMode.local:
        return 'Ludo Local';
      case GameMode.wifiHost:
        return 'Ludo Wi-Fi (Hôte)';
      case GameMode.wifiClient:
        return 'Ludo Wi-Fi (Client)';
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onExit,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: <Widget>[
          _IconTile(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 31,
                letterSpacing: 0.6,
                shadows: <Shadow>[
                  Shadow(
                    color: Color(0x99000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _IconTile(icon: Icons.exit_to_app_rounded, onTap: onExit),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB3071035),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.controller, required this.state});

  final GameController controller;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final Color accent = state.isFinished
        ? const Color(0xFF607D8B)
        : state.currentPlayer.color.color;

    final bool canShowRoll = !state.isFinished && controller.isLocalPlayersTurn;
    final bool canRollNow = canShowRoll && controller.canRoll;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD3DEEF), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4D020A26),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  state.isFinished
                      ? 'Victoire : ${state.currentPlayer.name}'
                      : 'Tour : ${state.currentPlayer.name}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.infoMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2F3B59),
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (controller.networkInfo.isNotEmpty)
                  Text(
                    controller.networkInfo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF546E7A),
                      fontSize: 14,
                    ),
                  ),
                if (controller.lastError.isNotEmpty)
                  Text(
                    controller.lastError,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: canShowRoll
                ? SizedBox(
                    key: const ValueKey<String>('roll_button'),
                    width: 194,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: canRollNow ? controller.rollDice : null,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFF8FA0B9),
                        disabledForegroundColor: Colors.white70,
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.casino_rounded, size: 24),
                      label: const Text(
                        'LANCER',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey<String>('wait_tile'),
                    width: 168,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFD8E6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'En attente',
                      style: TextStyle(
                        color: Color(0xFF455A64),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  const _BackgroundPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = const Color(0x12000000);
    const double step = 30;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        dot..strokeWidth = 1,
      );
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dot);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) {
    return false;
  }
}

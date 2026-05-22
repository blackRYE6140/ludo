import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/pawn.dart';
import '../../models/player.dart';
import 'dice_face.dart';

class PlayerStatusBar extends StatelessWidget {
  const PlayerStatusBar({
    super.key,
    required this.state,
    required this.localPlayerIndex,
    required this.diceValue,
    required this.isRolling,
    required this.isLocalPlayersTurn,
    required this.canRoll,
    required this.rowSlots,
    required this.onRoll,
  });

  final GameState state;
  final int? localPlayerIndex;
  final int? diceValue;
  final bool isRolling;
  final bool isLocalPlayersTurn;
  final bool canRoll;
  final List<int> rowSlots;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: rowSlots
          .map(
            (int slot) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildSlot(slot),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildSlot(int slot) {
    final Player? player = slot < state.players.length
        ? state.players[slot]
        : null;
    final bool isCurrent = slot == state.currentTurnIndex;
    final bool isLocal = slot == localPlayerIndex;
    final bool diceOnLeft = slot == 0 || slot == 3;
    final int finished = player == null
        ? 0
        : player.pawns.where((Pawn pawn) => pawn.isFinished).length;

    final Color normalColor = player?.color.color ?? const Color(0xFF90A4AE);
    Color diceColor = normalColor;
    if (state.players.length == 2 && player?.color == PlayerColor.yellow) {
      diceColor = PlayerColor.green.color;
    }

    final Widget card = player == null
        ? const _PlayerPlaceholder()
        : _PlayerCard(
            player: player,
            finished: finished,
            isCurrent: isCurrent,
            isLocal: isLocal,
            accentColor: normalColor,
          );

    final Widget dice = _DiceDock(
      isActive: player != null && isCurrent,
      isRolling: player != null && isCurrent && isRolling,
      diceValue: player != null && isCurrent ? diceValue : null,
      accent: diceColor,
      canRoll: player != null && isCurrent && isLocalPlayersTurn && canRoll,
      onRoll: onRoll,
    );

    return SizedBox(
      height: 90,
      child: Row(
        children: diceOnLeft
            ? <Widget>[dice, const SizedBox(width: 8), Expanded(child: card)]
            : <Widget>[Expanded(child: card), const SizedBox(width: 8), dice],
      ),
    );
  }
}

class _PlayerCard extends StatefulWidget {
  const _PlayerCard({
    required this.player,
    required this.finished,
    required this.isCurrent,
    required this.isLocal,
    required this.accentColor,
  });

  final Player player;
  final int finished;
  final bool isCurrent;
  final bool isLocal;
  final Color accentColor;

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard>
    with SingleTickerProviderStateMixin {
  static const List<IconData> _avatars = <IconData>[
    Icons.sports_martial_arts_rounded,
    Icons.sentiment_very_satisfied_rounded,
    Icons.auto_awesome_rounded,
    Icons.rocket_launch_rounded,
  ];

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );

    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.accentColor;
    final bool darkText = accent.computeLuminance() > 0.5;
    final Color textColor = darkText ? const Color(0xFF172B3A) : Colors.white;
    final Color subtitleColor = textColor.withValues(alpha: 0.9);
    final int score = widget.finished * 100;

    final int colorIndex = widget.player.color.index;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (BuildContext context, _) {
        final double pulse = widget.isCurrent ? _pulseController.value : 0;

        return Transform.scale(
          scale: widget.isCurrent ? 1 + (pulse * 0.02) : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(accent, Colors.white, 0.18)!,
                  Color.lerp(accent, Colors.black, 0.12)!,
                ],
              ),
              border: Border.all(
                color: widget.isCurrent ? Colors.white : Colors.white70,
                width: widget.isCurrent ? 2.2 : 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(
                    alpha: widget.isCurrent ? 0.38 + (pulse * 0.18) : 0.2,
                  ),
                  blurRadius: widget.isCurrent ? 18 + (pulse * 8) : 8,
                  spreadRadius: widget.isCurrent ? 0.8 + pulse : 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.88),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Icon(
                    _avatars[colorIndex % _avatars.length],
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.player.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                shadows: const <Shadow>[
                                  Shadow(
                                    color: Color(0x55000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.isLocal)
                            Icon(
                              Icons.person_rounded,
                              color: textColor,
                              size: 14,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Maison : ${widget.finished}/4',
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.stars_rounded,
                            size: 12,
                            color: textColor.withValues(alpha: 0.92),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Score : $score',
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiceDock extends StatelessWidget {
  const _DiceDock({
    required this.isActive,
    required this.isRolling,
    required this.diceValue,
    required this.accent,
    required this.canRoll,
    required this.onRoll,
  });

  final bool isActive;
  final bool isRolling;
  final int? diceValue;
  final Color accent;
  final bool canRoll;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration inactiveDecoration = BoxDecoration(
      color: const Color(0x50000000),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x55FFFFFF), width: 1),
    );

    if (!isActive) {
      return Container(
        width: 56,
        height: 56,
        decoration: inactiveDecoration,
        child: const Icon(
          Icons.casino_outlined,
          color: Colors.white54,
          size: 24,
        ),
      );
    }

    return GestureDetector(
      onTap: canRoll ? onRoll : null,
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: canRoll
              ? accent.withValues(alpha: 0.45)
              : const Color(0x55FFFFFF),
          border: Border.all(
            color: canRoll ? Colors.white : const Color(0xB0FFFFFF),
            width: canRoll ? 2 : 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: canRoll ? 0.38 : 0.2),
              blurRadius: canRoll ? 10 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isRolling ? 1 : 0),
          duration: const Duration(milliseconds: 420),
          builder: (BuildContext context, double value, Widget? child) {
            final double angle = value * (math.pi * 2);
            return Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: 1 + (value * 0.06), child: child),
            );
          },
          child: DiceFace(
            value: diceValue,
            size: 48,
            accent: accent,
            showQuestionWhenNull: true,
          ),
        ),
      ),
    );
  }
}

class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x22000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x40FFFFFF), width: 1.1),
      ),
      child: const Center(
        child: Text(
          'Slot libre',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dice_face.dart';

class DicePanel extends StatelessWidget {
  const DicePanel({
    super.key,
    required this.diceValue,
    required this.isRolling,
    required this.canRoll,
    required this.isLocalPlayersTurn,
    required this.onRoll,
  });

  final int? diceValue;
  final bool isRolling;
  final bool canRoll;
  final bool isLocalPlayersTurn;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: <Widget>[
            Text(
              'Dé du tour',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isRolling ? 1 : 0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, Widget? child) {
                final double angle = value * (math.pi * 2);
                return Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: 1 + (value * 0.1),
                    child: child,
                  ),
                );
              },
              child: DiceFace(value: diceValue),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canRoll ? onRoll : null,
                icon: const Icon(Icons.casino_outlined),
                label: Text(isLocalPlayersTurn ? 'Lancer le dé' : 'Attendez votre tour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

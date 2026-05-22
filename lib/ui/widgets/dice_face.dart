import 'package:flutter/material.dart';

class DiceFace extends StatelessWidget {
  const DiceFace({
    super.key,
    required this.value,
    this.size = 84,
    this.showQuestionWhenNull = true,
    this.accent,
  });

  final int? value;
  final double size;
  final bool showQuestionWhenNull;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color glowColor = accent ?? const Color(0xFF37474F);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white,
            Color.lerp(const Color(0xFFF4F8FF), glowColor, 0.08)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF6E7A8B), width: 1.6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: glowColor.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: value == null
          ? showQuestionWhenNull
                ? Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF35495D),
                      ),
                    ),
                  )
                : const SizedBox.shrink()
          : CustomPaint(painter: _DicePainter(value: value!.clamp(1, 6))),
    );
  }
}

class _DicePainter extends CustomPainter {
  _DicePainter({required this.value});

  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = const Color(0xFF263238);
    final double r = size.width * 0.075;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset topLeft = Offset(size.width * 0.28, size.height * 0.28);
    final Offset topRight = Offset(size.width * 0.72, size.height * 0.28);
    final Offset bottomLeft = Offset(size.width * 0.28, size.height * 0.72);
    final Offset bottomRight = Offset(size.width * 0.72, size.height * 0.72);
    final Offset midLeft = Offset(size.width * 0.28, size.height / 2);
    final Offset midRight = Offset(size.width * 0.72, size.height / 2);

    final Map<int, List<Offset>> dots = <int, List<Offset>>{
      1: <Offset>[center],
      2: <Offset>[topLeft, bottomRight],
      3: <Offset>[topLeft, center, bottomRight],
      4: <Offset>[topLeft, topRight, bottomLeft, bottomRight],
      5: <Offset>[topLeft, topRight, center, bottomLeft, bottomRight],
      6: <Offset>[
        topLeft,
        topRight,
        midLeft,
        midRight,
        bottomLeft,
        bottomRight,
      ],
    };

    for (final Offset offset in dots[value] ?? <Offset>[center]) {
      canvas.drawCircle(offset, r, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter oldDelegate) {
    return value != oldDelegate.value;
  }
}

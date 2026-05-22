import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/board_constants.dart';
import '../../models/game_state.dart';
import '../../models/pawn.dart';
import '../../models/player.dart';
import '../../services/local_game_service.dart';

class LudoBoard extends StatefulWidget {
  const LudoBoard({
    super.key,
    required this.state,
    required this.gameService,
    required this.onPawnTap,
    required this.isLocalPlayersTurn,
  });

  final GameState state;
  final LocalGameService gameService;
  final ValueChanged<String> onPawnTap;
  final bool isLocalPlayersTurn;

  @override
  State<LudoBoard> createState() => _LudoBoardState();
}

class _LudoBoardState extends State<LudoBoard> {
  final Map<String, GridPosition> _displayPositions = <String, GridPosition>{};

  Timer? _pathTimer;
  int _lastHandledMoveSerial = 0;
  String? _animatingPawnId;

  @override
  void initState() {
    super.initState();
    _lastHandledMoveSerial = widget.state.moveSerial;
    _syncDisplayFromState();
  }

  @override
  void didUpdateWidget(covariant LudoBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    _removeMissingPawns();

    if (widget.state.moveSerial < _lastHandledMoveSerial) {
      _lastHandledMoveSerial = widget.state.moveSerial;
      _syncDisplayFromState();
      return;
    }

    final bool hasNewMove =
        widget.state.moveSerial > _lastHandledMoveSerial &&
        widget.state.lastMovedPawnId != null &&
        widget.state.lastMovedPathSteps.length > 1;

    if (hasNewMove) {
      _startStepAnimation();
      return;
    }

    if (_animatingPawnId == null) {
      _syncDisplayFromState();
    }
  }

  @override
  void dispose() {
    _pathTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double boardSize = constraints.biggest.shortestSide;
          final double boardInset = boardSize * _BoardPainter.frameFraction;
          final double playableSize = boardSize - (boardInset * 2);
          final double cellSize = playableSize / BoardConstants.boardSize;

          final List<_PawnRenderData> pawns = _buildPawns(cellSize, boardInset);

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x8A010616),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: <Widget>[
                  CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: _BoardPainter(
                      activeTurnColor: widget.state.currentPlayer.color.color,
                    ),
                  ),
                  for (final _PawnRenderData pawn in pawns)
                    AnimatedPositioned(
                      key: ValueKey<String>(pawn.pawn.id),
                      duration: Duration(
                        milliseconds: pawn.pawn.id == _animatingPawnId
                            ? 120
                            : 260,
                      ),
                      curve: Curves.easeOutCubic,
                      left: pawn.offset.dx - (cellSize * 0.37),
                      top: pawn.offset.dy - (cellSize * 0.8),
                      child: GestureDetector(
                        onTap: pawn.isMovable && widget.isLocalPlayersTurn
                            ? () => widget.onPawnTap(pawn.pawn.id)
                            : null,
                        child: _PawnPiece(
                          color: pawn.pawn.color.color,
                          diameter: cellSize * 0.74,
                          highlight:
                              pawn.isMovable && widget.isLocalPlayersTurn,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_PawnRenderData> _buildPawns(double cellSize, double boardInset) {
    final List<_RawPawn> allPawns = <_RawPawn>[];
    for (final Player player in widget.state.players) {
      for (final Pawn pawn in player.pawns) {
        final GridPosition position =
            _displayPositions[pawn.id] ??
            widget.gameService.pawnGridPosition(pawn);

        allPawns.add(
          _RawPawn(
            pawn: pawn,
            position: position,
            isMovable: widget.state.movablePawnIds.contains(pawn.id),
          ),
        );
      }
    }

    final Map<String, List<_RawPawn>> grouped = <String, List<_RawPawn>>{};
    for (final _RawPawn raw in allPawns) {
      final String key = '${raw.position.row}_${raw.position.col}';
      grouped.putIfAbsent(key, () => <_RawPawn>[]).add(raw);
    }

    final List<_PawnRenderData> rendered = <_PawnRenderData>[];
    final List<Offset> pattern = <Offset>[
      Offset.zero,
      const Offset(-0.22, -0.22),
      const Offset(0.22, -0.22),
      const Offset(-0.22, 0.22),
      const Offset(0.22, 0.22),
      const Offset(0.0, -0.32),
      const Offset(0.0, 0.32),
    ];

    for (final MapEntry<String, List<_RawPawn>> entry in grouped.entries) {
      final List<_RawPawn> group = entry.value;
      for (int i = 0; i < group.length; i++) {
        final _RawPawn raw = group[i];
        final Offset shift = pattern[i % pattern.length];

        final Offset baseOffset = Offset(
          boardInset + (raw.position.col + 0.5) * cellSize,
          boardInset + (raw.position.row + 0.5) * cellSize,
        );

        rendered.add(
          _PawnRenderData(
            pawn: raw.pawn,
            offset:
                baseOffset + Offset(shift.dx * cellSize, shift.dy * cellSize),
            isMovable: raw.isMovable,
          ),
        );
      }
    }

    return rendered;
  }

  void _startStepAnimation() {
    final String? pawnId = widget.state.lastMovedPawnId;
    final List<int> pathSteps = widget.state.lastMovedPathSteps;
    if (pawnId == null || pathSteps.length < 2) {
      _lastHandledMoveSerial = widget.state.moveSerial;
      _syncDisplayFromState();
      return;
    }

    final Pawn? movedPawn = _findPawnById(pawnId);
    if (movedPawn == null) {
      _lastHandledMoveSerial = widget.state.moveSerial;
      _syncDisplayFromState();
      return;
    }

    final List<GridPosition> path = pathSteps
        .map(
          (int steps) => widget.gameService.pawnGridPosition(
            Pawn(id: pawnId, color: movedPawn.color, steps: steps),
          ),
        )
        .toList(growable: false);

    if (path.length < 2) {
      _lastHandledMoveSerial = widget.state.moveSerial;
      _syncDisplayFromState();
      return;
    }

    _pathTimer?.cancel();
    _lastHandledMoveSerial = widget.state.moveSerial;

    setState(() {
      _animatingPawnId = pawnId;
      _displayPositions[pawnId] = path.first;
    });

    int index = 0;
    _pathTimer = Timer.periodic(const Duration(milliseconds: 130), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      index++;
      if (index >= path.length) {
        timer.cancel();
        _finishAnimation();
        return;
      }

      setState(() {
        _displayPositions[pawnId] = path[index];
      });
    });
  }

  void _finishAnimation() {
    if (!mounted) {
      return;
    }

    setState(() {
      _animatingPawnId = null;
      _syncDisplayFromState();
    });
  }

  void _syncDisplayFromState() {
    for (final Player player in widget.state.players) {
      for (final Pawn pawn in player.pawns) {
        _displayPositions[pawn.id] = widget.gameService.pawnGridPosition(pawn);
      }
    }
  }

  void _removeMissingPawns() {
    final Set<String> validPawnIds = <String>{
      for (final Player player in widget.state.players)
        for (final Pawn pawn in player.pawns) pawn.id,
    };

    _displayPositions.removeWhere((String key, GridPosition value) {
      return !validPawnIds.contains(key);
    });
  }

  Pawn? _findPawnById(String pawnId) {
    for (final Player player in widget.state.players) {
      for (final Pawn pawn in player.pawns) {
        if (pawn.id == pawnId) {
          return pawn;
        }
      }
    }
    return null;
  }
}

class _RawPawn {
  const _RawPawn({
    required this.pawn,
    required this.position,
    required this.isMovable,
  });

  final Pawn pawn;
  final GridPosition position;
  final bool isMovable;
}

class _PawnRenderData {
  const _PawnRenderData({
    required this.pawn,
    required this.offset,
    required this.isMovable,
  });

  final Pawn pawn;
  final Offset offset;
  final bool isMovable;
}

class _PawnPiece extends StatefulWidget {
  const _PawnPiece({
    required this.color,
    required this.diameter,
    required this.highlight,
  });

  final Color color;
  final double diameter;
  final bool highlight;

  @override
  State<_PawnPiece> createState() => _PawnPieceState();
}

class _PawnPieceState extends State<_PawnPiece>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    if (widget.highlight) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PawnPiece oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.highlight && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double pulse = 1 + (_controller.value * 0.08);

        return Transform.scale(
          scale: widget.highlight ? pulse : 1,
          child: SizedBox(
            width: widget.diameter,
            height: widget.diameter * 1.4,
            child: CustomPaint(
              painter: _PawnPainter(
                color: widget.color,
                highlight: widget.highlight,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PawnPainter extends CustomPainter {
  _PawnPainter({required this.color, required this.highlight});
  final Color color;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Color darkColor = Color.lerp(color, Colors.black, 0.4)!;
    final Color lightColor = Color.lerp(color, Colors.white, 0.6)!;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.95), width: w * 0.8, height: h * 0.25),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    if (highlight) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.95), width: w * 1.2, height: h * 0.4),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Gradient for the cylindrical/spherical parts
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [darkColor, color, lightColor, color, darkColor],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Base bottom
    final Path basePath = Path()
      ..moveTo(w * 0.15, h * 0.85)
      ..quadraticBezierTo(w * 0.5, h * 1.0, w * 0.85, h * 0.85)
      ..lineTo(w * 0.85, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h * 0.9, w * 0.15, h * 0.75)
      ..close();
    canvas.drawPath(basePath, basePaint);

    // Body (stem)
    final Path bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.75)
      ..quadraticBezierTo(w * 0.4, h * 0.5, w * 0.4, h * 0.4)
      ..lineTo(w * 0.6, h * 0.4)
      ..quadraticBezierTo(w * 0.6, h * 0.5, w * 0.75, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.25, h * 0.75)
      ..close();
    canvas.drawPath(bodyPath, basePaint);

    // Collar
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.4), width: w * 0.5, height: h * 0.15),
      basePaint,
    );

    // Head
    final Paint headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [lightColor, color, darkColor],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.25), width: w * 0.5, height: h * 0.5));

    canvas.drawCircle(Offset(w * 0.5, h * 0.25), w * 0.25, headPaint);

    // Head highlight reflection
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.4, h * 0.15), width: w * 0.15, height: h * 0.1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PawnPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.highlight != highlight;
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.activeTurnColor});

  static const double frameFraction = 0.05;

  final Color activeTurnColor;

  static const Color _frameLight = Color(0xFFF3B182);
  static const Color _frameDark = Color(0xFF945029);
  static const Color _gridColor = Color(0x5F7A7D86);
  static const Color _trackWhite = Color(0xFFFDFDFD);
  static const Color _safeTile = Color(0xFFE9EFF7);
  static const Color _red = Color(0xFFEB3D3D);
  static const Color _green = Color(0xFF21B44B);
  static const Color _yellow = Color(0xFFF2C51D);
  static const Color _blue = Color(0xFF25A8F1);

  @override
  void paint(Canvas canvas, Size size) {
    final double inset = size.width * frameFraction;
    final Rect inner = Rect.fromLTWH(
      inset,
      inset,
      size.width - (inset * 2),
      size.height - (inset * 2),
    );
    final double cell = inner.width / BoardConstants.boardSize;

    _drawFrame(canvas, size, inner);

    canvas.drawRect(inner, Paint()..color = _trackWhite);

    _drawQuadrants(canvas, inner, cell);
    _drawHomeLanes(canvas, inner, cell);
    _drawCenterDiamond(canvas, inner, cell);
    _drawYardTargets(canvas, inner, cell);
    _drawSafeMarkers(canvas, inner, cell);
    _drawStartMarkers(canvas, inner, cell);
    _drawDirectionalHints(canvas, inner, cell);
    _drawGrid(canvas, inner, cell);
    _drawTurnGlow(canvas, inner);
  }

  void _drawFrame(Canvas canvas, Size size, Rect inner) {
    final RRect outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.08),
    );

    final Paint body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[_frameLight, Color(0xFFE29E68), _frameDark],
      ).createShader(outer.outerRect);

    canvas.drawRRect(outer, body);
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.018
        ..color = const Color(0xFF7B3F1D),
    );

    canvas.drawRRect(
      outer.deflate(size.width * 0.02),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.007
        ..color = const Color(0x55FFFFFF),
    );

    final Rect glossRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.42);
    canvas.saveLayer(outer.outerRect, Paint());
    canvas.clipRRect(outer);
    canvas.drawRect(
      glossRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x55FFFFFF), Color(0x00FFFFFF)],
        ).createShader(glossRect),
    );
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(size.width * 0.018)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.0035
        ..color = const Color(0x66000000),
    );
  }

  void _drawQuadrants(Canvas canvas, Rect inner, double cell) {
    _fillZone(
      canvas,
      _cells(inner, cell, row: 0, col: 0, rows: 6, cols: 6),
      _red,
    );
    _fillZone(
      canvas,
      _cells(inner, cell, row: 0, col: 9, rows: 6, cols: 6),
      _green,
    );
    _fillZone(
      canvas,
      _cells(inner, cell, row: 9, col: 0, rows: 6, cols: 6),
      _blue,
    );
    _fillZone(
      canvas,
      _cells(inner, cell, row: 9, col: 9, rows: 6, cols: 6),
      _yellow,
    );
  }

  void _fillZone(Canvas canvas, Rect rect, Color color) {
    // Base quadrant background
    canvas.drawRect(rect, Paint()..color = color);

    // Inner prison area
    final double cell = rect.width / 6;
    final Rect innerRect = rect.deflate(cell * 0.9);
    final RRect rrect = RRect.fromRectAndRadius(innerRect, Radius.circular(cell * 0.6));
    
    final Color darkerColor = Color.lerp(color, Colors.black, 0.2)!;

    canvas.drawRRect(rrect, Paint()..color = darkerColor);

    // Debossed edge effect
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.black.withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      rrect.deflate(2.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.2),
    );

    // Overall quadrant lighting
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.24),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.10),
          ],
          stops: const <double>[0, 0.55, 1],
        ).createShader(rect),
    );
  }

  void _drawHomeLanes(Canvas canvas, Rect inner, double cell) {
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
        _cells(inner, cell, row: 7, col: 1 + i),
        Paint()..color = _red.withValues(alpha: 0.94),
      );
      canvas.drawRect(
        _cells(inner, cell, row: 1 + i, col: 7),
        Paint()..color = _green.withValues(alpha: 0.94),
      );
      canvas.drawRect(
        _cells(inner, cell, row: 7, col: 13 - i),
        Paint()..color = _yellow.withValues(alpha: 0.94),
      );
      canvas.drawRect(
        _cells(inner, cell, row: 13 - i, col: 7),
        Paint()..color = _blue.withValues(alpha: 0.94),
      );
    }
  }

  void _drawCenterDiamond(Canvas canvas, Rect inner, double cell) {
    final Rect coreRect = _cells(inner, cell, row: 6, col: 6, rows: 3, cols: 3);
    final Offset top = Offset(coreRect.center.dx, coreRect.top);
    final Offset right = Offset(coreRect.right, coreRect.center.dy);
    final Offset bottom = Offset(coreRect.center.dx, coreRect.bottom);
    final Offset left = Offset(coreRect.left, coreRect.center.dy);
    final Offset center = coreRect.center;

    final Path up = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(center.dx, center.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    final Path rightPath = Path()
      ..moveTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path down = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path leftPath = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(top.dx, top.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(up, Paint()..color = _green);
    canvas.drawPath(rightPath, Paint()..color = _yellow);
    canvas.drawPath(down, Paint()..color = _blue);
    canvas.drawPath(leftPath, Paint()..color = _red);

    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(left.dx, left.dy)
        ..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.12
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _drawYardTargets(Canvas canvas, Rect inner, double cell) {
    for (final MapEntry<PlayerColor, List<GridPosition>> entry
        in BoardConstants.yardPositions.entries) {
      final Color color = _colorForPlayer(entry.key);
      for (final GridPosition position in entry.value) {
        final Rect rect = _cells(
          inner,
          cell,
          row: position.row,
          col: position.col,
        );
        final Offset center = rect.center;
        canvas.drawCircle(
          center,
          cell * 0.33,
          Paint()..color = Colors.white.withValues(alpha: 0.65),
        );
        canvas.drawCircle(
          center,
          cell * 0.26,
          Paint()..color = color.withValues(alpha: 0.78),
        );
        canvas.drawCircle(
          center,
          cell * 0.14,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }
  }

  void _drawStartMarkers(Canvas canvas, Rect inner, double cell) {
    final Map<PlayerColor, GridPosition> starts = <PlayerColor, GridPosition>{
      PlayerColor.red: BoardConstants.track[0],
      PlayerColor.green: BoardConstants.track[13],
      PlayerColor.yellow: BoardConstants.track[26],
      PlayerColor.blue: BoardConstants.track[39],
    };

    for (final MapEntry<PlayerColor, GridPosition> entry in starts.entries) {
      final Rect rect = _cells(
        inner,
        cell,
        row: entry.value.row,
        col: entry.value.col,
      );
      final Offset c = rect.center;
      final Color color = _colorForPlayer(entry.key);
      final Offset direction = _directionForPlayer(entry.key);

      canvas.drawCircle(
        c,
        cell * 0.26,
        Paint()..color = color.withValues(alpha: 0.92),
      );
      canvas.drawCircle(
        c,
        cell * 0.24,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.06
          ..color = Colors.white.withValues(alpha: 0.82),
      );

      final Offset tip =
          c + Offset(direction.dx * cell * 0.17, direction.dy * cell * 0.17);
      final Offset tail =
          c - Offset(direction.dx * cell * 0.14, direction.dy * cell * 0.14);
      final Offset side = Offset(-direction.dy, direction.dx) * (cell * 0.12);

      final Path arrow = Path();
      arrow
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tail.dx + side.dx, tail.dy + side.dy)
        ..lineTo(tail.dx - side.dx, tail.dy - side.dy)
        ..close();

      canvas.drawPath(arrow, Paint()..color = Colors.white);
    }
  }

  void _drawSafeMarkers(Canvas canvas, Rect inner, double cell) {
    for (final int safeIndex in BoardConstants.safeTrackIndices) {
      final GridPosition p = BoardConstants.track[safeIndex];
      final Rect rect = _cells(inner, cell, row: p.row, col: p.col);
      canvas.drawRect(rect.deflate(cell * 0.05), Paint()..color = _safeTile);

      final Offset center = rect.center;
      final Path star = _buildStar(
        center: center,
        outerRadius: cell * 0.18,
        points: 5,
      );
      canvas.drawPath(star, Paint()..color = const Color(0xFF8A8A8A));
    }
  }

  void _drawDirectionalHints(Canvas canvas, Rect inner, double cell) {
    _drawArrowHint(
      canvas,
      _cells(inner, cell, row: 7, col: 4).center,
      const Offset(1, 0),
      cell,
    );
    _drawArrowHint(
      canvas,
      _cells(inner, cell, row: 4, col: 7).center,
      const Offset(0, 1),
      cell,
    );
    _drawArrowHint(
      canvas,
      _cells(inner, cell, row: 7, col: 10).center,
      const Offset(-1, 0),
      cell,
    );
    _drawArrowHint(
      canvas,
      _cells(inner, cell, row: 10, col: 7).center,
      const Offset(0, -1),
      cell,
    );
  }

  void _drawArrowHint(
    Canvas canvas,
    Offset center,
    Offset direction,
    double cell,
  ) {
    final Offset side = Offset(-direction.dy, direction.dx);
    final Offset tip = center + (direction * (cell * 0.18));
    final Offset tail = center - (direction * (cell * 0.10));

    final Path arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tail.dx + (side.dx * cell * 0.14),
        tail.dy + (side.dy * cell * 0.14),
      )
      ..lineTo(
        tail.dx - (side.dx * cell * 0.14),
        tail.dy - (side.dy * cell * 0.14),
      )
      ..close();

    canvas.drawPath(
      arrow,
      Paint()..color = Colors.white.withValues(alpha: 0.84),
    );
  }

  void _drawGrid(Canvas canvas, Rect inner, double cell) {
    final Paint stroke = Paint()
      ..color = _gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.72;

    for (int i = 0; i <= BoardConstants.boardSize; i++) {
      final double x = inner.left + (i * cell);
      final double y = inner.top + (i * cell);

      if (i > 0 && i < 6 || i > 9 && i < 15) {
        // Vertical lines in the left/right sections
        canvas.drawLine(
          Offset(x, inner.top + 6 * cell),
          Offset(x, inner.top + 9 * cell),
          stroke,
        );
        // Horizontal lines in the top/bottom sections
        canvas.drawLine(
          Offset(inner.left + 6 * cell, y),
          Offset(inner.left + 9 * cell, y),
          stroke,
        );
      } else {
        // Full lines for borders and center cross
        canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), stroke);
        canvas.drawLine(Offset(inner.left, y), Offset(inner.right, y), stroke);
      }
    }
  }

  void _drawTurnGlow(Canvas canvas, Rect inner) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = inner.width * 0.01
      ..color = activeTurnColor.withValues(alpha: 0.63);

    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(inner.width * 0.01)),
      paint,
    );
  }

  Rect _cells(
    Rect inner,
    double cell, {
    required int row,
    required int col,
    int rows = 1,
    int cols = 1,
  }) {
    return Rect.fromLTWH(
      inner.left + (col * cell),
      inner.top + (row * cell),
      cell * cols,
      cell * rows,
    );
  }

  Path _buildStar({
    required Offset center,
    required double outerRadius,
    required int points,
  }) {
    final double innerRadius = outerRadius * 0.45;
    final Path path = Path();

    for (int i = 0; i < points * 2; i++) {
      final bool outer = i.isEven;
      final double radius = outer ? outerRadius : innerRadius;
      final double angle = (i * math.pi / points) - math.pi / 2;
      final Offset p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    path.close();
    return path;
  }

  Color _colorForPlayer(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return _red;
      case PlayerColor.green:
        return _green;
      case PlayerColor.yellow:
        return _yellow;
      case PlayerColor.blue:
        return _blue;
    }
  }

  Offset _directionForPlayer(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const Offset(1, 0);
      case PlayerColor.green:
        return const Offset(0, 1);
      case PlayerColor.yellow:
        return const Offset(-1, 0);
      case PlayerColor.blue:
        return const Offset(0, -1);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.activeTurnColor != activeTurnColor;
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'effects.dart';
import 'game_map.dart';
import 'ghost.dart';

class GamePainter extends CustomPainter {
  final double pacmanX;
  final double pacmanY;

  /// Ángulo actual hacia donde mira Pac-Man (en radianes, ya suavizado).
  final double facingAngle;

  /// 0 = boca casi cerrada, 1 = boca completamente abierta.
  final double mouthOpenness;

  /// 0 = vivo. Entre 0 y 1 = animación de muerte en progreso.
  final double dyingProgress;

  final List<Ghost> ghosts;
  final int frightenedMsRemaining;
  final int level;
  final int fruitMsRemaining;
  final List<Particle> particles;
  final List<FloatingText> floatingTexts;

  GamePainter({
    required this.pacmanX,
    required this.pacmanY,
    required this.facingAngle,
    required this.mouthOpenness,
    required this.dyingProgress,
    required this.ghosts,
    required this.frightenedMsRemaining,
    required this.level,
    required this.fruitMsRemaining,
    required this.particles,
    required this.floatingTexts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / kMapWidth;
    final cellHeight = size.height / kMapHeight;

    // Fondo negro
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // Dibujar el mapa
    for (int y = 0; y < kMapHeight; y++) {
      for (int x = 0; x < kMapWidth; x++) {
        final rect = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );

        switch (GameMap.layout[y][x]) {
          case 1: // Pared
            final wallPaint = Paint()..color = kWallColor;
            canvas.drawRect(rect, wallPaint);

            final borderPaint = Paint()..color = kWallBorderColor;
            canvas.drawRect(
              Rect.fromLTWH(rect.left, rect.top, rect.width, 2),
              borderPaint,
            );
            canvas.drawRect(
              Rect.fromLTWH(rect.left, rect.top, 2, rect.height),
              borderPaint,
            );
            break;

          case 2: // Punto normal
            canvas.drawCircle(
              rect.center,
              cellWidth * 0.1,
              Paint()..color = kDotColor,
            );
            break;

          case 3: // Fruta (power-up), aparece y desaparece dinámicamente
            final flashing =
                fruitMsRemaining > 0 &&
                fruitMsRemaining < kFruitFlashStartMs &&
                (fruitMsRemaining ~/ 150) % 2 == 0;
            if (!flashing) {
              _drawFruit(canvas, rect.center, cellWidth, cellHeight);
            }
            break;

          case 5: // Pared intermitente (trampa)
            _drawTrapWall(canvas, rect);
            break;

          case 6: // Teletransportador, extremo A
            _drawPortal(canvas, rect, Colors.cyanAccent);
            break;

          case 7: // Teletransportador, extremo B
            _drawPortal(canvas, rect, Colors.orangeAccent);
            break;
        }
      }
    }

    // Durante la animación de muerte los fantasmas se ocultan.
    if (dyingProgress == 0) {
      _drawGhosts(canvas, cellWidth, cellHeight);
    }
    _drawPacman(canvas, cellWidth, cellHeight);
    _drawParticles(canvas, cellWidth, cellHeight);
    _drawFloatingTexts(canvas, cellWidth, cellHeight);
  }

  void _drawFruit(
    Canvas canvas,
    Offset center,
    double cellWidth,
    double cellHeight,
  ) {
    final color = kFruitColors[(level - 1) % kFruitColors.length];
    final radius = cellWidth * 0.22;

    // Brillo suave detrás de la fruta
    final glow = Paint()
      ..color = color.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, radius * 1.3, glow);

    // Cuerpo de la fruta
    canvas.drawCircle(center, radius, Paint()..color = color);

    // Brillito (highlight)
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
      radius * 0.25,
      Paint()..color = Colors.white.withAlpha(140),
    );

    // Tallo
    final stemPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = cellWidth * 0.05
      ..strokeCap = StrokeCap.round;
    final stemStart = Offset(center.dx, center.dy - radius);
    final stemEnd = Offset(
      center.dx + cellWidth * 0.06,
      center.dy - radius - cellHeight * 0.14,
    );
    canvas.drawLine(stemStart, stemEnd, stemPaint);

    // Hoja
    final leafPaint = Paint()..color = Colors.green;
    final leafPath = Path()
      ..moveTo(stemEnd.dx, stemEnd.dy)
      ..quadraticBezierTo(
        stemEnd.dx + cellWidth * 0.18,
        stemEnd.dy - cellHeight * 0.04,
        stemEnd.dx + cellWidth * 0.02,
        stemEnd.dy + cellHeight * 0.09,
      )
      ..close();
    canvas.drawPath(leafPath, leafPaint);
  }

  void _drawTrapWall(Canvas canvas, Rect rect) {
    if (GameMap.trapWallsOpen) {
      // Pasaje abierto: contorno tenue que marca dónde vuelve a cerrarse.
      canvas.drawRect(
        rect.deflate(rect.width * 0.08),
        Paint()
          ..color = const Color(0xFFCE93D8).withAlpha(90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      canvas.drawRect(rect, Paint()..color = const Color(0xFF4A148C));
      final borderPaint = Paint()..color = const Color(0xFFCE93D8);
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, 2),
        borderPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, 2, rect.height),
        borderPaint,
      );
    }
  }

  void _drawPortal(Canvas canvas, Rect rect, Color color) {
    final t = DateTime.now().millisecondsSinceEpoch / 300.0;
    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final r = rect.width * 0.5 * phase;
      final alpha = ((1 - phase) * 200).round();
      canvas.drawCircle(
        rect.center,
        r,
        Paint()
          ..color = color.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(rect.center, rect.width * 0.12, Paint()..color = color);
  }

  // ---------------------------------------------------------------------
  // Pac-Man
  // ---------------------------------------------------------------------

  void _drawPacman(Canvas canvas, double cellWidth, double cellHeight) {
    final center = Offset(
      (pacmanX + 0.5) * cellWidth,
      (pacmanY + 0.5) * cellHeight,
    );
    final baseRadius = min(cellWidth, cellHeight) * 0.47;
    final dying = dyingProgress > 0;

    double radius = baseRadius;
    double angle = facingAngle;
    double mouthHalf;
    int alpha = 255;

    if (dying) {
      // Muerte: gira una vuelta completa mientras la boca se abre hasta que
      // el cuerpo desaparece, y se va desvaneciendo al final.
      final p = min(1.0, dyingProgress);
      mouthHalf = p * pi * 0.97;
      angle = -pi / 2 + p * pi * 2;
      radius = baseRadius * (1 - 0.3 * p);
      final fade = p < 0.7 ? 1.0 : max(0.0, 1 - (p - 0.7) / 0.3);
      alpha = (255 * fade).round();
    } else {
      mouthHalf = 0.04 + mouthOpenness * 0.62;
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    // Resplandor suave alrededor de Pac-Man
    if (!dying) {
      final glow = Paint()
        ..color = kPacmanColor.withAlpha(50)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35);
      canvas.drawCircle(Offset.zero, radius * 1.25, glow);
    }

    // Cuerpo con degradado radial (luz arriba a la izquierda). La rotación
    // inversa del degradado mantiene la luz fija aunque el cuerpo gire.
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.0,
        colors: const [Color(0xFFFFF9C4), Colors.yellow, Color(0xFFFFA000)],
        stops: const [0.0, 0.55, 1.0],
        transform: GradientRotation(-angle),
      ).createShader(rect);

    if (dying) {
      bodyPaint.colorFilter = ColorFilter.mode(
        Color.fromARGB(alpha, 255, 255, 255),
        BlendMode.modulate,
      );
    }

    canvas.drawArc(rect, mouthHalf, 2 * pi - mouthHalf * 2, true, bodyPaint);
    canvas.restore();

    // Ojo (se dibuja sin rotar). Su posición depende de hacia dónde mira
    // Pac-Man para que nunca quede metido en la boca:
    //  - mirando a los lados o hacia abajo: arriba, un poco hacia el frente;
    //  - mirando hacia arriba: a un costado, a media altura.
    if (!dying) {
      final cosA = cos(facingAngle);
      final sinA = sin(facingAngle);
      final u = max(0.0, -sinA); // 0 = no mira hacia arriba, 1 = de lleno
      final ex = 0.25 * cosA + 1.0 * u;
      final ey = 0.25 * sinA - 0.85 * (1 - u) + 0.16 * u;
      final eyeCenter = center + Offset(ex, ey) * (radius * 0.55);

      canvas.drawCircle(eyeCenter, radius * 0.2, Paint()..color = kEyeColor);
      canvas.drawCircle(
        eyeCenter + Offset(-radius * 0.06, -radius * 0.07),
        radius * 0.06,
        Paint()..color = Colors.white.withAlpha(210),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Efectos
  // ---------------------------------------------------------------------

  void _drawParticles(Canvas canvas, double cellWidth, double cellHeight) {
    for (final p in particles) {
      final fade = 1 - p.progress;
      final paint = Paint()..color = p.color.withAlpha((255 * fade).round());
      canvas.drawCircle(
        Offset(p.x * cellWidth, p.y * cellHeight),
        p.size * cellWidth * (1 - 0.5 * p.progress),
        paint,
      );
    }
  }

  void _drawFloatingTexts(Canvas canvas, double cellWidth, double cellHeight) {
    for (final t in floatingTexts) {
      final p = t.progress;
      final alpha = p < 0.5 ? 255 : (255 * (1 - (p - 0.5) / 0.5)).round();
      // Pequeño "pop": el texto aparece un poco chico y crece rápido.
      final pop = p < 0.15 ? 0.7 + (p / 0.15) * 0.4 : 1.1 - (p - 0.15) * 0.1;

      final painter = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            color: t.color.withAlpha(alpha),
            fontSize: cellWidth * 0.42 * t.scale * pop,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black.withAlpha(alpha), blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          t.x * cellWidth - painter.width / 2,
          t.y * cellHeight - painter.height / 2,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Fantasmas
  // ---------------------------------------------------------------------

  void _drawGhosts(Canvas canvas, double cellWidth, double cellHeight) {
    // La falda alterna entre dos formas para dar sensación de ondulación.
    final wavePhase = (DateTime.now().millisecondsSinceEpoch ~/ 160) % 2;

    for (final ghost in ghosts) {
      if (!ghost.isAlive) continue;

      final rect = Rect.fromLTWH(
        ghost.x * cellWidth,
        ghost.y * cellHeight,
        cellWidth,
        cellHeight,
      );

      Color bodyColor = ghost.color;
      if (ghost.mode == GhostMode.frightened) {
        final flashing =
            frightenedMsRemaining < kFrightenedFlashStartMs &&
            (frightenedMsRemaining ~/ 200) % 2 == 0;
        bodyColor = flashing
            ? kFrightenedGhostFlashColor
            : kFrightenedGhostColor;
      }

      final paint = Paint()..color = bodyColor;
      final path = Path();
      final left = rect.left + rect.width * 0.08;
      final right = rect.right - rect.width * 0.08;
      final top = rect.top + rect.height * 0.1;
      final bottom = rect.bottom - rect.height * 0.08;
      final radius = (right - left) / 2;

      // Cabeza redondeada
      path.moveTo(left, bottom);
      path.arcTo(
        Rect.fromCircle(
          center: Offset(rect.center.dx, top + radius),
          radius: radius,
        ),
        pi,
        pi,
        false,
      );
      path.lineTo(right, bottom);

      // Base ondulada (la "falda" clásica del fantasma), animada.
      const waveCount = 3;
      final waveWidth = (right - left) / (waveCount * 2);
      for (int i = 0; i < waveCount * 2; i++) {
        final dx = right - waveWidth * (i + 1);
        final high = (i + wavePhase) % 2 == 0;
        final dy = high ? bottom - rect.height * 0.12 : bottom;
        path.lineTo(dx, dy);
      }
      path.close();
      canvas.drawPath(path, paint);

      // Ojos
      if (ghost.mode != GhostMode.frightened) {
        final eyeWhite = Paint()..color = Colors.white;
        final eyeLeft = Offset(
          rect.center.dx - cellWidth * 0.15,
          rect.center.dy - cellHeight * 0.05,
        );
        final eyeRight = Offset(
          rect.center.dx + cellWidth * 0.15,
          rect.center.dy - cellHeight * 0.05,
        );
        canvas.drawCircle(eyeLeft, cellWidth * 0.09, eyeWhite);
        canvas.drawCircle(eyeRight, cellWidth * 0.09, eyeWhite);

        final pupilPaint = Paint()..color = Colors.black;
        final pupilOffset = _pupilOffsetFor(ghost.direction, cellWidth);
        canvas.drawCircle(eyeLeft + pupilOffset, cellWidth * 0.045, pupilPaint);
        canvas.drawCircle(
          eyeRight + pupilOffset,
          cellWidth * 0.045,
          pupilPaint,
        );
      } else {
        final eyeWhite = Paint()..color = Colors.white;
        canvas.drawCircle(
          Offset(rect.center.dx - cellWidth * 0.15, rect.center.dy),
          cellWidth * 0.06,
          eyeWhite,
        );
        canvas.drawCircle(
          Offset(rect.center.dx + cellWidth * 0.15, rect.center.dy),
          cellWidth * 0.06,
          eyeWhite,
        );
      }
    }
  }

  Offset _pupilOffsetFor(String direction, double cellWidth) {
    final d = cellWidth * 0.03;
    switch (direction) {
      case 'left':
        return Offset(-d, 0);
      case 'right':
        return Offset(d, 0);
      case 'up':
        return Offset(0, -d);
      case 'down':
        return Offset(0, d);
      default:
        return Offset.zero;
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    // Siempre repintar: hay animación continua (Pac-Man, fantasmas, efectos).
    return true;
  }
}

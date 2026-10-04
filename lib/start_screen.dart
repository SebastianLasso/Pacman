import 'dart:math';

import 'package:flutter/material.dart';

import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedPacman(controller: _controller),
              const SizedBox(height: 24),
              const Text(
                'PAC-MAN',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Come todos los puntos y atrapa a los fantasmas',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.yellow, width: 2),
                  ),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Usa las flechas del teclado para moverte',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pac-Man animado abriendo y cerrando la boca, decoración de la pantalla
/// de bienvenida.
class _AnimatedPacman extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedPacman({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 80),
          painter: _PacmanIconPainter(mouthOpen: controller.value),
        );
      },
    );
  }
}

class _PacmanIconPainter extends CustomPainter {
  final double mouthOpen;

  _PacmanIconPainter({required this.mouthOpen});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..color = Colors.yellow;

    final mouthAngle = 0.05 + mouthOpen * 0.35;
    canvas.drawArc(rect, mouthAngle, 2 * pi - (mouthAngle * 2), true, paint);
  }

  @override
  bool shouldRepaint(covariant _PacmanIconPainter oldDelegate) {
    return oldDelegate.mouthOpen != mouthOpen;
  }
}

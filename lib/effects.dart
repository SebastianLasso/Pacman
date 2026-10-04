import 'dart:math';

import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  final double vx;
  final double vy;
  final Color color;
  final int lifeMs;
  final double size;
  int ageMs = 0;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.lifeMs,
    required this.size,
  });

  double get progress => (ageMs / lifeMs).clamp(0.0, 1.0);
  bool get isDead => ageMs >= lifeMs;

  void update(int deltaMs) {
    final dt = deltaMs / 1000;
    x += vx * dt;
    y += vy * dt;
    ageMs += deltaMs;
  }

  static List<Particle> burst(
    Random random, {
    required double cellX,
    required double cellY,
    required Color color,
    required int count,
    required double speed,
    required int lifeMs,
    required double size,
  }) {
    return List.generate(count, (_) {
      final angle = random.nextDouble() * 2 * pi;
      final particleSpeed = speed * (0.65 + random.nextDouble() * 0.7);
      return Particle(
        x: cellX + 0.5,
        y: cellY + 0.5,
        vx: cos(angle) * particleSpeed,
        vy: sin(angle) * particleSpeed,
        color: color,
        lifeMs: lifeMs,
        size: size * (0.75 + random.nextDouble() * 0.5),
      );
    });
  }
}

class FloatingText {
  double x;
  double y;
  final String text;
  final Color color;
  final double scale;
  final int lifeMs;
  int ageMs = 0;

  FloatingText({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.scale,
    required this.lifeMs,
  });

  double get progress => (ageMs / lifeMs).clamp(0.0, 1.0);
  bool get isDead => ageMs >= lifeMs;

  void update(int deltaMs) {
    y -= deltaMs / 1000 * 0.35;
    ageMs += deltaMs;
  }
}

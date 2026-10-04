import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_map.dart';

enum GhostMode { normal, frightened }

class Ghost {
  double x;
  double y;
  String direction;
  final Color color;
  final double startX;
  final double startY;

  /// Si es true, este fantasma persigue activamente a Pac-Man.
  /// Si es false, se mueve de forma semi-aleatoria (con cierta probabilidad
  /// de acercarse), lo que da variedad al comportamiento del grupo.
  final bool chaser;

  GhostMode mode = GhostMode.normal;

  /// Se marca en true la primera vez que Pac-Man se lo come estando
  /// asustado. Se usa para saber si ya se completó el nivel (hay que
  /// comerse a todos los fantasmas al menos una vez).
  bool eatenThisLevel = false;

  /// Un fantasma comido desaparece y no vuelve hasta que termina el nivel.
  bool get isAlive => !eatenThisLevel;

  /// Velocidades (celdas por segundo), configurables desde afuera según
  /// la dificultad del nivel actual.
  double normalSpeed = kGhostSpeed;
  double frightenedSpeed = kFrightenedGhostSpeed;

  /// Evita que un teletransportador rebote al fantasma de un lado a otro
  /// sin parar apenas llega.
  int teleportCooldownMs = 0;

  static final Random _rand = Random();

  static const Map<String, String> _opposite = {
    'up': 'down',
    'down': 'up',
    'left': 'right',
    'right': 'left',
  };

  static const Map<String, List<int>> _deltas = {
    'up': [0, -1],
    'down': [0, 1],
    'left': [-1, 0],
    'right': [1, 0],
  };

  Ghost({
    required this.startX,
    required this.startY,
    required this.color,
    this.direction = 'up',
    this.chaser = false,
  })  : x = startX,
        y = startY;

  /// Reaparece en su punto de origen. No borra `eatenThisLevel`: perder una
  /// vida no debe hacerte perder el progreso de fantasmas ya atrapados.
  /// Devuelve al fantasma a su punto de origen (por ejemplo, después de que
  /// Pac-Man pierde una vida). No lo "revive": si ya fue comido en este
  /// nivel, sigue eliminado.
  void reset() {
    x = startX;
    y = startY;
    direction = 'up';
    mode = GhostMode.normal;
    teleportCooldownMs = 0;
  }

  /// Pac-Man se comió al fantasma: queda eliminado hasta que termine el nivel.
  void defeat() {
    eatenThisLevel = true;
    x = startX;
    y = startY;
    direction = 'up';
    mode = GhostMode.normal;
  }

  List<String> _openDirections(int gx, int gy, {bool allowReverse = false}) {
    final dirs = <String>[];
    for (final d in _deltas.keys) {
      if (!allowReverse && d == _opposite[direction]) continue;
      final delta = _deltas[d]!;
      if (!GameMap.isWall(gx + delta[0], gy + delta[1])) {
        dirs.add(d);
      }
    }
    // Si es un callejón sin salida, se permite retroceder.
    if (dirs.isEmpty && !allowReverse) {
      return _openDirections(gx, gy, allowReverse: true);
    }
    return dirs;
  }

  String _chooseDirection(List<String> options, double pacmanX, double pacmanY) {
    if (mode == GhostMode.frightened) {
      return options[_rand.nextInt(options.length)];
    }

    final shouldChase = chaser || _rand.nextDouble() < 0.35;
    if (!shouldChase) {
      return options[_rand.nextInt(options.length)];
    }

    String best = options.first;
    double bestDist = double.infinity;
    for (final d in options) {
      final delta = _deltas[d]!;
      final nx = x.round() + delta[0];
      final ny = y.round() + delta[1];
      final dist = (nx - pacmanX) * (nx - pacmanX) + (ny - pacmanY) * (ny - pacmanY);
      if (dist < bestDist) {
        bestDist = dist;
        best = d;
      }
    }
    return best;
  }

  void update(double dt, double pacmanX, double pacmanY) {
    if (!isAlive) return;
    if (teleportCooldownMs > 0) teleportCooldownMs -= (dt * 1000).round();

    final speed = mode == GhostMode.frightened ? frightenedSpeed : normalSpeed;
    final step = speed * dt;

    final gx = x.round();
    final gy = y.round();
    final centered = (x - gx).abs() < step / 2 && (y - gy).abs() < step / 2;

    if (centered) {
      x = gx.toDouble();
      y = gy.toDouble();

      if (teleportCooldownMs <= 0) {
        final dest = GameMap.otherTeleporterFor(gx, gy);
        if (dest != null) {
          x = dest[0].toDouble();
          y = dest[1].toDouble();
          teleportCooldownMs = 500;
          return; // este frame ya se usó para teletransportarse
        }
      }

      final options = _openDirections(gx, gy);
      direction = _chooseDirection(options, pacmanX, pacmanY);
    }

    final delta = _deltas[direction]!;
    x += delta[0] * step;
    y += delta[1] * step;
  }
}
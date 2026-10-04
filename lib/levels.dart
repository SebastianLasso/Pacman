import 'constants.dart';

/// Define los mapas disponibles y cómo escala la dificultad con el nivel.
class Levels {
  Levels._();

  // Los 3 mapas rotan: nivel 1 usa el mapa 0, nivel 2 el mapa 1, nivel 3 el
  // mapa 2, nivel 4 vuelve al mapa 0 (pero más difícil), y así sucesivamente.
  //
  // Valores de celda: 1 = pared, 2 = punto normal. Ya no hay frutas (3) fijas
  // en el mapa: aparecen dinámicamente durante la partida (ver game_screen.dart).
  static const List<List<List<int>>> _layouts = [
    // Mapa 1: laberinto clásico.
    [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1],
      [1, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1],
      [1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ],
    // Mapa 2: mismo estilo, invertido verticalmente (recorrido distinto).
    [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1],
      [1, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1],
      [1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ],
    // Mapa 3: sala abierta con un obstáculo central.
    [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    ],
  ];

  static int get mapCount => _layouts.length;

  /// Devuelve una copia nueva (mutable) del layout que le toca a este nivel.
  static List<List<int>> layoutForLevel(int level) {
    final base = _layouts[(level - 1) % _layouts.length];
    return base.map((row) => List<int>.from(row)).toList();
  }

  // -------------------------------------------------------------------
  // Escalado de dificultad. Todos los valores están acotados (clamped)
  // para que el juego siga siendo jugable en niveles muy altos.
  // -------------------------------------------------------------------

  static double ghostSpeedForLevel(int level) {
    final speed = kGhostSpeed + (level - 1) * 0.2;
    return speed.clamp(kGhostSpeed, kGhostSpeed + 1.6);
  }

  static double frightenedSpeedForLevel(int level) {
    final speed = kFrightenedGhostSpeed + (level - 1) * 0.1;
    return speed.clamp(kFrightenedGhostSpeed, kFrightenedGhostSpeed + 0.8);
  }

  static int frightenedDurationForLevel(int level) {
    final duration = kFrightenedDurationMs - (level - 1) * 400;
    return duration.clamp(2000, kFrightenedDurationMs);
  }

  static int ghostCountForLevel(int level) {
    final count = 3 + ((level - 1) ~/ 2);
    return count.clamp(3, kGhostColors.length);
  }

  /// Cuánto tiempo permanece visible una fruta antes de desaparecer si no
  /// se come. Baja con el nivel, hasta un mínimo razonable.
  static int fruitLifetimeForLevel(int level) {
    final duration = kFruitLifetimeMs - (level - 1) * 500;
    return duration.clamp(3000, kFruitLifetimeMs);
  }
}

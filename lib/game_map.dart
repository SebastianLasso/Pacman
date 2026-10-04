import 'constants.dart';
import 'levels.dart';

class GameMap {
  static const List<List<int>> originalLayout = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1],
    [1, 3, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 3, 1],
    [1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1],
    [1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  static late List<List<int>> layout;
  static int _trapTimerMs = 0;
  static bool trapWallsOpen = true;

  // Punto de aparición de Pac-Man.
  static const List<double> pacmanStart = [1, 1];

  // Puntos de aparición de los fantasmas (celdas abiertas cerca del centro).
  static const List<List<double>> ghostStarts = [
    [6, 3],
    [8, 3],
    [7, 7],
  ];

  static void resetMap() {
    layout = originalLayout.map((row) => List<int>.from(row)).toList();
    _resetDynamicState();
  }

  static void loadLevel(int level) {
    layout = Levels.layoutForLevel(level);
    _resetDynamicState();
  }

  static void _resetDynamicState() {
    _trapTimerMs = 0;
    trapWallsOpen = true;
  }

  static void updateTrapTimer(int deltaMs) {
    _trapTimerMs += deltaMs;
    final cycleMs = kTrapOpenMs + kTrapClosedMs;
    final phase = _trapTimerMs % cycleMs;
    trapWallsOpen = phase < kTrapOpenMs;
  }

  static bool isWall(int x, int y) {
    if (x < 0 || x >= kMapWidth || y < 0 || y >= kMapHeight) return true;
    final cell = layout[y][x];
    return cell == 1 || (cell == 5 && !trapWallsOpen);
  }

  static List<int>? otherTeleporterFor(int x, int y) {
    if (x < 0 || x >= kMapWidth || y < 0 || y >= kMapHeight) return null;
    final cell = layout[y][x];
    if (cell != 6 && cell != 7) return null;

    for (int row = 0; row < kMapHeight; row++) {
      for (int column = 0; column < kMapWidth; column++) {
        if (layout[row][column] == cell && (column != x || row != y)) {
          return [column, row];
        }
      }
    }
    return null;
  }

  /// Cuenta cuántos puntos (normales y power pellets) quedan sin comer.
  static int countRemainingPellets() {
    int count = 0;
    for (int y = 0; y < kMapHeight; y++) {
      for (int x = 0; x < kMapWidth; x++) {
        if (layout[y][x] == 2 || layout[y][x] == 3) {
          count++;
        }
      }
    }
    return count;
  }
}

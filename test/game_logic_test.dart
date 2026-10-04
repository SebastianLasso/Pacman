import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_pacman/game_map.dart';

void main() {
  test('debe contar los puntos restantes del mapa', () {
    GameMap.resetMap();
    final pellets = GameMap.countRemainingPellets();
    expect(pellets, greaterThan(0));
  });
}

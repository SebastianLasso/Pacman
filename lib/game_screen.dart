import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';
import 'effects.dart';
import 'game_map.dart';
import 'game_painter.dart';
import 'ghost.dart';
import 'level_complete_dialog.dart';
import 'levels.dart';
import 'lose_dialog.dart';
import 'score_display.dart';
import 'sound_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int level = 1;

  double pacmanX = GameMap.pacmanStart[0];
  double pacmanY = GameMap.pacmanStart[1];
  String direction = 'right';
  String nextDirection = 'right';

  int score = 0;
  int lives = kStartingLives;
  int frightenedMsRemaining = 0;

  bool gameRunning = true;
  bool paused = false; // breve pausa tras perder una vida
  bool userPaused = false; // pausa manual (botón, barra espaciadora o P)

  // --- Animación de Pac-Man ---
  double facingAngle = 0; // hacia dónde mira (suavizado)
  double mouthOpenness = 0.15; // 0 = cerrada, 1 = abierta
  double _mouthPhase = 0; // avanza con la distancia recorrida
  bool dying = false;
  int dyingMs = 0;

  // --- Efectos visuales ---
  final List<Particle> particles = [];
  final List<FloatingText> floatingTexts = [];

  // --- Fruta dinámica: aparece una a la vez, en una celda al azar ---
  int? fruitX;
  int? fruitY;
  int fruitActiveMsRemaining = 0;
  int fruitSpawnCountdownMs = kFruitFirstDelayMs;
  bool _fruitOnEmptyCell = false; // true si se puso sobre una celda ya vacía
  final Random _rand = Random();

  // Evita que un teletransportador rebote a Pac-Man de un lado a otro.
  int pacmanTeleportCooldownMs = 0;

  late Timer gameTimer;
  late List<Ghost> ghosts;

  // Se reutiliza el mismo FocusNode en cada build: crear uno nuevo por build
  // roba el foco constantemente y es muy costoso ahora que el loop llama a
  // setState ~60 veces por segundo.
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    GameMap.loadLevel(level);
    ghosts = _createGhosts();
    startGame();
  }

  List<Ghost> _createGhosts() {
    final spawns = GameMap.ghostStarts;
    final count = Levels.ghostCountForLevel(level);
    final normalSpeed = Levels.ghostSpeedForLevel(level);
    final frightSpeed = Levels.frightenedSpeedForLevel(level);

    return List.generate(count, (i) {
      final spawn = spawns[i % spawns.length];
      return Ghost(
          startX: spawn[0],
          startY: spawn[1],
          color: kGhostColors[i % kGhostColors.length],
          chaser: i == 0,
        )
        ..normalSpeed = normalSpeed
        ..frightenedSpeed = frightSpeed;
    });
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), _update);
  }

  @override
  void dispose() {
    gameTimer.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  /// Reinicio completo: vuelve al nivel 1 con puntaje y vidas en cero.
  void resetGame() {
    gameTimer.cancel();
    setState(() {
      level = 1;
      GameMap.loadLevel(level);
      pacmanX = GameMap.pacmanStart[0];
      pacmanY = GameMap.pacmanStart[1];
      direction = 'right';
      nextDirection = 'right';
      score = 0;
      lives = kStartingLives;
      frightenedMsRemaining = 0;
      gameRunning = true;
      paused = false;
      ghosts = _createGhosts();
      _resetFruitState();
      _resetVisualState();
    });
    startGame();
    _focusNode.requestFocus();
  }

  /// Avanza al siguiente nivel conservando puntaje y vidas.
  void _startNextLevel() {
    gameTimer.cancel();
    setState(() {
      level += 1;
      GameMap.loadLevel(level);
      pacmanX = GameMap.pacmanStart[0];
      pacmanY = GameMap.pacmanStart[1];
      direction = 'right';
      nextDirection = 'right';
      frightenedMsRemaining = 0;
      gameRunning = true;
      paused = false;
      ghosts = _createGhosts();
      _resetFruitState();
      _resetVisualState();
    });
    startGame();
  }

  void _resetVisualState() {
    userPaused = false;
    dying = false;
    dyingMs = 0;
    facingAngle = 0;
    mouthOpenness = 0.15;
    _mouthPhase = 0;
    particles.clear();
    floatingTexts.clear();
  }

  // ---------------------------------------------------------------------
  // Loop principal (~60 fps)
  // ---------------------------------------------------------------------

  void _update(Timer timer) {
    if (!gameRunning || userPaused) return;

    const dt = 0.016;

    _updateEffects(16);

    // Animación de muerte: todo lo demás queda congelado.
    if (dying) {
      _updateDeath();
      setState(() {});
      return;
    }

    // Pausa breve después de perder una vida (los efectos siguen animándose).
    if (paused) {
      setState(() {});
      return;
    }

    if (frightenedMsRemaining > 0) {
      frightenedMsRemaining -= 16;
      if (frightenedMsRemaining <= 0) {
        frightenedMsRemaining = 0;
        for (final g in ghosts) {
          g.mode = GhostMode.normal;
        }
      }
    }

    GameMap.updateTrapTimer(16);
    _updateFruit(16);
    final moved = _updatePacman(dt);
    _updateFacingAndMouth(dt, moved);

    if (!gameRunning) {
      // Se completó el nivel en esta celda.
      setState(() {});
      return;
    }

    for (final g in ghosts) {
      g.update(dt, pacmanX, pacmanY);
    }
    _checkGhostCollisions();

    setState(() {});
  }

  Offset _deltaFor(String dir) {
    switch (dir) {
      case 'right':
        return const Offset(1, 0);
      case 'left':
        return const Offset(-1, 0);
      case 'up':
        return const Offset(0, -1);
      case 'down':
        return const Offset(0, 1);
      default:
        return Offset.zero;
    }
  }

  double _angleFor(String dir) {
    switch (dir) {
      case 'down':
        return pi / 2;
      case 'left':
        return pi;
      case 'up':
        return -pi / 2;
      default:
        return 0;
    }
  }

  bool _isOpen(int gx, int gy, String dir) {
    final delta = _deltaFor(dir);
    return !GameMap.isWall(gx + delta.dx.round(), gy + delta.dy.round());
  }

  /// Mueve a Pac-Man. Devuelve true si realmente avanzó en este frame.
  bool _updatePacman(double dt) {
    if (pacmanTeleportCooldownMs > 0) pacmanTeleportCooldownMs -= 16;

    final step = kPacmanSpeed * dt;
    final gx = pacmanX.round();
    final gy = pacmanY.round();
    final centered =
        (pacmanX - gx).abs() < step / 2 && (pacmanY - gy).abs() < step / 2;

    if (centered) {
      pacmanX = gx.toDouble();
      pacmanY = gy.toDouble();

      // Aplica la dirección "en buffer" si es válida en este cruce
      // (esto permite girar en una esquina un poco antes de llegar a ella).
      if (_isOpen(gx, gy, nextDirection)) {
        direction = nextDirection;
      }

      _handleCell(gx, gy);
      if (!gameRunning) return false; // se completó el nivel en esta celda

      if (pacmanTeleportCooldownMs <= 0) {
        final dest = GameMap.otherTeleporterFor(gx, gy);
        if (dest != null) {
          _spawnBurst(
            gx.toDouble(),
            gy.toDouble(),
            Colors.cyanAccent,
            count: 10,
            speed: 2.4,
            lifeMs: 400,
            size: 0.05,
          );
          pacmanX = dest[0].toDouble();
          pacmanY = dest[1].toDouble();
          pacmanTeleportCooldownMs = 500;
          _spawnBurst(
            pacmanX,
            pacmanY,
            Colors.cyanAccent,
            count: 10,
            speed: 2.4,
            lifeMs: 400,
            size: 0.05,
          );
          return true;
        }
      }

      if (!_isOpen(gx, gy, direction)) {
        return false; // pared por delante: Pac-Man se queda quieto
      }
    }

    final delta = _deltaFor(direction);
    pacmanX += delta.dx * step;
    pacmanY += delta.dy * step;
    return true;
  }

  /// Giro suave hacia la dirección actual y boca ligada a la distancia
  /// recorrida (si Pac-Man se detiene, la boca se relaja).
  void _updateFacingAndMouth(double dt, bool moved) {
    final target = _angleFor(direction);
    var diff = target - facingAngle;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    facingAngle += diff * (1 - exp(-dt * 22));

    if (moved) {
      _mouthPhase += kPacmanSpeed * dt;
      // Un ciclo completo de abrir/cerrar cada ~0.9 celdas recorridas.
      mouthOpenness = (1 - cos(2 * pi * _mouthPhase / 0.9)) / 2;
    } else {
      mouthOpenness += (0.15 - mouthOpenness) * 0.2;
    }
  }

  void _handleCell(int gx, int gy) {
    final cell = GameMap.layout[gy][gx];
    if (cell == 2) {
      GameMap.layout[gy][gx] = 0;
      score += kNormalDotPoints;
      SoundManager.instance.playChomp();
      _spawnBurst(
        gx.toDouble(),
        gy.toDouble(),
        kDotColor,
        count: 4,
        speed: 1.4,
        lifeMs: 320,
        size: 0.045,
      );
      _spawnText(
        gx + 0.5,
        gy + 0.25,
        '+$kNormalDotPoints',
        kDotColor,
        scale: 0.6,
        lifeMs: 450,
      );
    } else if (cell == 3) {
      GameMap.layout[gy][gx] = 0;
      score += kPowerDotPoints;
      SoundManager.instance.playPower();
      final fruitColor = kFruitColors[(level - 1) % kFruitColors.length];
      _spawnBurst(
        gx.toDouble(),
        gy.toDouble(),
        fruitColor,
        count: 14,
        speed: 2.8,
        lifeMs: 600,
        size: 0.07,
      );
      _spawnText(
        gx + 0.5,
        gy + 0.25,
        '+$kPowerDotPoints',
        fruitColor,
        scale: 1.0,
        lifeMs: 800,
      );
      _activateFrightenedMode();
      _despawnFruit(eaten: true);
    }
    _checkLevelComplete();
  }

  // --- Efectos ------------------------------------------------------------

  void _spawnBurst(
    double cellX,
    double cellY,
    Color color, {
    int count = 8,
    double speed = 2.2,
    int lifeMs = 500,
    double size = 0.06,
  }) {
    particles.addAll(
      Particle.burst(
        _rand,
        cellX: cellX,
        cellY: cellY,
        color: color,
        count: count,
        speed: speed,
        lifeMs: lifeMs,
        size: size,
      ),
    );
  }

  void _spawnText(
    double x,
    double y,
    String text,
    Color color, {
    double scale = 1.0,
    int lifeMs = 700,
  }) {
    floatingTexts.add(
      FloatingText(
        x: x,
        y: y,
        text: text,
        color: color,
        scale: scale,
        lifeMs: lifeMs,
      ),
    );
  }

  void _updateEffects(int dtMs) {
    for (final p in particles) {
      p.update(dtMs);
    }
    particles.removeWhere((p) => p.isDead);

    for (final t in floatingTexts) {
      t.update(dtMs);
    }
    floatingTexts.removeWhere((t) => t.isDead);
  }

  // --- Fruta dinámica -----------------------------------------------

  void _resetFruitState() {
    fruitX = null;
    fruitY = null;
    fruitActiveMsRemaining = 0;
    fruitSpawnCountdownMs = kFruitFirstDelayMs;
  }

  void _updateFruit(int deltaMs) {
    if (fruitX != null) {
      fruitActiveMsRemaining -= deltaMs;
      if (fruitActiveMsRemaining <= 0) {
        _despawnFruit(eaten: false);
      }
    } else {
      fruitSpawnCountdownMs -= deltaMs;
      if (fruitSpawnCountdownMs <= 0) {
        _spawnFruit();
      }
    }
  }

  void _spawnFruit() {
    // Preferimos poner la fruta sobre un punto normal que todavía no se
    // haya comido (así no se pierde ningún punto, solo cambia su forma
    // temporalmente). Si ya no quedan puntos, la ponemos sobre una celda
    // vacía cualquiera para que siempre haya oportunidad de activar el
    // modo "frightened" y terminar de atrapar a los fantasmas.
    final dotCells = <List<int>>[];
    for (int y = 0; y < kMapHeight; y++) {
      for (int x = 0; x < kMapWidth; x++) {
        if (GameMap.layout[y][x] == 2) dotCells.add([x, y]);
      }
    }

    List<int> chosen;
    bool onEmptyCell;
    if (dotCells.isNotEmpty) {
      chosen = dotCells[_rand.nextInt(dotCells.length)];
      onEmptyCell = false;
    } else {
      final emptyCells = <List<int>>[];
      for (int y = 0; y < kMapHeight; y++) {
        for (int x = 0; x < kMapWidth; x++) {
          if (GameMap.layout[y][x] == 0) emptyCells.add([x, y]);
        }
      }
      if (emptyCells.isEmpty) {
        // No hay dónde poner una fruta ahora mismo; se reintenta pronto.
        fruitSpawnCountdownMs = 500;
        return;
      }
      chosen = emptyCells[_rand.nextInt(emptyCells.length)];
      onEmptyCell = true;
    }

    fruitX = chosen[0];
    fruitY = chosen[1];
    _fruitOnEmptyCell = onEmptyCell;
    GameMap.layout[fruitY!][fruitX!] = 3;
    fruitActiveMsRemaining = Levels.fruitLifetimeForLevel(level);
  }

  void _despawnFruit({required bool eaten}) {
    if (fruitX == null) return;
    if (!eaten) {
      // Si nadie se la comió, la celda vuelve a lo que era antes: un punto
      // normal, o quedar vacía si no había ningún punto ahí.
      GameMap.layout[fruitY!][fruitX!] = _fruitOnEmptyCell ? 0 : 2;
    }
    fruitX = null;
    fruitY = null;
    fruitActiveMsRemaining = 0;
    fruitSpawnCountdownMs = kFruitSpawnIntervalMs;
  }

  void _activateFrightenedMode() {
    frightenedMsRemaining = Levels.frightenedDurationForLevel(level);
    for (final g in ghosts) {
      g.mode = GhostMode.frightened;
      g.direction = _oppositeDirection(g.direction);
    }
  }

  String _oppositeDirection(String d) {
    switch (d) {
      case 'up':
        return 'down';
      case 'down':
        return 'up';
      case 'left':
        return 'right';
      case 'right':
        return 'left';
      default:
        return d;
    }
  }

  /// El nivel se completa cuando no quedan puntos/frutas por comer Y,
  /// además, cada fantasma fue atrapado al menos una vez en este nivel.
  void _checkLevelComplete() {
    if (GameMap.countRemainingPellets() > 0) return;
    if (!ghosts.every((g) => g.eatenThisLevel)) return;

    gameRunning = false;
    gameTimer.cancel();
    SoundManager.instance.playLevelComplete();
    showLevelCompleteDialog(context, level, score, _startNextLevel);
  }

  void _checkGhostCollisions() {
    for (final g in ghosts) {
      if (!g.isAlive) continue; // comido y esperando para reaparecer
      final dx = (g.x - pacmanX).abs();
      final dy = (g.y - pacmanY).abs();
      if (dx < 0.5 && dy < 0.5) {
        if (g.mode == GhostMode.frightened) {
          score += kGhostEatenPoints;
          SoundManager.instance.playEatGhost();
          g.eatenThisLevel = true;
          _spawnBurst(
            g.x,
            g.y,
            g.color,
            count: 16,
            speed: 3.0,
            lifeMs: 650,
            size: 0.07,
          );
          _spawnText(
            g.x + 0.5,
            g.y + 0.2,
            '+$kGhostEatenPoints',
            Colors.cyanAccent,
            scale: 1.3,
            lifeMs: 900,
          );
          g.defeat();
          _checkLevelComplete();
        } else {
          _startDeath();
        }
        break;
      }
    }
  }

  // --- Muerte de Pac-Man ----------------------------------------------

  void _startDeath() {
    if (dying) return;
    dying = true;
    dyingMs = 0;
    lives -= 1; // el corazón se resta de inmediato
    SoundManager.instance.playDeath();
  }

  void _updateDeath() {
    dyingMs += 16;
    if (dyingMs >= kDeathAnimMs) {
      _finishDeath();
    }
  }

  void _finishDeath() {
    if (lives <= 0) {
      // Game over: Pac-Man queda invisible detrás del diálogo.
      dyingMs = kDeathAnimMs;
      particles.clear();
      floatingTexts.clear();
      gameRunning = false;
      gameTimer.cancel();
      showLoseDialog(context, score, resetGame);
      return;
    }

    // Explosión de partículas en el lugar donde murió.
    _spawnBurst(
      pacmanX,
      pacmanY,
      kPacmanColor,
      count: 18,
      speed: 3.2,
      lifeMs: 700,
      size: 0.07,
    );

    dying = false;
    dyingMs = 0;
    paused = true;
    pacmanX = GameMap.pacmanStart[0];
    pacmanY = GameMap.pacmanStart[1];
    direction = 'right';
    nextDirection = 'right';
    facingAngle = 0;
    mouthOpenness = 0.15;
    _mouthPhase = 0;
    frightenedMsRemaining = 0;
    for (final g in ghosts) {
      g.reset(); // no borra eatenThisLevel: el progreso del nivel se conserva
    }

    Future.delayed(const Duration(milliseconds: kReadyPauseMs), () {
      if (mounted) {
        setState(() => paused = false);
      }
    });
  }

  // ---------------------------------------------------------------------
  // Controles
  // ---------------------------------------------------------------------

  void changeDirection(String newDirection) {
    nextDirection = newDirection;
  }

  void togglePause() {
    if (!gameRunning) return;
    setState(() => userPaused = !userPaused);
    _focusNode.requestFocus(); // para que las flechas sigan funcionando
  }

  String get _statusText {
    if (!gameRunning) return '🏁 Juego terminado';
    if (userPaused) return '⏸️ Juego en pausa';
    if (dying) return '💀 ¡Te atraparon!';
    if (paused) return '💥 ¡Prepárate!';
    return '🎮 Jugando...';
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is! KeyDownEvent) return;
        final key = event.logicalKey;

        if (key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.keyP ||
            key == LogicalKeyboardKey.escape) {
          togglePause();
          return;
        }

        if (!gameRunning || userPaused) return;

        if (key == LogicalKeyboardKey.arrowRight) {
          changeDirection('right');
        } else if (key == LogicalKeyboardKey.arrowLeft) {
          changeDirection('left');
        } else if (key == LogicalKeyboardKey.arrowUp) {
          changeDirection('up');
        } else if (key == LogicalKeyboardKey.arrowDown) {
          changeDirection('down');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              ScoreDisplay(
                level: level,
                score: score,
                lives: lives,
                isPaused: userPaused,
                onReset: resetGame,
                onTogglePause: togglePause,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 320,
                    ),
                    child: AspectRatio(
                      aspectRatio: kMapWidth / kMapHeight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                size: Size.infinite,
                                painter: GamePainter(
                                  pacmanX: pacmanX,
                                  pacmanY: pacmanY,
                                  facingAngle: facingAngle,
                                  mouthOpenness: mouthOpenness,
                                  dyingProgress: dying
                                      ? dyingMs / kDeathAnimMs
                                      : 0.0,
                                  ghosts: ghosts,
                                  frightenedMsRemaining: frightenedMsRemaining,
                                  level: level,
                                  fruitMsRemaining: fruitActiveMsRemaining,
                                  particles: particles,
                                  floatingTexts: floatingTexts,
                                ),
                              ),
                              if (userPaused)
                                Container(
                                  color: Colors.black.withAlpha(180),
                                  alignment: Alignment.center,
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.pause_circle_filled,
                                        color: Colors.yellow,
                                        size: 56,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'PAUSA',
                                        style: TextStyle(
                                          color: Colors.yellow,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: gameRunning
                            ? (paused || dying || userPaused
                                  ? Colors.orange
                                  : Colors.green)
                            : Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Flechas: mover  •  Espacio o P: pausar / continuar',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

const int kMapWidth = 15;
const int kMapHeight = 9;

const Color kWallColor = Color(0xFF1565C0);
const Color kWallBorderColor = Color(0xFF42A5F5);
const Color kDotColor = Colors.yellow;
const Color kPowerDotColor = Colors.orange;
const Color kPacmanColor = Colors.yellow;
const Color kEyeColor = Colors.black;
const Color kFrightenedGhostColor = Color(0xFF1E88E5);
const Color kFrightenedGhostFlashColor = Colors.white;

const List<Color> kGhostColors = [
  Colors.red,
  Color(0xFFFF69B4),
  Color(0xFF00E5FF),
  Colors.lightGreenAccent,
  Color(0xFFAB47BC),
];

// Colores de las frutas (power-ups), uno distinto por nivel (rota).
const List<Color> kFruitColors = [
  Colors.red,
  Colors.orange,
  Colors.purpleAccent,
  Colors.pinkAccent,
  Colors.lightGreenAccent,
];

// Velocidades base (celdas por segundo) — el loop corre a ~60 fps.
// La dificultad por nivel escala a partir de estos valores en levels.dart.
const double kPacmanSpeed = 4.6;
const double kGhostSpeed = 3.6;
const double kFrightenedGhostSpeed = 2.4;

const int kFrightenedDurationMs = 6000;
const int kFrightenedFlashStartMs = 1500;

const int kNormalDotPoints = 10;
const int kPowerDotPoints = 50;
const int kGhostEatenPoints = 200;

// Sistema de frutas dinámicas: aparecen una a la vez, en una celda al azar,
// y desaparecen si no se comen a tiempo.
const int kFruitFirstDelayMs = 3000; // primera fruta del nivel
const int kFruitSpawnIntervalMs =
    8000; // tiempo entre que desaparece una y sale otra
const int kFruitLifetimeMs = 7000; // cuánto dura visible antes de desaparecer
const int kFruitFlashStartMs = 2000; // empieza a parpadear cuando le queda esto

const int kStartingLives = 3;
const int kReadyPauseMs = 900;
const int kDeathAnimMs = 1100; // duración de la animación al perder una vida

// Trampas de mapa: paredes intermitentes (aparecen/desaparecen).
const int kTrapOpenMs = 3000; // cuánto tiempo quedan abiertas (pasables)
const int kTrapClosedMs = 3500; // cuánto tiempo quedan cerradas (pared)

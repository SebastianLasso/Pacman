import 'package:flutter/material.dart';

void showLevelCompleteDialog(
  BuildContext context,
  int level,
  int score,
  VoidCallback onNextLevel,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          '🎉 ¡Nivel $level completado!',
          style: const TextStyle(color: Colors.yellow),
        ),
        content: Text(
          'Puntuación: $score\n¡Prepárate para el nivel ${level + 1}!',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onNextLevel();
            },
            child: const Text(
              'Siguiente nivel',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      );
    },
  );
}

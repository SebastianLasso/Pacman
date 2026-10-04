import 'package:flutter/material.dart';

void showLoseDialog(BuildContext context, int score, VoidCallback onRetry) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          '¡Game Over!',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          'Los fantasmas te atraparon.\nPuntuación final: $score\nSuerte a la proxima',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text(
              'Intentar de nuevo',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      );
    },
  );
}

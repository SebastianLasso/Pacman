import 'package:flutter/material.dart';

class ScoreDisplay extends StatelessWidget {
  final int level;
  final int score;
  final int lives;
  final bool isPaused;
  final VoidCallback onReset;
  final VoidCallback onTogglePause;

  const ScoreDisplay({
    super.key,
    required this.level,
    required this.score,
    required this.lives,
    required this.isPaused,
    required this.onReset,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'Nivel $level',
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: Text(
              'Score: $score',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          Row(
            children: List.generate(
              lives,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.favorite, color: Colors.red, size: 22),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, color: Colors.yellow),
            label: const Text(
              'Reiniciar',
              style: TextStyle(color: Colors.yellow),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.yellow, width: 2),
              ),
            ),
          ),
          IconButton(
            onPressed: onTogglePause,
            tooltip: isPaused ? 'Continuar' : 'Pausar',
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}

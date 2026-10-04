import 'package:flutter/material.dart';

import 'start_screen.dart';

void main() {
  runApp(const PacmanApp());
}

class PacmanApp extends StatelessWidget {
  const PacmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pac-Man',
      theme: ThemeData.dark(),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

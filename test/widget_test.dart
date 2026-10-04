import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_pacman/main.dart';

void main() {
  testWidgets('La app carga y muestra el marcador inicial', (tester) async {
    await tester.pumpWidget(const PacmanApp());
    await tester.pump();

    // Se debe ver el puntaje inicial en 0.
    expect(find.text('Score: 0'), findsOneWidget);

    // Deben verse las 3 vidas iniciales (ícono de corazón).
    expect(find.byIcon(Icons.favorite), findsNWidgets(3));

    // El botón de reiniciar debe estar presente.
    expect(find.text('Reiniciar'), findsOneWidget);

    // Los botones del D-pad táctil deben estar presentes.
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_left), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
  });

  testWidgets('El botón de reiniciar reinicia el puntaje a 0', (tester) async {
    await tester.pumpWidget(const PacmanApp());

    // Deja correr el juego un momento para que el puntaje pueda cambiar
    // (Pac-Man se come el punto de su celda inicial al comenzar).
    await tester.pump(const Duration(milliseconds: 500));

    // Presiona "Reiniciar".
    await tester.tap(find.text('Reiniciar'));
    await tester.pump();

    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNWidgets(3));
  });

  testWidgets('Los botones del D-pad no lanzan errores al presionarlos', (
    tester,
  ) async {
    await tester.pumpWidget(const PacmanApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
    await tester.pump(const Duration(milliseconds: 100));

    // Si no se lanzó ninguna excepción, el test pasa.
  });
}

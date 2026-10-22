import 'package:brilliant/presentacion/pantalla_inicio.dart';
import 'package:brilliant/presentacion/seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el nombre del juego y el botón de inicio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaInicio()),
    );

    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Inicio'), findsOneWidget);
    expect(find.byType(PantallaSeleccionMapa), findsNothing);
  });

  testWidgets('el botón Inicio navega al selector de mapas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaInicio()),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Inicio'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaSeleccionMapa), findsOneWidget);
    expect(find.text('Selecciona un mapa'), findsOneWidget);
  });
}

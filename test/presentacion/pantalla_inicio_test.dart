import 'package:brilliant/presentacion/pantalla_inicio.dart';
import 'package:brilliant/presentacion/pantalla_instrucciones.dart';
import 'package:brilliant/presentacion/seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el nombre del juego y el botón de inicio', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaInicio()));

    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.text('Instrucciones'), findsOneWidget);
    expect(find.text('Cómo jugar'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Inicio'), findsOneWidget);
    expect(find.byType(PantallaSeleccionMapa), findsNothing);
  });

  testWidgets('el botón Instrucciones abre la información del juego', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaInicio()));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Instrucciones'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaInstrucciones), findsOneWidget);
    expect(find.text('Cómo jugar'), findsOneWidget);
    expect(find.text('Reglas de las zonas'), findsOneWidget);
    expect(find.text('Cómo se puntúa'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PantallaInicio), findsOneWidget);
  });

  testWidgets('el botón Inicio navega al selector de mapas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaInicio()));

    final inicio = find.widgetWithText(FilledButton, 'Inicio');
    await tester.ensureVisible(inicio);
    await tester.tap(inicio);
    await tester.pumpAndSettle();

    expect(find.byType(PantallaSeleccionMapa), findsOneWidget);
    expect(find.text('Selecciona un mapa'), findsOneWidget);
  });

  testWidgets('muestra instrucciones y puntuaciones específicas por mapa', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaInicio()));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Instrucciones'));
    await tester.pumpAndSettle();

    expect(find.textContaining('casillas iniciales señaladas'), findsOneWidget);
    expect(find.textContaining('casilla vacía adyacente'), findsOneWidget);

    final mapaTres = find.text('Mapa 3');
    await tester.ensureVisible(mapaTres);
    await tester.tap(mapaTres);
    await tester.pumpAndSettle();

    expect(
      find.text('Moradas (cuentan como una zona): 7, 5, 3 puntos.'),
      findsOneWidget,
    );
    expect(
      find.text('Blancas (una sola zona): 8, 6, 4 puntos.'),
      findsOneWidget,
    );
  });
}

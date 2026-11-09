import 'package:brilliant/presentacion/tema_mesa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the warm tabletop palette and light surfaces', () {
    final theme = TemaMesa.data;

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, TemaMesa.papel);
    expect(theme.colorScheme.primary, TemaMesa.verde);
    expect(theme.cardTheme.elevation, 2);
  });

  testWidgets('shows a dice-themed loading state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IndicadorCargaMesa(mensaje: 'Preparando el tablero...'),
      ),
    );

    expect(find.byIcon(Icons.casino_rounded), findsOneWidget);
    expect(find.text('Preparando el tablero...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}

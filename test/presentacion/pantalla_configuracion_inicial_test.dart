import 'package:brilliant/presentacion/pantalla_configuracion_inicial.dart';
import 'package:brilliant/presentacion/widgets/boton_inicio.dart';
import 'package:brilliant/presentacion/widgets/selector_numeros_zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arma la pantalla con título, tablero, selector y botón', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaConfiguracionInicial()));

    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.byType(TableroWidget), findsOneWidget);
    expect(find.byType(SelectorNumerosZonaInicial), findsOneWidget);
    expect(find.byType(BotonInicio), findsOneWidget);
  });

  testWidgets('el botón Inicio empieza deshabilitado', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaConfiguracionInicial()));

    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
  });

  testWidgets(
    'flujo completo: llenar los 6 números distintos habilita Inicio y tocarlo lo deshabilita de nuevo',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PantallaConfiguracionInicial()));

      // Coloca 1..6 tocando los botones del selector; cada toque avanza
      // automáticamente a la siguiente celda vacía de la ZonaInicial.
      for (var n = 1; n <= 6; n++) {
        await tester.tap(find.text('$n'));
        await tester.pump();
      }

      expect(find.textContaining('¡Configuración lista!'), findsNothing);
      var boton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(boton.onPressed, isNotNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('¡Configuración lista!'), findsOneWidget);
      boton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(boton.onPressed, isNull);
    },
  );

  testWidgets('tocar un número repetido muestra el aviso de número repetido', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaConfiguracionInicial()));

    await tester.tap(find.text('1')); // celda 1 = 1, avanza a la celda 2
    await tester.pump();
    await tester.tap(find.text('1')); // celda 2: 1 ya está en la celda 1
    await tester.pump();
    await tester.pump(); // anima el SnackBar

    expect(find.textContaining('ya está en la casilla'), findsOneWidget);
  });
}

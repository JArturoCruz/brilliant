import 'package:brilliant/main.dart' as app;
import 'package:brilliant/presentacion/pantalla_configuracion_inicial.dart';
import 'package:brilliant/presentacion/pantalla_juego.dart';
import 'package:brilliant/presentacion/seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'package:brilliant/presentacion/widgets/boton_inicio.dart';
import 'package:brilliant/presentacion/widgets/selector_numeros_zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(1200, 1600);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('navega desde inicio al mapa disponible en móvil', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(320, 740);
    binding.window.devicePixelRatioTestValue = 1;

    await tester.pumpWidget(const app.BrilliantApp());
    await tester.pumpAndSettle();

    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.byType(TableroWidget), findsNothing);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaSeleccionMapa), findsOneWidget);
    expect(find.text('Mapa 1'), findsOneWidget);
    expect(find.text('Mapa 2'), findsOneWidget);
    expect(find.text('Mapa 3'), findsOneWidget);
    expect(find.text('Mapa 4'), findsOneWidget);

    await tester.tap(find.text('Mapa 2'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaSeleccionMapa), findsOneWidget);

    await tester.tap(find.text('Mapa 1'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaJuego), findsOneWidget);
    expect(find.byType(TableroWidget), findsOneWidget);
    expect(find.byType(BotonInicio), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arma la pantalla con título, tablero, selector y botón', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaConfiguracionInicial()),
    );

    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.byType(TableroWidget), findsOneWidget);
    expect(find.byType(SelectorNumerosZonaInicial), findsOneWidget);
    expect(find.byType(BotonInicio), findsOneWidget);
  });

  testWidgets('el botón Inicio empieza deshabilitado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaConfiguracionInicial()),
    );

    final inicio = find.widgetWithText(FilledButton, 'Inicio');
    final boton = tester.widget<FilledButton>(inicio);
    expect(boton.onPressed, isNull);
  });

  testWidgets(
    'flujo completo: llenar los 6 números distintos habilita Inicio y tocarlo activa la configuración',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PantallaConfiguracionInicial()),
      );

      for (var n = 1; n <= 6; n++) {
        final finder = find.widgetWithText(OutlinedButton, '$n');
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();
      }

      expect(find.textContaining('¡Configuración lista!'), findsNothing);
      final inicio = find.widgetWithText(FilledButton, 'Inicio');
      final boton = tester.widget<FilledButton>(inicio);
      expect(boton.onPressed, isNotNull);

      await tester.tap(inicio);
      await tester.pumpAndSettle();

      expect(find.text('¡Configuración lista!'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Inicio'), findsNothing);
    },
  );

  testWidgets('tocar un número repetido muestra el aviso de número repetido', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaConfiguracionInicial()),
    );

    final primerNumero = find.widgetWithText(OutlinedButton, '1');
    await tester.ensureVisible(primerNumero);
    await tester.tap(primerNumero);
    await tester.pump();

    await tester.ensureVisible(primerNumero);
    await tester.tap(primerNumero);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('ya está en la casilla'), findsOneWidget);
  });
}

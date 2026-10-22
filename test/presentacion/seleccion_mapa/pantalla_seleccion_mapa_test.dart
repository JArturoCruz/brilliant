import 'package:brilliant/presentacion/seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'package:brilliant/presentacion/seleccion_mapa/widgets/tarjeta_mapa.dart';
import 'package:brilliant/presentacion/pantalla_juego.dart';
import 'package:brilliant/presentacion/widgets/tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra cuatro mapas y habilita los cuatro', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaSeleccionMapa()));

    expect(find.text('Mapa 1'), findsOneWidget);
    expect(find.text('Mapa 2'), findsOneWidget);
    expect(find.text('Mapa 3'), findsOneWidget);
    expect(find.text('Mapa 4'), findsOneWidget);
    expect(find.text('Disponible'), findsNWidgets(4));
    expect(find.text('Próximamente'), findsNothing);

    final tarjetas = tester.widgetList<TarjetaMapa>(find.byType(TarjetaMapa));
    expect(tarjetas, hasLength(4));
    expect(tarjetas.where((tarjeta) => tarjeta.onTap != null), hasLength(4));
    expect(tarjetas.first.onTap, isNotNull);
    expect(tarjetas.elementAt(1).onTap, isNotNull);
    expect(tarjetas.elementAt(2).onTap, isNotNull);
    expect(tarjetas.last.onTap, isNotNull);
  });

  testWidgets('seleccionar el mapa 2 abre el tablero correspondiente', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaSeleccionMapa()));

    await tester.tap(find.text('Mapa 2'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaJuego), findsOneWidget);
    expect(find.byType(TableroWidget), findsOneWidget);
    expect(tester.widget<PantallaJuego>(find.byType(PantallaJuego)).mapa.id, 2);
    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('seleccionar el mapa 3 abre el tablero correspondiente', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaSeleccionMapa()));

    await tester.tap(find.text('Mapa 3'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaJuego), findsOneWidget);
    expect(tester.widget<PantallaJuego>(find.byType(PantallaJuego)).mapa.id, 3);
    expect(find.byType(TableroWidget), findsOneWidget);
  });

  testWidgets('seleccionar el mapa 4 abre el tablero correspondiente', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaSeleccionMapa()));

    await tester.tap(find.text('Mapa 4'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaJuego), findsOneWidget);
    expect(tester.widget<PantallaJuego>(find.byType(PantallaJuego)).mapa.id, 4);
    expect(find.byType(TableroWidget), findsOneWidget);
  });

  testWidgets('usa una columna en móvil y dos columnas en escritorio', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(const MaterialApp(home: PantallaSeleccionMapa()));
    expect(
      tester.widget<GridView>(find.byType(GridView)).gridDelegate,
      isA<SliverGridDelegateWithFixedCrossAxisCount>(),
    );
    expect(
      (tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );

    tester.view.physicalSize = const Size(900, 844);
    await tester.pumpWidget(const MaterialApp(home: PantallaSeleccionMapa()));
    await tester.pump();

    expect(
      (tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
  });
}

import 'package:brilliant/presentacion/seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'package:brilliant/presentacion/seleccion_mapa/widgets/tarjeta_mapa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra cuatro mapas y solo habilita el primero', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaSeleccionMapa()));

    expect(find.text('Mapa 1'), findsOneWidget);
    expect(find.text('Mapa 2'), findsOneWidget);
    expect(find.text('Mapa 3'), findsOneWidget);
    expect(find.text('Mapa 4'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Próximamente'), findsNWidgets(3));

    final tarjetas = tester.widgetList<TarjetaMapa>(find.byType(TarjetaMapa));
    expect(tarjetas, hasLength(4));
    expect(tarjetas.where((tarjeta) => tarjeta.onTap != null), hasLength(1));
    expect(tarjetas.first.onTap, isNotNull);
    expect(tarjetas.skip(1).every((tarjeta) => tarjeta.onTap == null), isTrue);
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

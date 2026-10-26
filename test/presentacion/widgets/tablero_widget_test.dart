import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/topologia_tablero.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/celda_tablero_widget.dart';
import 'package:brilliant/presentacion/widgets/tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dibuja una celda por cada posición del tablero (7x7 = 49)', (
    tester,
  ) async {
    final cubit = ZonaInicialCubit();
    final bloque = JuegoBloc();
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<JuegoBloc>.value(value: bloque),
            BlocProvider<ZonaInicialCubit>.value(value: cubit),
          ],
          child: const Scaffold(body: TableroWidget()),
        ),
      ),
    );

    expect(
      find.byType(CeldaTableroWidget),
      findsNWidgets(TopologiaTablero.filas * TopologiaTablero.columnas),
    );
    cubit.close();
    bloque.close();
  });

  testWidgets(
    'muestra 6 signos de interrogación antes de llenar la ZonaInicial',
    (tester) async {
      final cubit = ZonaInicialCubit();
      final bloque = JuegoBloc();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<JuegoBloc>.value(value: bloque),
              BlocProvider<ZonaInicialCubit>.value(value: cubit),
            ],
            child: const Scaffold(body: TableroWidget()),
          ),
        ),
      );

      expect(find.text('?'), findsNWidgets(ZonaInicial.cantidadCeldas));
      cubit.close();
      bloque.close();
    },
  );

  testWidgets('muestra las seis celdas iniciales del mapa 2', (tester) async {
    final cubit = ZonaInicialCubit(mapa: MapaTablero.mapa2);
    final bloque = JuegoBloc(mapa: MapaTablero.mapa2);
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<JuegoBloc>.value(value: bloque),
            BlocProvider<ZonaInicialCubit>.value(value: cubit),
          ],
          child: const Scaffold(body: TableroWidget(mapa: MapaTablero.mapa2)),
        ),
      ),
    );

    expect(find.text('?'), findsNWidgets(ZonaInicial.cantidadCeldas));
    for (final posicion in const [
      Posicion(0, 4),
      Posicion(2, 0),
      Posicion(3, 2),
      Posicion(4, 5),
      Posicion(5, 1),
      Posicion(6, 4),
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CeldaTableroWidget &&
              widget.posicion == posicion &&
              widget.state.valores.containsKey(posicion),
        ),
        findsOneWidget,
      );
    }
    cubit.close();
    bloque.close();
  });

  testWidgets('muestra las seis celdas iniciales del mapa 3', (tester) async {
    final cubit = ZonaInicialCubit(mapa: MapaTablero.mapa3);
    final bloque = JuegoBloc(mapa: MapaTablero.mapa3);
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<JuegoBloc>.value(value: bloque),
            BlocProvider<ZonaInicialCubit>.value(value: cubit),
          ],
          child: const Scaffold(body: TableroWidget(mapa: MapaTablero.mapa3)),
        ),
      ),
    );

    expect(find.text('?'), findsNWidgets(ZonaInicial.cantidadCeldas));
    for (final posicion in const [
      Posicion(1, 2),
      Posicion(1, 5),
      Posicion(3, 3),
      Posicion(4, 1),
      Posicion(4, 6),
      Posicion(6, 2),
    ]) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CeldaTableroWidget &&
              widget.posicion == posicion &&
              widget.state.valores.containsKey(posicion),
        ),
        findsOneWidget,
      );
    }
    cubit.close();
    bloque.close();
  });

  testWidgets(
    'tocar una celda de la ZonaInicial dentro del tablero la selecciona',
    (tester) async {
      final cubit = ZonaInicialCubit();
      final bloque = JuegoBloc();
      final pos = ZonaInicial.posiciones[1];

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<JuegoBloc>.value(value: bloque),
              BlocProvider<ZonaInicialCubit>.value(value: cubit),
            ],
            child: const Scaffold(body: TableroWidget()),
          ),
        ),
      );

      final celda = find.byWidgetPredicate(
        (w) => w is CeldaTableroWidget && w.posicion == pos,
      );
      await tester.tap(celda);

      expect(cubit.state.seleccionada, pos);
      cubit.close();
      bloque.close();
    },
  );
}

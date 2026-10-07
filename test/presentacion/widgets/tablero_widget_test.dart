import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/topologia_tablero.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/celda_tablero_widget.dart';
import 'package:brilliant/presentacion/widgets/tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dibuja una celda por cada posición del tablero (7x7 = 49)', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: TableroWidget()),
      ),
    ));

    expect(find.byType(CeldaTableroWidget),
        findsNWidgets(TopologiaTablero.filas * TopologiaTablero.columnas));
    cubit.close();
  });

  testWidgets('muestra 6 signos de interrogación antes de llenar la ZonaInicial', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: TableroWidget()),
      ),
    ));

    expect(find.text('?'), findsNWidgets(ZonaInicial.cantidadCeldas));
    cubit.close();
  });

  testWidgets('tocar una celda de la ZonaInicial dentro del tablero la selecciona', (tester) async {
    final cubit = ZonaInicialCubit();
    final pos = ZonaInicial.posiciones[1];

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: TableroWidget()),
      ),
    ));

    final celda = find.byWidgetPredicate(
      (w) => w is CeldaTableroWidget && w.posicion == pos,
    );
    await tester.tap(celda);

    expect(cubit.state.seleccionada, pos);
    cubit.close();
  });
}

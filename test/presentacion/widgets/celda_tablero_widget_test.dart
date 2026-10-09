import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/celda_tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(ZonaInicialCubit cubit, Widget hijo) {
  final juegoBloc = JuegoBloc();
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<JuegoBloc>.value(value: juegoBloc),
        BlocProvider<ZonaInicialCubit>.value(value: cubit),
      ],
      child: Scaffold(body: hijo),
    ),
  );
}

Widget _celda(Posicion pos) {
  return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
    builder: (context, state) => CeldaTableroWidget(posicion: pos, state: state),
  );
}

void main() {
  testWidgets('una celda vacía de la ZonaInicial muestra "?"', (tester) async {
    final cubit = ZonaInicialCubit();
    final pos = ZonaInicial.posiciones.first;

    await tester.pumpWidget(_envolver(cubit, _celda(pos)));

    expect(find.text('?'), findsOneWidget);
    cubit.close();
  });

  testWidgets('una celda con valor muestra el número', (tester) async {
    final cubit = ZonaInicialCubit();
    final pos = ZonaInicial.posiciones.first;
    cubit.asignarASeleccionada(5);

    await tester.pumpWidget(_envolver(cubit, _celda(pos)));

    expect(find.text('5'), findsOneWidget);
    cubit.close();
  });

  testWidgets('tocar una celda de la ZonaInicial la selecciona en el cubit', (tester) async {
    final cubit = ZonaInicialCubit();
    final pos = ZonaInicial.posiciones[2];

    await tester.pumpWidget(_envolver(cubit, _celda(pos)));

    await tester.tap(find.byType(GestureDetector));
    expect(cubit.state.seleccionada, pos);
    cubit.close();
  });

  testWidgets('una celda fuera de la ZonaInicial no muestra "?" ni número', (tester) async {
    final cubit = ZonaInicialCubit();
    // La esquina (0,0) es amarilla pero no es una de las 6 celdas de la ZonaInicial.
    const celdaFueraDeZona = Posicion(0, 0);
    expect(ZonaInicial.posiciones.contains(celdaFueraDeZona), isFalse);

    await tester.pumpWidget(_envolver(cubit, _celda(celdaFueraDeZona)));

    expect(find.text('?'), findsNothing);
    cubit.close();
  });

  testWidgets('tocar una celda fuera de la ZonaInicial no cambia la selección', (tester) async {
    final cubit = ZonaInicialCubit();
    const celdaFueraDeZona = Posicion(0, 0);
    final seleccionPrevia = cubit.state.seleccionada;

    await tester.pumpWidget(_envolver(cubit, _celda(celdaFueraDeZona)));
    await tester.tap(find.byType(GestureDetector));

    expect(cubit.state.seleccionada, seleccionPrevia);
    cubit.close();
  });
}

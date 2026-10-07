import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/presentacion/widgets/boton_inicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(ZonaInicialCubit cubit, TableroJuego tablero) {
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(body: BotonInicio(tablero: tablero)),
    ),
  );
}

void main() {
  testWidgets('está deshabilitado mientras la ZonaInicial no sea válida', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(_envolver(cubit, TableroJuego()));

    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
    cubit.close();
  });

  testWidgets('se habilita cuando la ZonaInicial queda válida', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(_envolver(cubit, TableroJuego()));

    for (var i = 0; i < 6; i++) {
      cubit.asignarASeleccionada(i + 1);
    }
    await tester.pump();

    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNotNull);
    cubit.close();
  });

  testWidgets('al tocarlo aplica los valores al tablero y vuelve a deshabilitarse', (tester) async {
    final cubit = ZonaInicialCubit();
    final tablero = TableroJuego();
    await tester.pumpWidget(_envolver(cubit, tablero));

    for (var i = 0; i < 6; i++) {
      cubit.asignarASeleccionada(i + 1);
    }
    await tester.pump();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(cubit.state.iniciada, isTrue);
    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
    cubit.close();
  });
}

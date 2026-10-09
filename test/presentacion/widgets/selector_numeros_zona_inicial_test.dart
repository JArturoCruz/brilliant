import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/presentacion/widgets/boton_numero.dart';
import 'package:brilliant/presentacion/widgets/selector_numeros_zona_inicial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(ZonaInicialCubit cubit) {
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: const Scaffold(body: SelectorNumerosZonaInicial()),
    ),
  );
}

void main() {
  testWidgets('muestra un botón por cada número del 1 al 6', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(_envolver(cubit));
    expect(find.byType(BotonNumero), findsNWidgets(6));
    cubit.close();
  });

  testWidgets('tocar un número lo asigna a la celda seleccionada', (tester) async {
    final cubit = ZonaInicialCubit();
    final primera = cubit.state.seleccionada!;
    await tester.pumpWidget(_envolver(cubit));

    await tester.tap(find.text('3'));
    await tester.pump();

    expect(cubit.state.valores[primera], 3);
    cubit.close();
  });

  testWidgets('el botón de borrar está deshabilitado si la celda está vacía', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(_envolver(cubit));

    final boton = tester.widget<IconButton>(find.byType(IconButton));
    expect(boton.onPressed, isNull);
    cubit.close();
  });

  testWidgets('el botón de borrar se habilita tras colocar un número en la celda seleccionada', (tester) async {
    final cubit = ZonaInicialCubit();
    final celda = cubit.state.seleccionada!;
    await tester.pumpWidget(_envolver(cubit));

    cubit.asignarValor(celda, 2);
    await tester.pump();

    expect(cubit.state.valores[celda], 2);
    final boton = tester.widget<IconButton>(find.byType(IconButton));
    expect(boton.onPressed, isNotNull);
    cubit.close();
  });

  testWidgets('tocar el botón de borrar limpia la celda seleccionada', (tester) async {
    final cubit = ZonaInicialCubit();
    final primera = cubit.state.seleccionada!;
    await tester.pumpWidget(_envolver(cubit));

    await tester.tap(find.text('2'));
    await tester.pump();
    cubit.seleccionarCelda(primera);
    await tester.pump();

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(cubit.state.valores[primera], isNull);
    cubit.close();
  });
}

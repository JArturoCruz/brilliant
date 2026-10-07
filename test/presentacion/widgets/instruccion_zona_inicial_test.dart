import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/instruccion_zona_inicial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el conteo 0/6 al inicio', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: InstruccionZonaInicial()),
      ),
    ));

    expect(find.textContaining('0/${ZonaInicial.cantidadCeldas}'), findsOneWidget);
    cubit.close();
  });

  testWidgets('actualiza el conteo según se llenan celdas', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: InstruccionZonaInicial()),
      ),
    ));

    cubit.asignarASeleccionada(1);
    await tester.pump();

    expect(find.textContaining('1/${ZonaInicial.cantidadCeldas}'), findsOneWidget);
    cubit.close();
  });

  testWidgets('muestra el mensaje de listo una vez iniciada la partida', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: InstruccionZonaInicial()),
      ),
    ));

    for (var i = 0; i < 6; i++) {
      cubit.asignarASeleccionada(i + 1);
    }
    cubit.aplicarATablero(TableroJuego());
    await tester.pump();

    expect(find.text('¡Configuración lista!'), findsOneWidget);
    cubit.close();
  });
}

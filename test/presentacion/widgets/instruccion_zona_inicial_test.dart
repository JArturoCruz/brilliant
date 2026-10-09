import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/instruccion_zona_inicial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el conteo 0/6 al inicio', (tester) async {
    final cubit = ZonaInicialCubit();
    final juegoBloc = JuegoBloc();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocProvider.value(
            value: juegoBloc,
            child: const Scaffold(body: InstruccionZonaInicial()),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('0/${ZonaInicial.cantidadCeldas}'),
      findsOneWidget,
    );
    cubit.close();
    juegoBloc.close();
  });

  testWidgets('actualiza el conteo según se llenan celdas', (tester) async {
    final cubit = ZonaInicialCubit();
    final juegoBloc = JuegoBloc();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocProvider.value(
            value: juegoBloc,
            child: const Scaffold(body: InstruccionZonaInicial()),
          ),
        ),
      ),
    );

    cubit.asignarASeleccionada(1);
    await tester.pump();

    expect(
      find.textContaining('1/${ZonaInicial.cantidadCeldas}'),
      findsOneWidget,
    );
    cubit.close();
    juegoBloc.close();
  });

  testWidgets('muestra el mensaje de listo una vez iniciada la partida', (
    tester,
  ) async {
    final cubit = ZonaInicialCubit();
    final juegoBloc = JuegoBloc();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: BlocProvider.value(
            value: juegoBloc,
            child: const Scaffold(body: InstruccionZonaInicial()),
          ),
        ),
      ),
    );

    for (var i = 0; i < 6; i++) {
      cubit.asignarASeleccionada(i + 1);
    }
    cubit.aplicarATablero(TableroJuego());
    await tester.pump();

    expect(find.text('¡Configuración lista!'), findsOneWidget);

    juegoBloc.add(IniciarTurno({const Posicion(0, 0): 1}));
    await juegoBloc.stream.firstWhere(
      (state) => state.fase == FaseTurno.seleccionandoAncla,
    );
    await tester.pump();

    expect(find.text('¡Configuración lista!'), findsNothing);
    cubit.close();
    juegoBloc.close();
  });
}

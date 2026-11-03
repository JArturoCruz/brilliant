import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/presentacion/widgets/panel_datos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('los dados usan animación de giro al lanzarse', (tester) async {
    var siguienteDado = 1;
    final bloc = JuegoBloc(tirarDado: () => siguienteDado++);
    addTearDown(bloc.close);

    bloc.add(IniciarTurno({const Posicion(0, 0): 1}));
    await bloc.stream.firstWhere(
      (state) => state.fase == FaseTurno.seleccionandoAncla,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: bloc, child: const PanelDados()),
        ),
      ),
    );

    for (final dadoKey in const ['dado-1', 'dado-2']) {
      final dado = find.byKey(ValueKey(dadoKey));
      expect(
        find.descendant(of: dado, matching: find.byType(RotationTransition)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dado, matching: find.byType(ScaleTransition)),
        findsOneWidget,
      );
    }

    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('avisa cuando el turno se salta automáticamente', (tester) async {
    var siguienteDado = 2;
    final bloc = JuegoBloc(tirarDado: () => siguienteDado++);
    addTearDown(bloc.close);
    const casillaVacia = Posicion(0, 2);
    final valoresIniciales = {
      for (var fila = 0; fila < 7; fila++)
        for (var columna = 0; columna < 7; columna++)
          if (Posicion(fila, columna) != casillaVacia)
            Posicion(fila, columna): 1,
      const Posicion(0, 1): 2,
      const Posicion(0, 3): 3,
    };

    bloc.add(IniciarTurno(valoresIniciales));
    await bloc.stream.firstWhere(
      (state) => state.fase == FaseTurno.turnoTerminado,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: bloc, child: const PanelDados()),
        ),
      ),
    );

    expect(
      find.text(
        'No hay jugadas válidas con esta tirada. Turno saltado automáticamente.',
      ),
      findsOneWidget,
    );
  });
}

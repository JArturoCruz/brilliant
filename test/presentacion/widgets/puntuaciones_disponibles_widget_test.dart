import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/region.dart';
import 'package:brilliant/presentacion/widgets/puntuaciones_disponibles_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra cada zona y sus tres puntuaciones activas', (
    tester,
  ) async {
    final juegoBloc = JuegoBloc(mapa: MapaTablero.mapa1);
    final zonaCubit = ZonaInicialCubit(mapa: MapaTablero.mapa1);
    addTearDown(juegoBloc.close);
    addTearDown(zonaCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: juegoBloc),
            BlocProvider.value(value: zonaCubit),
          ],
          child: const Scaffold(
            body: PuntuacionesDisponiblesWidget(mapa: MapaTablero.mapa1),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNWidgets(9));
    expect(find.text('Verde izq.'), findsOneWidget);
    expect(find.text('Verde der.'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('regla-simbolo-azul1')))
          .data,
      '=',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('regla-simbolo-verde1')))
          .data,
      '?',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('regla-simbolo-roja1')))
          .data,
      '≠',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('regla-simbolo-morada1')))
          .data,
      'XO',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('regla-simbolo-amarilla')))
          .data,
      '≠',
    );
    for (var puesto = 1; puesto <= 3; puesto++) {
      final premio = tester.widget<Text>(
        find.byKey(ValueKey('puntuacion-roja1-$puesto')),
      );
      expect(premio.style!.color, Colors.amberAccent);
      expect(premio.style!.decoration, TextDecoration.none);
    }
  });

  testWidgets('muestra en naranja el rango de cada zona del mapa 4', (
    tester,
  ) async {
    final juegoBloc = JuegoBloc(mapa: MapaTablero.mapa4);
    final zonaCubit = ZonaInicialCubit(mapa: MapaTablero.mapa4);
    addTearDown(juegoBloc.close);
    addTearDown(zonaCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: juegoBloc),
            BlocProvider.value(value: zonaCubit),
          ],
          child: const Scaffold(
            body: PuntuacionesDisponiblesWidget(mapa: MapaTablero.mapa4),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('regla-simbolo-naranjaInferior')),
          )
          .data,
      '1-3',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('regla-simbolo-naranjaSuperior')),
          )
          .data,
      '4-6',
    );
  });

  testWidgets('al completar la primera zona roja atenúa su primer premio', (
    tester,
  ) async {
    final juegoBloc = JuegoBloc(mapa: MapaTablero.mapa1);
    final zonaCubit = ZonaInicialCubit(mapa: MapaTablero.mapa1);
    addTearDown(juegoBloc.close);
    addTearDown(zonaCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: juegoBloc),
            BlocProvider.value(value: zonaCubit),
          ],
          child: const Scaffold(
            body: PuntuacionesDisponiblesWidget(mapa: MapaTablero.mapa1),
          ),
        ),
      ),
    );

    await _completarZonaRojaIzquierda(tester, juegoBloc);

    final primerPremio = tester.widget<Text>(
      find.byKey(const ValueKey('puntuacion-roja1-1')),
    );
    final segundoPremio = tester.widget<Text>(
      find.byKey(const ValueKey('puntuacion-roja1-2')),
    );
    expect(primerPremio.style!.color, Colors.grey.shade700);
    expect(primerPremio.style!.decoration, TextDecoration.lineThrough);
    expect(segundoPremio.style!.color, Colors.amberAccent);
    expect(segundoPremio.style!.decoration, TextDecoration.none);

    final primerPremioZonaRojaDerecha = tester.widget<Text>(
      find.byKey(const ValueKey('puntuacion-roja2-1')),
    );
    expect(primerPremioZonaRojaDerecha.style!.color, Colors.amberAccent);
    expect(primerPremioZonaRojaDerecha.style!.decoration, TextDecoration.none);
  });
}

Future<void> _completarZonaRojaIzquierda(
  WidgetTester tester,
  JuegoBloc bloc,
) async {
  bloc.add(
    IniciarTurno({
      const Posicion(2, 1): 1,
      const Posicion(2, 2): 2,
      const Posicion(3, 1): 3,
      const Posicion(4, 1): 4,
      const Posicion(5, 0): 5,
    }),
  );
  await _esperarFase(tester, bloc, FaseTurno.seleccionandoAncla);

  bloc.add(
    SeleccionarNumeroAncla(
      numeroElegido: 5,
      numeroParaColocar: 6,
      indiceDado: 0,
    ),
  );
  await _esperarFase(tester, bloc, FaseTurno.seleccionandoCasilla);

  bloc.add(const SeleccionarCasillaAncla(5, 0));
  await _esperarFase(tester, bloc, FaseTurno.colocandoNumero);

  bloc.add(const ColocarNumero(5, 1));
  await _esperarFase(tester, bloc, FaseTurno.confirmandoJugada);

  bloc.add(ConfirmarJugada());
  await _esperarFase(tester, bloc, FaseTurno.turnoTerminado);
}

Future<void> _esperarFase(
  WidgetTester tester,
  JuegoBloc bloc,
  FaseTurno fase,
) async {
  await bloc.stream.firstWhere((state) => state.fase == fase);
  await tester.pumpAndSettle();
}

import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/seleccion_mapa/widgets/vista_previa_mapa.dart';
import 'package:brilliant/presentacion/widgets/celda_tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(ZonaInicialCubit cubit, Widget hijo, {JuegoBloc? bloc}) {
  final juegoBloc = bloc ?? JuegoBloc();
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

Widget _celda(
  Posicion pos, {
  MapaTablero mapa = MapaTablero.mapa1,
  Casilla? casilla,
}) {
  return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
    builder: (context, state) => CeldaTableroWidget(
      posicion: pos,
      state: state,
      mapa: mapa,
      casillaJuego: casilla,
    ),
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

  testWidgets(
    'los números son blancos con contorno fino también en gris y en vistas previas',
    (tester) async {
      const posicion = Posicion(0, 3);
      final cubit = ZonaInicialCubit(mapa: MapaTablero.mapa2);
      final bloc = JuegoBloc(mapa: MapaTablero.mapa2);
      final casilla = Casilla(fila: 0, columna: 3, valorActual: 5);
      await tester.pumpWidget(
        _envolver(
          cubit,
          _celda(posicion, mapa: MapaTablero.mapa2, casilla: casilla),
          bloc: bloc,
        ),
      );

      void comprobarNumero(String valor) {
        final texto = tester.widget<Text>(find.text(valor));
        expect(texto.style!.color, Colors.white);
        expect(texto.style!.shadows, isNotEmpty);
        expect(
          texto.style!.shadows!.every(
            (s) => s.blurRadius == 0 && s.offset.distance <= 1,
          ),
          isTrue,
        );
      }

      comprobarNumero('5');
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        const Color(0xFFD0D0D0),
      );
      cubit.restaurarDesdeServidor(valores: const {}, iniciada: true);
      await tester.pumpAndSettle();
      comprobarNumero('5');

      bloc.add(
        SincronizarJuegoMultijugador(
          bloc.state.copyWith(
            fase: FaseTurno.confirmandoJugada,
            numeroColocar: 3,
            filaProvisional: 0,
            columnaProvisional: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      comprobarNumero('3');
      await tester.pumpWidget(const SizedBox.shrink());
      cubit.close();
      bloc.close();

      final valores = List.generate(7, (_) => List<int?>.filled(7, null));
      valores[0][3] = 5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VistaPreviaMapa(mapa: MapaTablero.mapa2, valores: valores),
          ),
        ),
      );
      comprobarNumero('5');
      final fondos = tester.widgetList<Container>(
        find.ancestor(of: find.text('5'), matching: find.byType(Container)),
      );
      expect(
        fondos.any(
          (w) =>
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color == const Color(0xFFD0D0D0),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'resalta anclas y destinos con borde brillante y contorno contrastante',
    (tester) async {
      final cubit = ZonaInicialCubit();
      final bloc = JuegoBloc();
      final ancla = Casilla(
        fila: 0,
        columna: 0,
        valorActual: 1,
        iluminacion: EstadoIluminacion.posibleAncla,
      );
      final destino = Casilla(
        fila: 0,
        columna: 1,
        iluminacion: EstadoIluminacion.posibleColocacion,
      );
      await tester.pumpWidget(
        _envolver(
          cubit,
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: _celda(const Posicion(0, 0), casilla: ancla),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: _celda(const Posicion(0, 1), casilla: destino),
              ),
            ],
          ),
          bloc: bloc,
        ),
      );
      final decoraciones = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((widget) => widget.decoration! as BoxDecoration)
          .toList();
      expect(decoraciones, hasLength(2));
      for (final decoracion in decoraciones) {
        final borde = decoracion.border! as Border;
        final anillo = decoracion.boxShadow!.last.color;
        final fondoAnillo = Color.alphaBlend(anillo, decoracion.color!);
        final contraste =
            (borde.top.color.computeLuminance() + 0.05) /
            (fondoAnillo.computeLuminance() + 0.05);
        expect(borde.top.width, greaterThanOrEqualTo(3));
        expect(contraste, greaterThan(4.5));
      }
      expect(
        (decoraciones[0].border! as Border).top.color,
        isNot((decoraciones[1].border! as Border).top.color),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      cubit.close();
      bloc.close();
    },
  );

  testWidgets('tocar una celda de la ZonaInicial la selecciona en el cubit', (
    tester,
  ) async {
    final cubit = ZonaInicialCubit();
    final pos = ZonaInicial.posiciones[2];

    await tester.pumpWidget(_envolver(cubit, _celda(pos)));

    await tester.tap(find.byType(GestureDetector));
    expect(cubit.state.seleccionada, pos);
    cubit.close();
  });

  testWidgets('una celda fuera de la ZonaInicial no muestra "?" ni número', (
    tester,
  ) async {
    final cubit = ZonaInicialCubit();
    // La esquina (0,0) es amarilla pero no es una de las 6 celdas de la ZonaInicial.
    const celdaFueraDeZona = Posicion(0, 0);
    expect(ZonaInicial.posiciones.contains(celdaFueraDeZona), isFalse);

    await tester.pumpWidget(_envolver(cubit, _celda(celdaFueraDeZona)));

    expect(find.text('?'), findsNothing);
    cubit.close();
  });

  testWidgets(
    'tocar una celda fuera de la ZonaInicial no cambia la selección',
    (tester) async {
      final cubit = ZonaInicialCubit();
      const celdaFueraDeZona = Posicion(0, 0);
      final seleccionPrevia = cubit.state.seleccionada;

      await tester.pumpWidget(_envolver(cubit, _celda(celdaFueraDeZona)));
      await tester.tap(find.byType(GestureDetector));

      expect(cubit.state.seleccionada, seleccionPrevia);
      cubit.close();
    },
  );
}

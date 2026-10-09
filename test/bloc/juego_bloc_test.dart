import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JuegoBloc', () {
    late JuegoBloc bloc;

    setUp(() {
      bloc = JuegoBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('arranca con un tablero vacío y la fase inicial', () {
      final state = bloc.state;

      expect(state.fase, FaseTurno.inicio);
      expect(state.puntuacionTotal, 0);
      expect(state.historial, isEmpty);
      expect(state.tablero.length, 7);
      expect(state.tablero.every((fila) => fila.length == 7), isTrue);
      expect(
        state.tablero
            .expand((fila) => fila)
            .every((casilla) => casilla.valorActual == null),
        isTrue,
      );
    });

    test(
      'iniciar turno inicializa el tablero y prepara la selección de ancla',
      () async {
        const posicionInicial = Posicion(0, 0);

        bloc.add(IniciarTurno({posicionInicial: 4}));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoAncla,
        );

        expect(bloc.state.fase, FaseTurno.seleccionandoAncla);
        expect(bloc.state.dado1, isNotNull);
        expect(bloc.state.dado2, isNotNull);
        expect(bloc.state.tablero[0][0].valorActual, 4);
        expect(bloc.state.historial.first, contains('Dados tirados'));
      },
    );

    test('no tira los dados cuando el tablero ya está completo', () async {
      final valoresIniciales = {
        for (var fila = 0; fila < 7; fila++)
          for (var columna = 0; columna < 7; columna++)
            Posicion(fila, columna): 1,
      };

      bloc.add(IniciarTurno(valoresIniciales));
      await bloc.stream.firstWhere(
        (state) => state.fase == FaseTurno.turnoTerminado,
      );

      expect(bloc.state.tableroCompleto, isTrue);
      expect(bloc.state.dado1, isNull);
      expect(bloc.state.dado2, isNull);
      expect(bloc.state.historial, isEmpty);
    });

    test(
      'seleccionar un número y una casilla activa la fase de colocación',
      () async {
        bloc.add(IniciarTurno({const Posicion(0, 0): 3}));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoAncla,
        );

        bloc.add(
          SeleccionarNumeroAncla(
            numeroElegido: 3,
            numeroParaColocar: 5,
            indiceDado: 1,
          ),
        );
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoCasilla,
        );

        expect(bloc.state.numeroAncla, 3);
        expect(bloc.state.numeroColocar, 5);
        expect(bloc.state.indiceDadoAncla, 1);
        expect(bloc.state.fase, FaseTurno.seleccionandoCasilla);
        expect(
          bloc.state.tablero[0][0].iluminacion,
          EstadoIluminacion.posibleAncla,
        );

        bloc.add(SeleccionarCasillaAncla(0, 0));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.colocandoNumero,
        );

        expect(bloc.state.fase, FaseTurno.colocandoNumero);
        expect(bloc.state.filaAncla, 0);
        expect(bloc.state.columnaAncla, 0);
      },
    );

    test(
      'solo ilumina como ancla las celdas con al menos un movimiento legal',
      () async {
        bloc.add(
          IniciarTurno({
            const Posicion(0, 0): 2,
            const Posicion(3, 3): 2,
            const Posicion(2, 3): 1,
            const Posicion(4, 3): 2,
            const Posicion(3, 2): 3,
            const Posicion(3, 4): 4,
          }),
        );
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoAncla,
        );

        bloc.add(
          SeleccionarNumeroAncla(
            numeroElegido: 2,
            numeroParaColocar: 5,
            indiceDado: 0,
          ),
        );
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoCasilla,
        );

        expect(
          bloc.state.tablero[0][0].iluminacion,
          EstadoIluminacion.posibleAncla,
        );
        expect(bloc.state.tablero[3][3].iluminacion, EstadoIluminacion.ninguno);
      },
    );

    test(
      'cada zona roja otorga su puntuación máxima de forma independiente',
      () async {
        Future<void> completarZona({
          required Map<Posicion, int> valoresIniciales,
          required Posicion ancla,
          required Posicion destino,
        }) async {
          bloc.add(IniciarTurno(valoresIniciales));
          await bloc.stream.firstWhere(
            (state) => state.fase == FaseTurno.seleccionandoAncla,
          );

          bloc.add(
            SeleccionarNumeroAncla(
              numeroElegido: 5,
              numeroParaColocar: 6,
              indiceDado: 0,
            ),
          );
          await bloc.stream.firstWhere(
            (state) => state.fase == FaseTurno.seleccionandoCasilla,
          );

          bloc.add(SeleccionarCasillaAncla(ancla.fila, ancla.columna));
          await bloc.stream.firstWhere(
            (state) => state.fase == FaseTurno.colocandoNumero,
          );
          expect(
            bloc.state.tablero[destino.fila][destino.columna].iluminacion,
            EstadoIluminacion.posibleColocacion,
          );

          bloc.add(ColocarNumero(destino.fila, destino.columna));
          await bloc.stream.firstWhere(
            (state) => state.fase == FaseTurno.confirmandoJugada,
          );

          bloc.add(ConfirmarJugada());
          await bloc.stream.firstWhere(
            (state) => state.fase == FaseTurno.turnoTerminado,
          );
        }

        await completarZona(
          valoresIniciales: {
            const Posicion(2, 1): 1,
            const Posicion(2, 2): 2,
            const Posicion(3, 1): 3,
            const Posicion(4, 1): 4,
            const Posicion(5, 0): 5,
            const Posicion(4, 4): 1,
            const Posicion(4, 5): 2,
            const Posicion(5, 3): 3,
            const Posicion(5, 4): 4,
            const Posicion(6, 3): 5,
          },
          ancla: const Posicion(5, 0),
          destino: const Posicion(5, 1),
        );

        expect(bloc.state.puntuacionTotal, 8);
        expect(bloc.state.contadorCompletadasPorRegion['roja1'], 1);
        expect(bloc.state.contadorCompletadasPorRegion['roja2'], isNull);

        await completarZona(
          valoresIniciales: const {},
          ancla: const Posicion(6, 3),
          destino: const Posicion(6, 4),
        );

        expect(bloc.state.puntuacionTotal, 16);
        expect(bloc.state.contadorCompletadasPorRegion['roja1'], 1);
        expect(bloc.state.contadorCompletadasPorRegion['roja2'], 1);
      },
    );

    test(
      'colocar y confirmar una jugada actualiza el tablero y termina el turno',
      () async {
        bloc.add(IniciarTurno({const Posicion(0, 0): 3}));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoAncla,
        );

        bloc.add(
          SeleccionarNumeroAncla(
            numeroElegido: 3,
            numeroParaColocar: 5,
            indiceDado: 0,
          ),
        );
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoCasilla,
        );

        bloc.add(SeleccionarCasillaAncla(0, 0));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.colocandoNumero,
        );

        final stateConAncla = bloc.state;
        int? filaDestino;
        int? columnaDestino;
        for (var fila = 0; fila < 7; fila++) {
          for (var columna = 0; columna < 7; columna++) {
            if (stateConAncla.tablero[fila][columna].iluminacion ==
                EstadoIluminacion.posibleColocacion) {
              filaDestino = fila;
              columnaDestino = columna;
              break;
            }
          }
          if (filaDestino != null) break;
        }

        expect(filaDestino, isNotNull);
        expect(columnaDestino, isNotNull);
        final destinoFila = filaDestino!;
        final destinoColumna = columnaDestino!;

        bloc.add(ColocarNumero(destinoFila, destinoColumna));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.confirmandoJugada,
        );

        expect(bloc.state.fase, FaseTurno.confirmandoJugada);
        expect(bloc.state.filaProvisional, destinoFila);
        expect(bloc.state.columnaProvisional, destinoColumna);

        bloc.add(ConfirmarJugada());
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.turnoTerminado,
        );

        expect(bloc.state.fase, FaseTurno.turnoTerminado);
        expect(bloc.state.tablero[destinoFila][destinoColumna].valorActual, 5);
        expect(bloc.state.historial.first, contains('Colocado'));
      },
    );

    test(
      'cancelar la confirmación devuelve la jugada a la fase de colocación',
      () async {
        bloc.add(IniciarTurno({const Posicion(0, 0): 3}));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoAncla,
        );

        bloc.add(
          SeleccionarNumeroAncla(
            numeroElegido: 3,
            numeroParaColocar: 2,
            indiceDado: 2,
          ),
        );
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.seleccionandoCasilla,
        );

        bloc.add(SeleccionarCasillaAncla(0, 0));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.colocandoNumero,
        );

        final stateConAncla = bloc.state;
        int? filaDestino;
        int? columnaDestino;
        for (var fila = 0; fila < 7; fila++) {
          for (var columna = 0; columna < 7; columna++) {
            if (stateConAncla.tablero[fila][columna].iluminacion ==
                EstadoIluminacion.posibleColocacion) {
              filaDestino = fila;
              columnaDestino = columna;
              break;
            }
          }
          if (filaDestino != null) break;
        }

        expect(filaDestino, isNotNull);
        expect(columnaDestino, isNotNull);

        bloc.add(ColocarNumero(filaDestino!, columnaDestino!));
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.confirmandoJugada,
        );

        bloc.add(CancelarConfirmacion());
        await bloc.stream.firstWhere(
          (state) => state.fase == FaseTurno.colocandoNumero,
        );

        expect(bloc.state.fase, FaseTurno.colocandoNumero);
        expect(bloc.state.filaProvisional, isNull);
        expect(bloc.state.columnaProvisional, isNull);
      },
    );

    test('saltar turno registra el evento y termina la fase actual', () async {
      bloc.add(IniciarTurno({const Posicion(0, 0): 2}));
      await bloc.stream.firstWhere(
        (state) => state.fase == FaseTurno.seleccionandoAncla,
      );

      bloc.add(SaltarTurno());
      await bloc.stream.firstWhere(
        (state) => state.fase == FaseTurno.turnoTerminado,
      );

      expect(bloc.state.fase, FaseTurno.turnoTerminado);
      expect(bloc.state.historial.first, contains('Turno saltado'));
    });
  });
}

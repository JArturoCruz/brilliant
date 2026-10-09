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

    test('iniciar turno inicializa el tablero y prepara la selección de ancla', () {
      const posicionInicial = Posicion(0, 0);

      bloc.add(IniciarTurno({posicionInicial: 4}));

      expect(bloc.state.fase, FaseTurno.seleccionandoAncla);
      expect(bloc.state.dado1, isNotNull);
      expect(bloc.state.dado2, isNotNull);
      expect(bloc.state.tablero[0][0].valorActual, 4);
      expect(bloc.state.historial.first, contains('Dados tirados'));
    });

    test('seleccionar un número y una casilla activa la fase de colocación', () {
      bloc.add(IniciarTurno({const Posicion(0, 0): 3}));
      bloc.add(
        SeleccionarNumeroAncla(
          numeroElegido: 3,
          numeroParaColocar: 5,
          indiceDado: 1,
        ),
      );

      expect(bloc.state.numeroAncla, 3);
      expect(bloc.state.numeroColocar, 5);
      expect(bloc.state.indiceDadoAncla, 1);
      expect(bloc.state.fase, FaseTurno.seleccionandoCasilla);
      expect(bloc.state.tablero[0][0].iluminacion, EstadoIluminacion.posibleAncla);

      bloc.add(SeleccionarCasillaAncla(0, 0));

      expect(bloc.state.fase, FaseTurno.colocandoNumero);
      expect(bloc.state.filaAncla, 0);
      expect(bloc.state.columnaAncla, 0);
    });

    test('colocar y confirmar una jugada actualiza el tablero y termina el turno', () {
      bloc.add(IniciarTurno({const Posicion(0, 0): 3}));
      bloc.add(
        SeleccionarNumeroAncla(
          numeroElegido: 3,
          numeroParaColocar: 5,
          indiceDado: 0,
        ),
      );
      bloc.add(SeleccionarCasillaAncla(0, 0));

      int? filaDestino;
      int? columnaDestino;
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          if (bloc.state.tablero[fila][columna].iluminacion ==
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
      expect(bloc.state.fase, FaseTurno.confirmandoJugada);
      expect(bloc.state.filaProvisional, filaDestino);
      expect(bloc.state.columnaProvisional, columnaDestino);

      bloc.add(ConfirmarJugada());

      expect(bloc.state.fase, FaseTurno.turnoTerminado);
      expect(bloc.state.tablero[filaDestino!][columnaDestino!].valorActual, 5);
      expect(bloc.state.historial.first, contains('Colocado'));
    });

    test('cancelar la confirmación devuelve la jugada a la fase de colocación', () {
      bloc.add(IniciarTurno({const Posicion(0, 0): 3}));
      bloc.add(
        SeleccionarNumeroAncla(
          numeroElegido: 3,
          numeroParaColocar: 2,
          indiceDado: 2,
        ),
      );
      bloc.add(SeleccionarCasillaAncla(0, 0));

      int? filaDestino;
      int? columnaDestino;
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          if (bloc.state.tablero[fila][columna].iluminacion ==
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
      bloc.add(CancelarConfirmacion());

      expect(bloc.state.fase, FaseTurno.colocandoNumero);
      expect(bloc.state.filaProvisional, isNull);
      expect(bloc.state.columnaProvisional, isNull);
    });

    test('saltar turno registra el evento y termina la fase actual', () {
      bloc.add(IniciarTurno({const Posicion(0, 0): 2}));

      bloc.add(SaltarTurno());

      expect(bloc.state.fase, FaseTurno.turnoTerminado);
      expect(bloc.state.historial.first, contains('Turno saltado'));
    });
  });
}

import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/dado.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'juego_event.dart';
import 'juego_state.dart';

class JuegoBloc extends Bloc<JuegoEvent, JuegoState> {
  JuegoBloc() : super(_estadoInicial()) {
    on<IniciarTurno>(_onIniciarTurno);
    on<SeleccionarNumeroAncla>(_onSeleccionarNumeroAncla);
    on<SeleccionarCasillaAncla>(_onSeleccionarCasillaAncla);
  }

  static JuegoState _estadoInicial() {
    // Inicializa el tablero 7x7 VACÍO (valorActual en null)
    List<List<Casilla>> tableroInicial = List.generate(
      7,
      (f) => List.generate(7, (c) => Casilla(fila: f, columna: c, valorActual: null)),
    );
    return JuegoState(tablero: tableroInicial);
  }

  void _onIniciarTurno(IniciarTurno event, Emitter<JuegoState> emit) {
    // 1. Copiamos el tablero vacío
    var nuevoTablero = state.tablero.map((f) => f.map((c) => c).toList()).toList();

    // 2. Colocamos únicamente los 6 números iniciales en sus posiciones
    event.valoresIniciales.forEach((posicion, valor) {
      nuevoTablero[posicion.fila][posicion.columna] = 
          nuevoTablero[posicion.fila][posicion.columna].copyWith(valorActual: valor);
    });

    // 3. Tiramos los 2 dados
    emit(state.copyWith(
      tablero: nuevoTablero,
      dado1: Dado.tirar(),
      dado2: Dado.tirar(),
      fase: FaseTurno.seleccionandoAncla,
    ));
  }

  void _onSeleccionarNumeroAncla(SeleccionarNumeroAncla event, Emitter<JuegoState> emit) {
    var nuevoTablero = state.tablero.map((fila) {
      return fila.map((casilla) {
        if (casilla.valorActual == event.numeroElegido) {
          return casilla.copyWith(iluminacion: EstadoIluminacion.posibleAncla);
        }
        return casilla.copyWith(iluminacion: EstadoIluminacion.ninguno);
      }).toList();
    }).toList();

    emit(state.copyWith(
      tablero: nuevoTablero,
      numeroAncla: event.numeroElegido,
      numeroColocar: event.numeroParaColocar,
      fase: FaseTurno.seleccionandoCasilla,
    ));
  }

  void _onSeleccionarCasillaAncla(SeleccionarCasillaAncla event, Emitter<JuegoState> emit) {
    var nuevoTablero = state.tablero.map((f) => f.map((c) => c.copyWith(iluminacion: EstadoIluminacion.ninguno)).toList()).toList();

    nuevoTablero[event.fila][event.columna] = nuevoTablero[event.fila][event.columna].copyWith(iluminacion: EstadoIluminacion.posibleAncla);

    final movimientos = [
      [-1, 0], [1, 0], [0, -1], [0, 1]
    ];

    for (var mov in movimientos) {
      int nFila = event.fila + mov[0];
      int nCol = event.columna + mov[1];

      if (nFila >= 0 && nFila < 7 && nCol >= 0 && nCol < 7) {
        // Opcional: Solo iluminar si la casilla adyacente está vacía
        if (nuevoTablero[nFila][nCol].valorActual == null) {
          nuevoTablero[nFila][nCol] = nuevoTablero[nFila][nCol].copyWith(
            iluminacion: EstadoIluminacion.posibleColocacion,
          );
        }
      }
    }

    emit(state.copyWith(
      tablero: nuevoTablero,
      fase: FaseTurno.colocandoNumero,
    ));
  }
}
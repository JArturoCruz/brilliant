import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/dado.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'juego_event.dart';
import 'juego_state.dart';

import '../../dominio/topologia_tablero.dart';
import '../../dominio/tipos/tipos_de_region.dart';

class JuegoBloc extends Bloc<JuegoEvent, JuegoState> {
  JuegoBloc() : super(_estadoInicial()) {
    on<IniciarTurno>(_onIniciarTurno);
    on<SeleccionarNumeroAncla>(_onSeleccionarNumeroAncla);
    on<SeleccionarCasillaAncla>(_onSeleccionarCasillaAncla);
    on<ColocarNumero>(_onColocarNumero);
    on<CancelarSeleccionAncla>(_onCancelarSeleccionAncla);
  }

  static JuegoState _estadoInicial() {
    List<List<Casilla>> tableroInicial = List.generate(
      7,
      (f) => List.generate(7, (c) => Casilla(fila: f, columna: c, valorActual: null)),
    );
    return JuegoState(tablero: tableroInicial);
  }

  void _onIniciarTurno(IniciarTurno event, Emitter<JuegoState> emit) {
    var nuevoTablero = state.tablero.map((f) => f.map((c) => c).toList()).toList();

    event.valoresIniciales.forEach((posicion, valor) {
      nuevoTablero[posicion.fila][posicion.columna] = 
          nuevoTablero[posicion.fila][posicion.columna].copyWith(valorActual: valor);
    });

    emit(state.copyWith(
      tablero: nuevoTablero,
      dado1: Dado.tirar(),
      dado2: Dado.tirar(),
      indiceDadoAncla: -1,
      fase: FaseTurno.seleccionandoAncla,
    ));
  }

  void _onSeleccionarNumeroAncla(SeleccionarNumeroAncla event, Emitter<JuegoState> emit) {
    // REGLA ESTRICTA: Solo las casillas cuyo valor sea EXACTAMENTE igual al número del dado elegido se iluminan como ancla.
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
      indiceDadoAncla: event.indiceDado,
      fase: FaseTurno.seleccionandoCasilla,
    ));
  }

  void _onSeleccionarCasillaAncla(SeleccionarCasillaAncla event, Emitter<JuegoState> emit) {
    final casillaSeleccionada = state.tablero[event.fila][event.columna];

    // Si toca una celda que NO está iluminada como posible ancla, ignoramos el toque por completo.
    if (casillaSeleccionada.iluminacion != EstadoIluminacion.posibleAncla) {
      return;
    }

    // Si vuelve a tocar la misma celda ancla exacta, permitimos cancelar/cambiar de opinión
    if (casillaSeleccionada.valorActual == state.numeroAncla && 
        casillaSeleccionada.iluminacion == EstadoIluminacion.posibleAncla &&
        state.fase == FaseTurno.colocandoNumero) {
      add(CancelarSeleccionAncla());
      return;
    }

    var nuevoTablero = state.tablero.map((fila) {
      return fila.map((casilla) {
        if (casilla.valorActual == state.numeroAncla) {
          return casilla.copyWith(iluminacion: EstadoIluminacion.posibleAncla);
        }
        return casilla.copyWith(iluminacion: EstadoIluminacion.ninguno);
      }).toList();
    }).toList();

    nuevoTablero[event.fila][event.columna] = nuevoTablero[event.fila][event.columna].copyWith(
      iluminacion: EstadoIluminacion.posibleAncla,
    );

    // Movimientos adyacentes estrictos: Arriba, Abajo, Izquierda, Derecha (sin diagonales)
    final movimientos = [[-1, 0], [1, 0], [0, -1], [0, 1]];

    for (var mov in movimientos) {
      int nFila = event.fila + mov[0];
      int nCol = event.columna + mov[1];

      if (nFila >= 0 && nFila < 7 && nCol >= 0 && nCol < 7) {
        if (nuevoTablero[nFila][nCol].valorActual == null) {
          bool movimientoPermitido = _validarReglaDeRegion(nFila, nCol, state.numeroColocar!);

          if (movimientoPermitido) {
            nuevoTablero[nFila][nCol] = nuevoTablero[nFila][nCol].copyWith(
              iluminacion: EstadoIluminacion.posibleColocacion,
            );
          }
        }
      }
    }

    emit(state.copyWith(tablero: nuevoTablero, fase: FaseTurno.colocandoNumero));
  }

  void _onCancelarSeleccionAncla(CancelarSeleccionAncla event, Emitter<JuegoState> emit) {
    var nuevoTablero = state.tablero.map((fila) {
      return fila.map((casilla) {
        if (casilla.valorActual == state.numeroAncla) {
          return casilla.copyWith(iluminacion: EstadoIluminacion.posibleAncla);
        }
        return casilla.copyWith(iluminacion: EstadoIluminacion.ninguno);
      }).toList();
    }).toList();

    emit(state.copyWith(
      tablero: nuevoTablero,
      fase: FaseTurno.seleccionandoCasilla,
    ));
  }

  void _onColocarNumero(ColocarNumero event, Emitter<JuegoState> emit) {
    if (state.tablero[event.fila][event.columna].iluminacion != EstadoIluminacion.posibleColocacion) return;

    var nuevoTablero = state.tablero.map((f) => f.map((c) => c.copyWith(iluminacion: EstadoIluminacion.ninguno)).toList()).toList();

    nuevoTablero[event.fila][event.columna] = nuevoTablero[event.fila][event.columna].copyWith(
      valorActual: state.numeroColocar,
    );

    emit(state.copyWith(tablero: nuevoTablero, fase: FaseTurno.turnoTerminado));
  }

  bool _validarReglaDeRegion(int fDestino, int cDestino, int numeroColocar) {
    final regionDestino = TopologiaTablero.regionDeCelda(fDestino, cDestino);
    if (regionDestino == null) return false;

    final tipoRegion = TiposDeRegion.obtenerTipo(regionDestino);

    List<int> numerosActualesEnRegion = [];
    
    for (var f = 0; f < TopologiaTablero.filas; f++) {
      for (var c = 0; c < TopologiaTablero.columnas; c++) {
        final regActual = TopologiaTablero.regionDeCelda(f, c);
        if (regActual == regionDestino) {
          final valorCelda = state.tablero[f][c].valorActual;
          if (valorCelda != null) {
            numerosActualesEnRegion.add(valorCelda);
          }
        }
      }
    }

    return tipoRegion.esPosibleAgregar(numerosActualesEnRegion, numeroColocar);
  }
}
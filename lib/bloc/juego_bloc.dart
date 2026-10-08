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
    on<ConfirmarJugada>(_onConfirmarJugada);
    on<CancelarConfirmacion>(_onCancelarConfirmacion);
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
      filaProvisional: null,
      columnaProvisional: null,
      filaAncla: null,
      columnaAncla: null,
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
      indiceDadoAncla: event.indiceDado,
      fase: FaseTurno.seleccionandoCasilla,
      filaAncla: null,
      columnaAncla: null,
      filaProvisional: null,
      columnaProvisional: null,
    ));
  }

  void _onSeleccionarCasillaAncla(SeleccionarCasillaAncla event, Emitter<JuegoState> emit) {
    final casillaSeleccionada = state.tablero[event.fila][event.columna];

    if (casillaSeleccionada.iluminacion != EstadoIluminacion.posibleAncla) {
      return;
    }

    if (casillaSeleccionada.valorActual == state.numeroAncla && 
        casillaSeleccionada.iluminacion == EstadoIluminacion.posibleAncla &&
        state.fase == FaseTurno.colocandoNumero) {
      add(CancelarSeleccionAncla());
      return;
    }

    var nuevoTablero = state.tablero.map((fila) {
      return fila.map((casilla) {
        return casilla.copyWith(iluminacion: EstadoIluminacion.ninguno);
      }).toList();
    }).toList();

    nuevoTablero[event.fila][event.columna] = nuevoTablero[event.fila][event.columna].copyWith(
      iluminacion: EstadoIluminacion.posibleAncla,
    );

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

    emit(state.copyWith(
      tablero: nuevoTablero, 
      fase: FaseTurno.colocandoNumero,
      filaProvisional: null,
      columnaProvisional: null,
      filaAncla: event.fila,
      columnaAncla: event.columna,
    ));
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
      filaProvisional: null,
      columnaProvisional: null,
      filaAncla: null,
      columnaAncla: null,
    ));
  }

  void _onColocarNumero(ColocarNumero event, Emitter<JuegoState> emit) {
    if (state.tablero[event.fila][event.columna].iluminacion != EstadoIluminacion.posibleColocacion) return;

    // NO alteramos el tablero todavía. Solo guardamos la posición provisional y cambiamos de fase.
    var nuevoTablero = state.tablero.map((row) => row.map((casilla) => casilla.copyWith(iluminacion: EstadoIluminacion.ninguno)).toList()).toList();

    emit(state.copyWith(
      tablero: nuevoTablero,
      fase: FaseTurno.confirmandoJugada,
      filaProvisional: event.fila,
      columnaProvisional: event.columna,
    ));
  }

  void _onConfirmarJugada(ConfirmarJugada event, Emitter<JuegoState> emit) {
    if (state.filaProvisional == null || state.columnaProvisional == null) return;

    int f = state.filaProvisional!;
    int c = state.columnaProvisional!;

    var nuevoTablero = state.tablero.map((row) => row.map((casilla) => casilla.copyWith(iluminacion: EstadoIluminacion.ninguno)).toList()).toList();
    
    // AQUÍ Y SOLO AQUÍ se aplica permanentemente el número en el tablero oficial
    nuevoTablero[f][c] = nuevoTablero[f][c].copyWith(
      valorActual: state.numeroColocar,
    );

    emit(state.copyWith(
      tablero: nuevoTablero,
      fase: FaseTurno.turnoTerminado,
      filaProvisional: null,
      columnaProvisional: null,
      filaAncla: null,
      columnaAncla: null,
    ));
  }

  void _onCancelarConfirmacion(CancelarConfirmacion event, Emitter<JuegoState> emit) {
    if (state.filaAncla == null) return;

    int fAncla = state.filaAncla!;

    // El tablero NO se modificó, por lo que limpiamos las luces y restauramos las opciones verdes originales del ancla
    var nuevoTablero = state.tablero.map((row) => row.map((casilla) => casilla.copyWith(iluminacion: EstadoIluminacion.ninguno)).toList()).toList();

    nuevoTablero[fAncla][cAnclaSegura(state.columnaAncla!)] = nuevoTablero[fAncla][cAnclaSegura(state.columnaAncla!)].copyWith(
      iluminacion: EstadoIluminacion.posibleAncla,
    );

    final movimientos = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (var mov in movimientos) {
      int nFila = fAncla + mov[0];
      int nCol = cAnclaSegura(state.columnaAncla!) + mov[1];
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

    emit(state.copyWith(
      tablero: nuevoTablero,
      fase: FaseTurno.colocandoNumero,
      filaProvisional: null,
      columnaProvisional: null,
    ));
  }

  int cAnclaSegura(int c) => c;

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
import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/dado.dart';
import 'package:brilliant/dominio/tipos/tipo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../dominio/region.dart';
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
    on<SaltarTurno>(_onSaltarTurno); // NUEVO
  }

  static JuegoState _estadoInicial() {
    List<List<Casilla>> tableroInicial = List.generate(
      7,
      (f) => List.generate(
        7,
        (c) => Casilla(fila: f, columna: c, valorActual: null),
      ),
    );
    return JuegoState(tablero: tableroInicial);
  }

  void _onIniciarTurno(IniciarTurno event, Emitter<JuegoState> emit) {
    var nuevoTablero = state.tablero
        .map((f) => f.map((c) => c).toList())
        .toList();

    event.valoresIniciales.forEach((posicion, valor) {
      nuevoTablero[posicion.fila][posicion.columna] =
          nuevoTablero[posicion.fila][posicion.columna].copyWith(
            valorActual: valor,
          );
    });

    if (nuevoTablero
        .expand((fila) => fila)
        .every((casilla) => casilla.valorActual != null)) {
      emit(
        state.copyWith(
          tablero: nuevoTablero,
          dado1: null,
          dado2: null,
          fase: FaseTurno.turnoTerminado,
        ),
      );
      return;
    }

    final dado1 = Dado.tirar();
    final dado2 = Dado.tirar();

    // Registramos la tirada en el historial
    final nuevoHistorial = List<String>.from(state.historial);
    nuevoHistorial.insert(0, '🎲 Dados tirados: [$dado1] y [$dado2]');

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        dado1: dado1,
        dado2: dado2,
        indiceDadoAncla: -1,
        fase: FaseTurno.seleccionandoAncla,
        filaProvisional: null,
        columnaProvisional: null,
        filaAncla: null,
        columnaAncla: null,
        historial: nuevoHistorial,
      ),
    );
  }

  void _onSeleccionarNumeroAncla(
    SeleccionarNumeroAncla event,
    Emitter<JuegoState> emit,
  ) {
    var nuevoTablero = state.tablero.map((fila) {
      return fila.map((casilla) {
        if (casilla.valorActual == event.numeroElegido &&
            _tieneColocacionValida(
              casilla.fila,
              casilla.columna,
              event.numeroParaColocar,
            )) {
          return casilla.copyWith(iluminacion: EstadoIluminacion.posibleAncla);
        }
        return casilla.copyWith(iluminacion: EstadoIluminacion.ninguno);
      }).toList();
    }).toList();

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        numeroAncla: event.numeroElegido,
        numeroColocar: event.numeroParaColocar,
        indiceDadoAncla: event.indiceDado,
        fase: FaseTurno.seleccionandoCasilla,
        filaAncla: null,
        columnaAncla: null,
        filaProvisional: null,
        columnaProvisional: null,
      ),
    );
  }

  void _onSeleccionarCasillaAncla(
    SeleccionarCasillaAncla event,
    Emitter<JuegoState> emit,
  ) {
    final casillaSeleccionada = state.tablero[event.fila][event.columna];

    if (casillaSeleccionada.iluminacion != EstadoIluminacion.posibleAncla)
      return;

    if (casillaSeleccionada.valorActual == state.numeroAncla &&
        casillaSeleccionada.iluminacion == EstadoIluminacion.posibleAncla &&
        state.fase == FaseTurno.colocandoNumero) {
      add(CancelarSeleccionAncla());
      return;
    }

    var nuevoTablero = state.tablero.map((fila) {
      return fila
          .map(
            (casilla) =>
                casilla.copyWith(iluminacion: EstadoIluminacion.ninguno),
          )
          .toList();
    }).toList();

    nuevoTablero[event.fila][event.columna] =
        nuevoTablero[event.fila][event.columna].copyWith(
          iluminacion: EstadoIluminacion.posibleAncla,
        );

    final movimientos = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (var mov in movimientos) {
      int nFila = event.fila + mov[0];
      int nCol = event.columna + mov[1];

      if (nFila >= 0 && nFila < 7 && nCol >= 0 && nCol < 7) {
        if (nuevoTablero[nFila][nCol].valorActual == null) {
          bool movimientoPermitido = _validarReglaDeRegion(
            nFila,
            nCol,
            state.numeroColocar!,
          );
          if (movimientoPermitido) {
            nuevoTablero[nFila][nCol] = nuevoTablero[nFila][nCol].copyWith(
              iluminacion: EstadoIluminacion.posibleColocacion,
            );
          }
        }
      }
    }

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        fase: FaseTurno.colocandoNumero,
        filaProvisional: null,
        columnaProvisional: null,
        filaAncla: event.fila,
        columnaAncla: event.columna,
      ),
    );
  }

  void _onCancelarSeleccionAncla(
    CancelarSeleccionAncla event,
    Emitter<JuegoState> emit,
  ) {
    var nuevoTablero = state.tablero.map((fila) {
      return fila.map((casilla) {
        if (casilla.valorActual == state.numeroAncla &&
            state.numeroColocar != null &&
            _tieneColocacionValida(
              casilla.fila,
              casilla.columna,
              state.numeroColocar!,
            )) {
          return casilla.copyWith(iluminacion: EstadoIluminacion.posibleAncla);
        }
        return casilla.copyWith(iluminacion: EstadoIluminacion.ninguno);
      }).toList();
    }).toList();

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        fase: FaseTurno.seleccionandoCasilla,
        filaProvisional: null,
        columnaProvisional: null,
        filaAncla: null,
        columnaAncla: null,
      ),
    );
  }

  void _onColocarNumero(ColocarNumero event, Emitter<JuegoState> emit) {
    if (state.tablero[event.fila][event.columna].iluminacion !=
        EstadoIluminacion.posibleColocacion)
      return;

    var nuevoTablero = state.tablero
        .map(
          (row) => row
              .map(
                (casilla) =>
                    casilla.copyWith(iluminacion: EstadoIluminacion.ninguno),
              )
              .toList(),
        )
        .toList();

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        fase: FaseTurno.confirmandoJugada,
        filaProvisional: event.fila,
        columnaProvisional: event.columna,
      ),
    );
  }

  void _onConfirmarJugada(ConfirmarJugada event, Emitter<JuegoState> emit) {
    if (state.filaProvisional == null || state.columnaProvisional == null)
      return;

    int f = state.filaProvisional!;
    int c = state.columnaProvisional!;

    var nuevoTablero = state.tablero
        .map(
          (row) => row
              .map(
                (casilla) =>
                    casilla.copyWith(iluminacion: EstadoIluminacion.ninguno),
              )
              .toList(),
        )
        .toList();

    nuevoTablero[f][c] = nuevoTablero[f][c].copyWith(
      valorActual: state.numeroColocar,
    );

    int puntosNuevos = 0;
    var nuevasRegionesCompletadas = Set<dynamic>.from(
      state.regionesCompletadas,
    );
    var nuevoContadorRegiones = Map<String, int>.from(
      state.contadorCompletadasPorRegion,
    );
    final nuevoHistorial = List<String>.from(state.historial);

    nuevoHistorial.insert(
      0,
      '✅ Colocado [${state.numeroColocar}] en F:$f, C:$c',
    );

    for (var region in RegionTablero.values) {
      if (nuevasRegionesCompletadas.contains(region)) continue;

      if (_esRegionCompleta(nuevoTablero, region)) {
        nuevasRegionesCompletadas.add(region);

        final tipo = TiposDeRegion.obtenerTipo(region);
        final regionKey = region.name;

        int posicionActual = (nuevoContadorRegiones[regionKey] ?? 0) + 1;
        nuevoContadorRegiones[regionKey] = posicionActual;

        int puntosZona = tipo.puntosPorPosicion(posicionActual);
        puntosNuevos += puntosZona;

        nuevoHistorial.insert(
          0,
          '⭐ ¡Zona completada! ($puntosZona pts ganados)',
        );
      }
    }

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        fase: FaseTurno.turnoTerminado,
        filaProvisional: null,
        columnaProvisional: null,
        filaAncla: null,
        columnaAncla: null,
        puntuacionTotal: state.puntuacionTotal + puntosNuevos,
        regionesCompletadas: nuevasRegionesCompletadas,
        contadorCompletadasPorRegion: nuevoContadorRegiones,
        historial: nuevoHistorial,
      ),
    );
  }

  void _onCancelarConfirmacion(
    CancelarConfirmacion event,
    Emitter<JuegoState> emit,
  ) {
    if (state.filaAncla == null) return;

    int fAncla = state.filaAncla!;
    int cAncla = state.columnaAncla ?? 0;

    var nuevoTablero = state.tablero
        .map(
          (row) => row
              .map(
                (casilla) =>
                    casilla.copyWith(iluminacion: EstadoIluminacion.ninguno),
              )
              .toList(),
        )
        .toList();

    nuevoTablero[fAncla][cAncla] = nuevoTablero[fAncla][cAncla].copyWith(
      iluminacion: EstadoIluminacion.posibleAncla,
    );

    final movimientos = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    for (var mov in movimientos) {
      int nFila = fAncla + mov[0];
      int nCol = cAncla + mov[1];
      if (nFila >= 0 && nFila < 7 && nCol >= 0 && nCol < 7) {
        if (nuevoTablero[nFila][nCol].valorActual == null) {
          bool movimientoPermitido = _validarReglaDeRegion(
            nFila,
            nCol,
            state.numeroColocar!,
          );
          if (movimientoPermitido) {
            nuevoTablero[nFila][nCol] = nuevoTablero[nFila][nCol].copyWith(
              iluminacion: EstadoIluminacion.posibleColocacion,
            );
          }
        }
      }
    }

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        fase: FaseTurno.colocandoNumero,
        filaProvisional: null,
        columnaProvisional: null,
      ),
    );
  }

  void _onSaltarTurno(SaltarTurno event, Emitter<JuegoState> emit) {
    final nuevoHistorial = List<String>.from(state.historial);
    nuevoHistorial.insert(0, '⏭️ Turno saltado.');

    var nuevoTablero = state.tablero
        .map(
          (row) => row
              .map(
                (casilla) =>
                    casilla.copyWith(iluminacion: EstadoIluminacion.ninguno),
              )
              .toList(),
        )
        .toList();

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        fase: FaseTurno.turnoTerminado,
        filaProvisional: null,
        columnaProvisional: null,
        filaAncla: null,
        columnaAncla: null,
        historial: nuevoHistorial,
      ),
    );
  }

  bool _esRegionCompleta(
    List<List<Casilla>> tablero,
    RegionTablero regionBuscada,
  ) {
    bool alMenosUnaCelda = false;
    for (var f = 0; f < TopologiaTablero.filas; f++) {
      for (var c = 0; c < TopologiaTablero.columnas; c++) {
        if (TopologiaTablero.regionDeCelda(f, c) == regionBuscada) {
          alMenosUnaCelda = true;
          if (tablero[f][c].valorActual == null) return false;
        }
      }
    }
    return alMenosUnaCelda;
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
          if (valorCelda != null) numerosActualesEnRegion.add(valorCelda);
        }
      }
    }
    return tipoRegion.esPosibleAgregar(numerosActualesEnRegion, numeroColocar);
  }

  bool _tieneColocacionValida(
    int filaAncla,
    int columnaAncla,
    int numeroColocar,
  ) {
    const movimientos = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (final movimiento in movimientos) {
      final filaDestino = filaAncla + movimiento[0];
      final columnaDestino = columnaAncla + movimiento[1];

      if (filaDestino < 0 ||
          filaDestino >= TopologiaTablero.filas ||
          columnaDestino < 0 ||
          columnaDestino >= TopologiaTablero.columnas) {
        continue;
      }

      if (state.tablero[filaDestino][columnaDestino].valorActual == null &&
          _validarReglaDeRegion(filaDestino, columnaDestino, numeroColocar)) {
        return true;
      }
    }

    return false;
  }
}

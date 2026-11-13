import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/dado.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/dominio/validador_de_jugadas.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../dominio/region.dart';
import 'juego_event.dart';
import 'juego_state.dart';

import '../../dominio/topologia_tablero.dart';

class JuegoBloc extends Bloc<JuegoEvent, JuegoState> {
  JuegoBloc({this.mapa = MapaTablero.mapa1, int Function()? tirarDado})
    : _validador = ValidadorDeJugadas(mapa: mapa),
      _tirarDado = tirarDado ?? Dado.tirar,
      super(_estadoInicial()) {
    on<IniciarTurno>(_onIniciarTurno);
    on<SeleccionarNumeroAncla>(_onSeleccionarNumeroAncla);
    on<SeleccionarCasillaAncla>(_onSeleccionarCasillaAncla);
    on<ColocarNumero>(_onColocarNumero);
    on<CancelarSeleccionAncla>(_onCancelarSeleccionAncla);
    on<ConfirmarJugada>(_onConfirmarJugada);
    on<CancelarConfirmacion>(_onCancelarConfirmacion);
    on<SaltarTurno>(_onSaltarTurno); // NUEVO
    on<SincronizarJuegoMultijugador>((event, emit) => emit(event.estado));
  }

  final MapaTablero mapa;
  final ValidadorDeJugadas _validador;
  final int Function() _tirarDado;

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

    final dado1 = _tirarDado();
    final dado2 = _tirarDado();

    // Registramos la tirada en el historial
    final nuevoHistorial = List<String>.from(state.historial);
    nuevoHistorial.insert(0, '🎲 Dados tirados: [$dado1] y [$dado2]');
    final puedeJugar = _hayJugadaValida(nuevoTablero, dado1, dado2);
    if (!puedeJugar) {
      nuevoHistorial.insert(
        0,
        '⏭️ No hay jugadas válidas con esta tirada; el turno se saltó automáticamente.',
      );
    }

    emit(
      state.copyWith(
        tablero: nuevoTablero,
        dado1: dado1,
        dado2: dado2,
        indiceDadoAncla: -1,
        fase: puedeJugar
            ? FaseTurno.seleccionandoAncla
            : FaseTurno.turnoTerminado,
        filaProvisional: null,
        columnaProvisional: null,
        filaAncla: null,
        columnaAncla: null,
        turnoSaltadoAutomaticamente: !puedeJugar,
        historial: nuevoHistorial,
      ),
    );
  }

  void _onSeleccionarNumeroAncla(
    SeleccionarNumeroAncla event,
    Emitter<JuegoState> emit,
  ) {
    if (!_puedeUsarComoAncla(
      state.tablero,
      event.numeroElegido,
      event.numeroParaColocar,
    ))
      return;
    final nuevoTablero = _iluminarOpciones(
      event.numeroElegido,
      event.numeroParaColocar,
    );

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
    if (state.numeroAncla == null || state.numeroColocar == null) return;
    final nuevoTablero = _iluminarOpciones(
      state.numeroAncla!,
      state.numeroColocar!,
    );

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
        EstadoIluminacion.posibleColocacion) {
      return;
    }

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
    if (state.filaProvisional == null || state.columnaProvisional == null) {
      return;
    }

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

        final regionKey = mapa.claveGrupoPuntuacion(region);

        int posicionActual = (nuevoContadorRegiones[regionKey] ?? 0) + 1;
        nuevoContadorRegiones[regionKey] = posicionActual;

        int puntosZona = mapa.puntosPorPosicion(region, posicionActual);
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
        turnoSaltadoAutomaticamente: false,
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
        turnoSaltadoAutomaticamente: false,
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
    for (final pos in TopologiaTablero.posicionesDe(
      regionBuscada,
      mapa: mapa,
    )) {
      alMenosUnaCelda = true;
      if (tablero[pos.fila][pos.columna].valorActual == null) return false;
    }
    return alMenosUnaCelda;
  }

  bool _validarReglaDeRegion(int fDestino, int cDestino, int numeroColocar) {
    return _validarReglaDeRegionEn(
      state.tablero,
      fDestino,
      cDestino,
      numeroColocar,
    );
  }

  bool _validarReglaDeRegionEn(
    List<List<Casilla>> tablero,
    int fDestino,
    int cDestino,
    int numeroColocar,
  ) {
    final tableroJuego = TableroJuego(
      tablero
          .map((fila) => fila.map((casilla) => casilla.valorActual).toList())
          .toList(),
    );
    return _validador.puedeAsignar(
      tableroJuego,
      fDestino,
      cDestino,
      numeroColocar,
    );
  }

  bool _tieneColocacionValidaEn(
    List<List<Casilla>> tablero,
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

      if (tablero[filaDestino][columnaDestino].valorActual == null &&
          _validarReglaDeRegionEn(
            tablero,
            filaDestino,
            columnaDestino,
            numeroColocar,
          )) {
        return true;
      }
    }

    return false;
  }

  bool _hayJugadaValida(List<List<Casilla>> tablero, int dado1, int dado2) {
    return _puedeUsarComoAncla(tablero, dado1, dado2) ||
        _puedeUsarComoAncla(tablero, dado2, dado1);
  }

  bool puedeUsarComoAncla(int numero, int otro) =>
      _puedeUsarComoAncla(state.tablero, numero, otro);

  bool _puedeUsarComoAncla(List<List<Casilla>> tablero, int numero, int otro) =>
      tablero
          .expand((fila) => fila)
          .any(
            (casilla) =>
                casilla.valorActual == numero &&
                _tieneColocacionValidaEn(
                  tablero,
                  casilla.fila,
                  casilla.columna,
                  otro,
                ),
          );

  List<List<Casilla>> _iluminarOpciones(int numero, int otro) {
    final resultado = state.tablero
        .map(
          (fila) => fila
              .map(
                (celda) =>
                    celda.copyWith(iluminacion: EstadoIluminacion.ninguno),
              )
              .toList(),
        )
        .toList();
    const movimientos = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final ancla in state.tablero.expand((fila) => fila)) {
      if (ancla.valorActual != numero ||
          !_tieneColocacionValidaEn(
            state.tablero,
            ancla.fila,
            ancla.columna,
            otro,
          ))
        continue;
      resultado[ancla.fila][ancla.columna] =
          resultado[ancla.fila][ancla.columna].copyWith(
            iluminacion: EstadoIluminacion.posibleAncla,
          );
      for (final (df, dc) in movimientos) {
        final f = ancla.fila + df;
        final c = ancla.columna + dc;
        if (f >= 0 &&
            f < 7 &&
            c >= 0 &&
            c < 7 &&
            state.tablero[f][c].valorActual == null &&
            _validarReglaDeRegionEn(state.tablero, f, c, otro)) {
          resultado[f][c] = resultado[f][c].copyWith(
            iluminacion: EstadoIluminacion.posibleColocacion,
          );
        }
      }
    }
    return resultado;
  }
}

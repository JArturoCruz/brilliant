import 'package:flutter_bloc/flutter_bloc.dart';

import '../dominio/mapa_tablero.dart';
import '../dominio/navegador_zona_inicial.dart';
import '../dominio/posicion.dart';
import '../dominio/tablero.dart';
import '../dominio/validador_de_jugadas.dart';
import '../dominio/validador_entrada_zona_inicial.dart';
import '../dominio/zona_inicial.dart';
import 'mensajes_zona_inicial.dart';

part 'zona_inicial_state.dart';

/// Cubit LOCAL: controla el llenado de la ZonaInicial y decide si ya se
/// puede avanzar al resto del juego. Delega en clases del dominio la
/// validación de entradas y la navegación entre celdas; su única
/// responsabilidad propia es orquestar esas piezas y emitir el estado.
class ZonaInicialCubit extends Cubit<ZonaInicialState> {
  ZonaInicialCubit({
    ValidadorEntradaZonaInicial? validador,
    NavegadorZonaInicial? navegador,
    this.mapa = MapaTablero.mapa1,
  })  : _validador = validador ?? const ValidadorEntradaZonaInicial(),
        _navegador = navegador ?? const NavegadorZonaInicial(),
        _validadorDeJugadas = ValidadorDeJugadas(mapa: mapa),
        super(
          ZonaInicialState.inicial(
            posiciones: ZonaInicial.posicionesParaMapa(mapa),
          ),
        );

  final ValidadorEntradaZonaInicial _validador;
  final NavegadorZonaInicial _navegador;
  final ValidadorDeJugadas _validadorDeJugadas;
  final MapaTablero mapa;
  List<Posicion> get _posiciones => ZonaInicial.posicionesParaMapa(mapa);

  /// Selecciona una celda de la ZonaInicial para colocarle un número.
  void seleccionarCelda(Posicion posicion) {
    if (state.iniciada) return;
    if (!_posiciones.contains(posicion)) return;
    emit(state.copyWith(seleccionada: posicion));
  }

  /// Mueve la selección [delta] celdas dentro de la ZonaInicial (circular).
  /// Pensado para las flechas del teclado: -1 = anterior, 1 = siguiente.
  void moverSeleccion(int delta) {
    if (state.iniciada) return;
    final siguiente =
        _navegador.siguiente(_posiciones, state.seleccionada, delta);
    emit(state.copyWith(seleccionada: siguiente));
  }

  /// Asigna (o borra, con null) el valor de una celda de la ZonaInicial.
  /// No hace nada si la posición no pertenece a la ZonaInicial.
  void asignarValor(Posicion posicion, int? valor) {
    if (state.iniciada) return;
    if (!_posiciones.contains(posicion)) return;

    final nuevosValores = Map<Posicion, int?>.from(state.valores)
      ..[posicion] = valor;

    emit(state.copyWith(
      valores: nuevosValores,
      esValida: ZonaInicial.esValida(nuevosValores.values.toList()),
    ));
  }

  /// Coloca [numero] en la celda seleccionada. Si ya está usado en otra
  /// celda, no lo coloca y avisa en cuál está. Si no hay celda
  /// seleccionada o el juego ya inició, no hace nada.
  void asignarASeleccionada(int numero) {
    final sel = state.seleccionada;
    if (sel == null || state.iniciada) return;

    final conflicto = _validador.conflictoAl(state.valores, sel, numero);
    if (conflicto != null) {
      _notificar(MensajesZonaInicial.numeroRepetido(numero, conflicto));
      return;
    }

    if (!puedeAsignarPorRegla(numero)) {
      _notificar('Ese número no cumple la regla de esta zona.');
      return;
    }

    asignarValor(sel, numero);
    _avanzarASiguienteVacia();
  }

  bool puedeAsignarPorRegla(int numero) {
    final posicion = state.seleccionada;
    if (posicion == null) return false;
    final tablero = TableroJuego();
    for (final entrada in state.valores.entries) {
      tablero.asignarValor(
        entrada.key.fila,
        entrada.key.columna,
        entrada.value,
      );
    }
    return _validadorDeJugadas.puedeAsignar(
      tablero,
      posicion.fila,
      posicion.columna,
      numero,
    );
  }

  /// Borra el valor de la celda seleccionada.
  void borrarSeleccionada() {
    final sel = state.seleccionada;
    if (sel == null || state.iniciada) return;
    asignarValor(sel, null);
  }

  /// Rechaza un carácter tecleado que no es un número del 1 al 6 y avisa
  /// al usuario. No cambia ningún valor del tablero.
  void rechazarEntrada(String caracter) {
    if (state.iniciada) return;
    _notificar(MensajesZonaInicial.caracterInvalido(caracter));
  }

  void _avanzarASiguienteVacia() {
    final vacia =
        _navegador.siguienteVacia(_posiciones, state.valores);
    if (vacia != null) emit(state.copyWith(seleccionada: vacia));
    // Si no hay ninguna vacía, se conserva la selección actual.
  }

  void _notificar(String mensaje) {
    emit(state.copyWith(mensaje: mensaje, mensajeId: state.mensajeId + 1));
  }

  /// Vuelca los valores de la ZonaInicial hacia el tablero real.
  ///
  /// Aunque la configuración aún no sea válida, se pueden seguir copiando
  /// temporalmente los valores para que los widgets puedan renderizarlos. Solo
  /// se marca como iniciada cuando la zona ya cumple la validación.
  void aplicarATablero(TableroJuego tablero) {
    if (state.iniciada) return;
    for (final entrada in state.valores.entries) {
      tablero.asignarValor(entrada.key.fila, entrada.key.columna, entrada.value);
    }
    if (state.esValida) {
      emit(state.copyWith(iniciada: true, limpiarSeleccion: true));
    }
  }
}

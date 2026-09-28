import 'package:flutter_bloc/flutter_bloc.dart';

import '../region.dart';
import '../tablero.dart';
import '../zona_inicial.dart';

part 'zona_inicial_state.dart';

/// Cubit LOCAL: controla el llenado de la ZonaInicial y decide si ya se
/// puede avanzar al resto del juego.
class ZonaInicialCubit extends Cubit<ZonaInicialState> {
  ZonaInicialCubit() : super(ZonaInicialState.inicial());

  /// Selecciona una celda de la ZonaInicial para colocarle un número.
  void seleccionarCelda(Posicion posicion) {
    if (state.iniciada) return;
    if (!ZonaInicial.posiciones.contains(posicion)) return;
    emit(state.copyWith(seleccionada: posicion));
  }

  /// Mueve la selección [delta] celdas dentro de la ZonaInicial (circular).
  /// Pensado para las flechas del teclado: -1 = anterior, 1 = siguiente.
  void moverSeleccion(int delta) {
    if (state.iniciada) return;
    final posiciones = ZonaInicial.posiciones;
    final actual =
        state.seleccionada == null ? -1 : posiciones.indexOf(state.seleccionada!);
    final siguiente = (actual + delta) % posiciones.length; // Dart: siempre >= 0
    emit(state.copyWith(seleccionada: posiciones[siguiente]));
  }

  /// Asigna (o borra, con null) el valor de una celda de la ZonaInicial.
  /// No hace nada si la posición no pertenece a la ZonaInicial.
  void asignarValor(Posicion posicion, int? valor) {
    if (state.iniciada) return;
    if (!ZonaInicial.posiciones.contains(posicion)) return;

    final nuevosValores = Map<Posicion, int?>.from(state.valores)
      ..[posicion] = valor;

    emit(state.copyWith(
      valores: nuevosValores,
      esValida: ZonaInicial.esValida(nuevosValores.values.toList()),
    ));
  }

  /// Coloca [numero] en la celda seleccionada. Ignora el número si ya está
  /// usado en otra celda o si no está en el rango 1-6. Después avanza a la
  /// siguiente celda vacía.
  void asignarASeleccionada(int numero) {
    final sel = state.seleccionada;
    if (sel == null || state.iniciada) return;
    if (!ZonaInicial.valoresRequeridos.contains(numero)) return;

    final usadoEnOtra =
        state.valores.entries.any((e) => e.key != sel && e.value == numero);
    if (usadoEnOtra) return;

    asignarValor(sel, numero);
    _avanzarASiguienteVacia();
  }

  /// Borra el valor de la celda seleccionada.
  void borrarSeleccionada() {
    final sel = state.seleccionada;
    if (sel == null || state.iniciada) return;
    asignarValor(sel, null);
  }

  void _avanzarASiguienteVacia() {
    for (final pos in ZonaInicial.posiciones) {
      if (state.valores[pos] == null) {
        emit(state.copyWith(seleccionada: pos));
        return;
      }
    }
    // Todas llenas: se conserva la selección actual.
  }

  /// Vuelca los valores de la ZonaInicial hacia el tablero real y marca la
  /// configuración como iniciada. No hace nada si todavía no son válidos.
  void aplicarATablero(TableroJuego tablero) {
    if (!state.esValida || state.iniciada) return;
    for (final entrada in state.valores.entries) {
      tablero.asignarValor(entrada.key.fila, entrada.key.columna, entrada.value);
    }
    emit(state.copyWith(iniciada: true, limpiarSeleccion: true));
  }
}
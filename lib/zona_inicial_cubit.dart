import 'package:flutter_bloc/flutter_bloc.dart';

import 'region.dart';
import 'tablero.dart';
import 'zona_inicial.dart';

/// Estado del llenado de la ZonaInicial: el valor actual de cada una de
/// sus 6 celdas, cuál está seleccionada, si ya son válidos (1 a 6, sin
/// repetir) y si la configuración ya fue confirmada con el botón Inicio.
class ZonaInicialState {
  final Map<Posicion, int?> valores;
  final Posicion? seleccionada;
  final bool esValida;
  final bool iniciada;

  const ZonaInicialState({
    required this.valores,
    required this.esValida,
    this.seleccionada,
    this.iniciada = false,
  });

  factory ZonaInicialState.inicial() => ZonaInicialState(
        valores: {for (final pos in ZonaInicial.posiciones) pos: null},
        esValida: false,
        // Arranca con la primera celda seleccionada para agilizar el llenado.
        seleccionada: ZonaInicial.posiciones.first,
      );

  /// Números ya colocados en alguna celda de la zona.
  Set<int> get usados => valores.values.whereType<int>().toSet();

  int get cantidadLlenas => valores.values.whereType<int>().length;

  ZonaInicialState copyWith({
    Map<Posicion, int?>? valores,
    bool? esValida,
    bool? iniciada,
    Posicion? seleccionada,
    bool limpiarSeleccion = false,
  }) {
    return ZonaInicialState(
      valores: valores ?? this.valores,
      esValida: esValida ?? this.esValida,
      iniciada: iniciada ?? this.iniciada,
      seleccionada: limpiarSeleccion ? null : (seleccionada ?? this.seleccionada),
    );
  }
}

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
  /// usado en otra celda. Después avanza a la siguiente celda vacía.
  void asignarASeleccionada(int numero) {
    final sel = state.seleccionada;
    if (sel == null || state.iniciada) return;

    final usadoEnOtra = state.valores.entries
        .any((e) => e.key != sel && e.value == numero);
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
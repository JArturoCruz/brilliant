part of 'zona_inicial_cubit.dart';

/// Estado del llenado de la ZonaInicial: el valor actual de cada una de
/// sus 6 celdas, cuál está seleccionada, si ya son válidos (1 a 6, sin
/// repetir), si la configuración ya fue confirmada con el botón Inicio, y
/// el último aviso a mostrar (si lo hay).
class ZonaInicialState {
  final Map<Posicion, int?> valores;
  final Posicion? seleccionada;
  final bool esValida;
  final bool iniciada;

  /// Aviso para el usuario (p. ej. "número repetido"). La UI lo muestra
  /// cuando [mensajeId] cambia, así el mismo aviso puede repetirse.
  final String? mensaje;
  final int mensajeId;

  const ZonaInicialState({
    required this.valores,
    required this.esValida,
    this.seleccionada,
    this.iniciada = false,
    this.mensaje,
    this.mensajeId = 0,
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
    String? mensaje,
    int? mensajeId,
  }) {
    return ZonaInicialState(
      valores: valores ?? this.valores,
      esValida: esValida ?? this.esValida,
      iniciada: iniciada ?? this.iniciada,
      seleccionada: limpiarSeleccion ? null : (seleccionada ?? this.seleccionada),
      mensaje: mensaje ?? this.mensaje,
      mensajeId: mensajeId ?? this.mensajeId,
    );
  }
}

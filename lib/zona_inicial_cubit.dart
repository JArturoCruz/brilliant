

import 'package:flutter_bloc/flutter_bloc.dart';

import 'region.dart';
import 'tablero.dart';
import 'zona_inicial.dart';

/// Estado del llenado de la ZonaInicial: el valor actual de cada una de
/// sus 6 celdas, y si ya son válidos (1 a 6, sin repetir) para permitir
/// avanzar en el juego.
class ZonaInicialState {
  final Map<Posicion, int?> valores;
  final bool esValida;

  const ZonaInicialState({required this.valores, required this.esValida});

  factory ZonaInicialState.inicial() => ZonaInicialState(
        valores: {for (final pos in ZonaInicial.posiciones) pos: null},
        esValida: false,
      );

  ZonaInicialState copyWith({Map<Posicion, int?>? valores, bool? esValida}) {
    return ZonaInicialState(
      valores: valores ?? this.valores,
      esValida: esValida ?? this.esValida,
    );
  }
}

/// Cubit LOCAL: se crea y se descarta dentro de la pantalla/flujo de
/// configuración inicial (por ejemplo con un BlocProvider alrededor de
/// esa pantalla), no es estado global de la app. Su única responsabilidad
/// es controlar el llenado de la ZonaInicial y decidir si ya se puede
/// avanzar al resto del juego — no valida reglas de Tipo ni conoce el
/// resto del tablero más allá de estas 6 celdas.
class ZonaInicialCubit extends Cubit<ZonaInicialState> {
  ZonaInicialCubit() : super(ZonaInicialState.inicial());

  /// Asigna (o borra, con null) el valor de una celda de la ZonaInicial.
  /// No hace nada si la posición no pertenece a la ZonaInicial.
  void asignarValor(Posicion posicion, int? valor) {
    if (!ZonaInicial.posiciones.contains(posicion)) return;

    final nuevosValores = Map<Posicion, int?>.from(state.valores)
      ..[posicion] = valor;

    emit(state.copyWith(
      valores: nuevosValores,
      esValida: ZonaInicial.esValida(nuevosValores.values.toList()),
    ));
  }

  /// Vuelca los valores de la ZonaInicial hacia el tablero real. No hace
  /// nada si todavía no son válidos (protege el "no avanzar hasta que
  /// estén completos" también del lado de los datos, no solo de la UI).
  void aplicarATablero(TableroJuego tablero) {
    if (!state.esValida) return;
    for (final entrada in state.valores.entries) {
      tablero.asignarValor(entrada.key.fila, entrada.key.columna, entrada.value);
    }
  }
}
import 'region.dart';
import 'topologia_tablero.dart';

/// Responsable ÚNICAMENTE de guardar y exponer el estado (valores) de una
/// partida concreta sobre el tablero. No conoce reglas de Tipo ni valida
/// jugadas — eso es responsabilidad de ValidadorDeJugadas. Tampoco conoce
/// el diseño de las regiones más allá de pedírselo a TopologiaTablero.
class TableroJuego {
  static const int filas = TopologiaTablero.filas;
  static const int columnas = TopologiaTablero.columnas;

  // Matriz interna: null representa celda vacía.
  final List<List<int?>> _matriz;

  TableroJuego([List<List<int?>>? matrizInicial])
      : _matriz = matrizInicial ??
            List.generate(filas, (_) => List.filled(columnas, null, growable: false));

  void asignarValor(int fila, int columna, int? valor) {
    if (fila < 0 || fila >= filas || columna < 0 || columna >= columnas) {
      throw RangeError('Coordenadas fuera de rango: ($fila, $columna)');
    }
    _matriz[fila][columna] = valor;
  }

  int? obtenerValor(int fila, int columna) => _matriz[fila][columna];

  /// Extrae los enteros existentes en la región (omite celdas con null).
  List<int> extraer(RegionTablero region) {
    final posiciones = TopologiaTablero.posicionesDe(region);
    final List<int> numeros = [];

    for (final pos in posiciones) {
      final valor = _matriz[pos.fila][pos.columna];
      if (valor != null) {
        numeros.add(valor);
      }
    }
    return numeros;
  }

  /// Extrae la lista completa incluyendo celdas nulas.
  List<int?> extraerCompleto(RegionTablero region) {
    final posiciones = TopologiaTablero.posicionesDe(region);
    return posiciones.map((p) => _matriz[p.fila][p.columna]).toList();
  }
}
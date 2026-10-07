import 'posicion.dart';

/// Lógica pura de recorrido sobre una lista fija de posiciones (las 6
/// celdas de la ZonaInicial). No conoce Flutter ni el Cubit: solo sabe
/// moverse entre índices y encontrar la siguiente celda vacía.
class NavegadorZonaInicial {
  const NavegadorZonaInicial();

  /// Posición [delta] lugares después de [actual] dentro de [posiciones],
  /// dando la vuelta al llegar a un extremo (circular). Si [actual] es
  /// null, empieza en la primera posición.
  Posicion siguiente(
    List<Posicion> posiciones,
    Posicion? actual,
    int delta,
  ) {
    final indiceActual = actual == null ? -1 : posiciones.indexOf(actual);
    final indiceSiguiente =
        (indiceActual + delta) % posiciones.length; // Dart: siempre >= 0
    return posiciones[indiceSiguiente];
  }

  /// Primera posición de [posiciones] cuyo valor en [valores] es null, o
  /// null si todas están llenas.
  Posicion? siguienteVacia(
    List<Posicion> posiciones,
    Map<Posicion, int?> valores,
  ) {
    for (final pos in posiciones) {
      if (valores[pos] == null) return pos;
    }
    return null;
  }
}

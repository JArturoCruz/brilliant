import 'region.dart';

/// Responsable ÚNICAMENTE de conocer el diseño fijo del tablero: qué
/// celdas (Posicion) pertenecen a qué región (RegionTablero). No conoce
/// nada sobre el estado (valores) de una partida ni sobre las reglas
/// de cada Tipo — eso es responsabilidad de otras clases.
class TopologiaTablero {
  static const int filas = 7;
  static const int columnas = 7;

  static const Map<RegionTablero, List<Posicion>> coordenadasPorRegion = {
    // Región Amarilla: 5 celdas aisladas (4 esquinas + centro)
    RegionTablero.amarilla: [
      Posicion(0, 0),
      Posicion(0, 6),
      Posicion(3, 3),
      Posicion(6, 0),
      Posicion(6, 6),
    ],

    // Verde 1: Bloque lateral izquierdo
    RegionTablero.verde1: [
      Posicion(0, 1),
      Posicion(1, 0),
      Posicion(1, 1),
      Posicion(2, 0),
      Posicion(3, 0),
      Posicion(4, 0),
    ],

    // Verde 2: Bloque lateral derecho
    RegionTablero.verde2: [
      Posicion(1, 6),
      Posicion(2, 5),
      Posicion(2, 6),
      Posicion(3, 5),
      Posicion(3, 6),
    ],

    // Azul 1: Bloque superior
    RegionTablero.azul1: [
      Posicion(0, 2),
      Posicion(1, 2),
      Posicion(1, 3),
      Posicion(2, 3),
    ],

    // Azul 2: Bloque inferior derecho
    RegionTablero.azul2: [
      Posicion(4, 6),
      Posicion(5, 5),
      Posicion(5, 6),
      Posicion(6, 5),
    ],

    // Morada 1: Bloque superior
    RegionTablero.morada1: [
      Posicion(0, 3),
      Posicion(0, 4),
      Posicion(0, 5),
      Posicion(1, 4),
      Posicion(1, 5),
      Posicion(2, 4),
    ],

    // Morada 2: Bloque inferior central
    RegionTablero.morada2: [
      Posicion(3, 2),
      Posicion(4, 2),
      Posicion(4, 3),
      Posicion(5, 2),
      Posicion(6, 1),
      Posicion(6, 2),
    ],

    // Roja 1: Bloque medio izquierdo
    RegionTablero.roja1: [
      Posicion(2, 1),
      Posicion(2, 2),
      Posicion(3, 1),
      Posicion(4, 1),
      Posicion(5, 0),
      Posicion(5, 1),
    ],

    // Roja 2: Bloque medio derecho
    RegionTablero.roja2: [
      Posicion(3, 4),
      Posicion(4, 4),
      Posicion(4, 5),
      Posicion(5, 3),
      Posicion(5, 4),
      Posicion(6, 3),
      Posicion(6, 4),
    ],
  };

  /// Mapa inverso (celda -> región), calculado una sola vez a partir de
  /// [coordenadasPorRegion].
  static final Map<Posicion, RegionTablero> _regionPorCelda = {
    for (final entrada in coordenadasPorRegion.entries)
      for (final pos in entrada.value) pos: entrada.key,
  };

  /// Región a la que pertenece la celda (fila, columna), o null si la
  /// celda no forma parte de ninguna región definida.
  static RegionTablero? regionDeCelda(int fila, int columna) =>
      _regionPorCelda[Posicion(fila, columna)];

  /// Posiciones que conforman una región. Lista vacía si la región no
  /// tiene celdas definidas.
  static List<Posicion> posicionesDe(RegionTablero region) =>
      coordenadasPorRegion[region] ?? const [];
}
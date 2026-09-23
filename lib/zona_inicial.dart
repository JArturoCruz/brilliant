import 'region.dart';

/// Zona especial de configuración inicial de la partida: 6 celdas fijas,
/// repartidas sobre distintas regiones de color, que deben llenarse con
/// los números del 1 al 6 (sin repetir) antes de poder avanzar en el
/// juego. No es una RegionTablero de color: cada una de estas celdas
/// también pertenece a su propia región, pero esta regla se valida de
/// forma independiente (es una capa adicional, no un reemplazo).
class ZonaInicial {
  ZonaInicial._();

  static const List<Posicion> posiciones = [
    Posicion(2, 0), // pertenece a verde1
    Posicion(5, 1), // pertenece a roja1
    Posicion(1, 3), // pertenece a azul1
    Posicion(4, 3), // pertenece a morada2
    Posicion(2, 5), // pertenece a verde2
    Posicion(4, 6), // pertenece a azul2
  ];

  static const int cantidadCeldas = 6;
  static const Set<int> valoresRequeridos = {1, 2, 3, 4, 5, 6};

  /// Indica si [valores] (uno por cada celda de [posiciones], sin importar
  /// el orden) son válidos: las 6 celdas llenas, con los números 1 a 6,
  /// cada uno usado exactamente una vez.
  static bool esValida(List<int?> valores) {
    if (valores.length != cantidadCeldas) return false;
    if (valores.contains(null)) return false;

    final numeros = valores.whereType<int>().toSet();
    return numeros.length == cantidadCeldas &&
        numeros.every(valoresRequeridos.contains);
  }
}
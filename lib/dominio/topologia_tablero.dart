import 'mapa_tablero.dart';
import 'posicion.dart';
import 'region.dart';

class TopologiaTablero {
  static const int filas = 7;
  static const int columnas = 7;

  static final Map<RegionTablero, List<Posicion>> coordenadasPorRegion =
      MapaTablero.mapa1.coordenadasPorRegion;

  static RegionTablero? regionDeCelda(
    int fila,
    int columna, {
    MapaTablero mapa = MapaTablero.mapa1,
  }) {
    final posicion = Posicion(fila, columna);
    for (final entrada in mapa.coordenadasPorRegion.entries) {
      if (entrada.value.contains(posicion)) return entrada.key;
    }
    return null;
  }

  static List<Posicion> posicionesDe(
    RegionTablero region, {
    MapaTablero mapa = MapaTablero.mapa1,
  }) =>
      mapa.coordenadasPorRegion[region] ?? const [];
}

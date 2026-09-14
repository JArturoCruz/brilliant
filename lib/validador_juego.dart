import 'region.dart';
import 'tablero.dart';
import 'tipo.dart';
import 'topologia_tablero.dart';

/// Responsable ÚNICAMENTE de orquestar la validación de jugadas: combina
/// el estado del tablero (TableroJuego), el diseño de las regiones
/// (TopologiaTablero) y la regla de cada Tipo (TiposDeRegion) para decidir
/// si una jugada es válida o cuál es el estado de una región. Ninguna de
/// esas otras clases necesita conocer a las demás para cumplir su propia
/// función; esta es la única que las conecta.
class ValidadorDeJugadas {
  const ValidadorDeJugadas();

  /// Indica si [valor] podría colocarse en (fila, columna) sin romper la
  /// regla del Tipo de la región a la que pertenece esa celda, dado lo que
  /// ya hay colocado en el resto de celdas de esa misma región.
  /// Devuelve false si la celda no pertenece a ninguna región.
  bool puedeAsignar(TableroJuego tablero, int fila, int columna, int valor) {
    final region = TopologiaTablero.regionDeCelda(fila, columna);
    if (region == null) return false;

    final tipo = TiposDeRegion.obtenerTipo(region);
    final posiciones = TopologiaTablero.posicionesDe(region);

    final actuales = <int>[];
    for (final pos in posiciones) {
      if (pos.fila == fila && pos.columna == columna) continue;
      final valorActual = tablero.obtenerValor(pos.fila, pos.columna);
      if (valorActual != null) actuales.add(valorActual);
    }
    return tipo.esPosibleAgregar(actuales, valor);
  }

  /// Estado actual (incompleta / completa / completaConBonificacion) de
  /// una región concreta del tablero, según la regla de su Tipo.
  EstadoRegion estadoDe(TableroJuego tablero, RegionTablero region) {
    final tipo = TiposDeRegion.obtenerTipo(region);
    return tipo.calcularEstado(tablero.extraerCompleto(region));
  }
}
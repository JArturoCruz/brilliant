import 'region.dart';
import 'validador.dart';

/// Estado de una región según el diagrama:
/// -- Incompleta: aún hay celdas vacías.
/// -- Completada: todas las celdas llenas y la regla del tipo se cumple.
/// -- Completada con bonificación: completada + cumple un criterio extra
///    definido por cada tipo (a definir por diseño de juego).
enum EstadoRegion {
  incompleta,
  completa,
  completaConBonificacion,
}

/// Representa el "Tipo" de una región (TipoAzul, TipoVerde, etc.)
/// Encapsula: la regla de validación, la puntuación al completarse
/// y el cálculo del estado de la región.
abstract class TipoRegion {
  const TipoRegion();

  /// Nombre identificador del tipo (útil para depuración / UI).
  String get nombre;

  /// Puntuación base otorgada cuando la región se completa correctamente.
  int get puntuacionBase;

  /// Valida si los valores (sin celdas vacías) cumplen la regla de este tipo.
  bool esValido(List<int> valores);

  /// Condición adicional para otorgar bonificación al completar la región.
  /// Por defecto no hay bonificación; cada tipo puede sobreescribir este
  /// método cuando se defina la regla real de bonificación.
  bool cumpleBonificacion(List<int?> valoresCompletos) => false;

  /// Calcula el estado de la región a partir de sus valores completos
  /// (incluyendo nulls para las celdas vacías).
  EstadoRegion calcularEstado(List<int?> valoresCompletos) {
    final estaLlena = !valoresCompletos.contains(null);
    if (!estaLlena) return EstadoRegion.incompleta;

    final valores = valoresCompletos.whereType<int>().toList();
    if (!esValido(valores)) return EstadoRegion.incompleta;

    if (cumpleBonificacion(valoresCompletos)) {
      return EstadoRegion.completaConBonificacion;
    }
    return EstadoRegion.completa;
  }

  /// Puntos extra otorgados cuando la región se completa con bonificación.
  /// Valor fijo por ahora; puede ajustarse más adelante si el diseño
  /// del juego requiere que varíe por tipo.
  static const int puntosBonificacion = 5;

  /// Puntuación final de la región según su estado actual.
  int calcularPuntuacion(List<int?> valoresCompletos) {
    switch (calcularEstado(valoresCompletos)) {
      case EstadoRegion.completa:
        return puntuacionBase;
      case EstadoRegion.completaConBonificacion:
        return puntuacionBase + puntosBonificacion;
      case EstadoRegion.incompleta:
        return 0;
    }
  }
}

class TipoAmarilla extends TipoRegion {
  const TipoAmarilla();

  @override
  String get nombre => 'Amarilla';

  @override
  int get puntuacionBase => 50;

  @override
  bool esValido(List<int> valores) => ValidadorRegiones.validarAmarilla(valores);
}

class TipoVerde extends TipoRegion {
  const TipoVerde();

  @override
  String get nombre => 'Verde';

  @override
  int get puntuacionBase => 20;

  @override
  bool esValido(List<int> valores) => ValidadorRegiones.validarVerde(valores);
}

class TipoAzul extends TipoRegion {
  const TipoAzul();

  @override
  String get nombre => 'Azul';

  @override
  int get puntuacionBase => 40;

  @override
  bool esValido(List<int> valores) => ValidadorRegiones.validarAzul(valores);
}

class TipoMorada extends TipoRegion {
  const TipoMorada();

  @override
  String get nombre => 'Morada';

  @override
  int get puntuacionBase => 30;

  @override
  bool esValido(List<int> valores) => ValidadorRegiones.validarMorada(valores);
}

class TipoRoja extends TipoRegion {
  const TipoRoja();

  @override
  String get nombre => 'Roja';

  @override
  int get puntuacionBase => 60;

  @override
  bool esValido(List<int> valores) => ValidadorRegiones.validarRoja(valores);
}

/// Une cada región específica del tablero (identificador) con su Tipo.
/// Esto mantiene separados, como en tu diagrama, el "Identificador"
/// (RegionTablero: verde1, verde2, azul1...) del "Tipo" (color/regla real).
class TiposDeRegion {
  static const Map<RegionTablero, TipoRegion> porRegion = {
    RegionTablero.amarilla: TipoAmarilla(),
    RegionTablero.verde1: TipoVerde(),
    RegionTablero.verde2: TipoVerde(),
    RegionTablero.azul1: TipoAzul(),
    RegionTablero.azul2: TipoAzul(),
    RegionTablero.morada1: TipoMorada(),
    RegionTablero.morada2: TipoMorada(),
    RegionTablero.roja1: TipoRoja(),
    RegionTablero.roja2: TipoRoja(),
  };

  static TipoRegion obtenerTipo(RegionTablero region) {
    final tipo = porRegion[region];
    if (tipo == null) {
      throw ArgumentError('No hay Tipo definido para la región: $region');
    }
    return tipo;
  }
}
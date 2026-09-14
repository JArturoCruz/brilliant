import 'dart:ui';

import 'region.dart';

/// Contrato de tipo de región. Cada Tipo concentra: su color, su
/// descripción, la regla que determina si un valor puede agregarse a la
/// región, y los puntos otorgados según la posición de finalización.
abstract class Tipo {

  const Tipo();
  
  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);

  /// Puntos otorgados según la POSICIÓN en la que un jugador completa esta
  /// región (es una carrera: solo puntúan los 3 primeros en completarla).
  /// Clave = posición de finalización (1 = primero, 2 = segundo, 3 =
  /// tercero). De la 4ta posición en adelante no se otorgan puntos.
  Map<int, int> get puntuaciones;
}

/// Puntos otorgados a quien complete la región en [posicion] (1º, 2º, 3º...).
/// De la 4ta posición en adelante siempre da 0.
extension TipoPuntuacion on Tipo {
  int puntosPorPosicion(int posicion) => puntuaciones[posicion] ?? 0;
}

/// Regla compartida por los tipos que exigen "todos los números distintos"
/// (Amarillo y Rojo). Se define una sola vez para no duplicar la misma
/// regla de negocio en dos clases distintas.
mixin ReglaTodosDistintos on Tipo {
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      !actuales.contains(posible);
}

class TipoAzul extends Tipo {
  const TipoAzul();

  @override
  Color get color => const Color(0xFF2196F3);

  @override
  String get descripcion => 'Todos los números deben de ser iguales';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    return actuales.isEmpty || actuales.every((element) => element == posible);
  }

  @override
  Map<int, int> get puntuaciones => {
        1: 7,
        2: 5,
        3: 3,
      };
}

class TipoVerde extends Tipo {
  const TipoVerde();

  @override
  Color get color => const Color(0xFF4CAF50);

  @override
  String get descripcion => 'Se puede colocar cualquier número';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) => true;

  @override
  Map<int, int> get puntuaciones => {
        1: 4,
        2: 3,
        3: 2,
      };
}

class TipoMorado extends Tipo {
  const TipoMorado();

  @override
  Color get color => const Color(0xFF9C27B0);

  @override
  String get descripcion => 'Máximo dos números diferentes por zona';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    final distintos = actuales.toSet()..add(posible);
    return distintos.length <= 2;
  }

  @override
  Map<int, int> get puntuaciones => {
        1: 8,
        2: 6,
        3: 4,
      };
}

class TipoAmarillo extends Tipo with ReglaTodosDistintos {
  const TipoAmarillo();

  @override
  Color get color => const Color(0xFFFFC107);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  Map<int, int> get puntuaciones => {
        1: 8,
        2: 6,
        3: 4,
      };
}

class TipoRojo extends Tipo with ReglaTodosDistintos {
  const TipoRojo();

  @override
  Color get color => const Color(0xFFF44336);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  Map<int, int> get puntuaciones => {
        1: 8,
        2: 6,
        3: 4,
      };
}

/// Estado de una región (según el diagrama original del proyecto).
enum EstadoRegion {
  incompleta,
  completa,
  completaConBonificacion,
}

/// Comportamiento añadido sobre Tipo sin tocar la clase original
/// (principio Abierto/Cerrado). Deriva la validez de una región completa
/// reutilizando esPosibleAgregar como única fuente de verdad de cada regla.
extension TipoEstadoRegion on Tipo {
  bool regionEsValida(List<int> valores) {
    for (var i = 0; i < valores.length; i++) {
      final resto = List<int>.from(valores)..removeAt(i);
      if (!esPosibleAgregar(resto, valores[i])) return false;
    }
    return true;
  }

  EstadoRegion calcularEstado(List<int?> valoresCompletos) {
    if (valoresCompletos.contains(null)) return EstadoRegion.incompleta;
    final valores = valoresCompletos.whereType<int>().toList();
    return regionEsValida(valores)
        ? EstadoRegion.completa
        : EstadoRegion.incompleta;
  }
}

/// Une cada región específica del tablero (identificador: verde1, verde2,
/// azul1...) con su Tipo (color/regla real).
class TiposDeRegion {
  static const Map<RegionTablero, Tipo> porRegion = {
    RegionTablero.amarilla: TipoAmarillo(),
    RegionTablero.verde1: TipoVerde(),
    RegionTablero.verde2: TipoVerde(),
    RegionTablero.azul1: TipoAzul(),
    RegionTablero.azul2: TipoAzul(),
    RegionTablero.morada1: TipoMorado(),
    RegionTablero.morada2: TipoMorado(),
    RegionTablero.roja1: TipoRojo(),
    RegionTablero.roja2: TipoRojo(),
  };

  static Tipo obtenerTipo(RegionTablero region) {
    final tipo = porRegion[region];
    if (tipo == null) {
      throw ArgumentError('No hay Tipo definido para la región: $region');
    }
    return tipo;
  }
}
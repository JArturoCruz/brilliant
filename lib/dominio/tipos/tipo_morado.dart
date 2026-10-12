import 'dart:ui';

import 'tipo.dart';

/// Región morada: admite uno o dos números distintos, y al completarse
/// debe contener al menos dos valores diferentes.
class TipoMorado extends Tipo {
  const TipoMorado();

  @override
  Color get color => const Color(0xFF9C27B0);

  @override
  String get descripcion => 'Máximo dos números diferentes por zona';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) {
    final distintos = actuales.toSet()..add(posible);
    if (distintos.length > 2) return false;

    // Las regiones moradas tienen seis casillas: no se puede ocupar la
    // última con el mismo valor de las cinco anteriores.
    return actuales.length != 5 || distintos.length > 1;
  }

  @override
  Map<int, int> get puntuaciones => {1: 8, 2: 6, 3: 4};
}

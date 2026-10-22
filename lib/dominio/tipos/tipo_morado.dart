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
  bool esPosibleAgregar(
    List<int> actuales,
    int posible, {
    int? capacidad,
  }) {
    final distintos = actuales.toSet()..add(posible);
    if (distintos.length > 2) return false;

    final ultimaCasilla = capacidad == null
        ? actuales.length == 5
        : actuales.length == capacidad - 1;
    return !ultimaCasilla || distintos.length > 1;
  }

  @override
  Map<int, int> get puntuaciones => {1: 8, 2: 6, 3: 4};
}

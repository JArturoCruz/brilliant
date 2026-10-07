import 'dart:ui';

import 'tipo.dart';

/// Región azul: todos los números colocados deben ser iguales entre sí.
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
  Map<int, int> get puntuaciones => {1: 7, 2: 5, 3: 3};
}

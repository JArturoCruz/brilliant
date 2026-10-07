import 'dart:ui';

import 'regla_todos_distintos.dart';
import 'tipo.dart';

/// Región amarilla: las 5 celdas aisladas deben tener números distintos.
class TipoAmarillo extends Tipo with ReglaTodosDistintos {
  const TipoAmarillo();

  @override
  Color get color => const Color(0xFFFFC107);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  Map<int, int> get puntuaciones => {1: 8, 2: 6, 3: 4};
}

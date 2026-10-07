import 'dart:ui';

import 'regla_todos_distintos.dart';
import 'tipo.dart';

/// Región roja: todos los números colocados deben ser distintos entre sí.
class TipoRojo extends Tipo with ReglaTodosDistintos {
  const TipoRojo();

  @override
  Color get color => const Color(0xFFF44336);

  @override
  String get descripcion => 'Todos los números deben de ser distintos';

  @override
  Map<int, int> get puntuaciones => {1: 8, 2: 6, 3: 4};
}

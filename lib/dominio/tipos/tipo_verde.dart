import 'dart:ui';

import 'tipo.dart';

/// Región verde: acepta cualquier número sin restricción.
class TipoVerde extends Tipo {
  const TipoVerde();

  @override
  Color get color => const Color(0xFF4CAF50);

  @override
  String get descripcion => 'Se puede colocar cualquier número';

  @override
  bool esPosibleAgregar(List<int> actuales, int posible) => true;

  @override
  Map<int, int> get puntuaciones => {1: 4, 2: 3, 3: 2};
}

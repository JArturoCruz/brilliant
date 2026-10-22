import 'dart:ui';

import 'tipo.dart';

class TipoNaranja extends Tipo {
  const TipoNaranja({required this.numeroMinimo, required this.numeroMaximo});

  final int numeroMinimo;
  final int numeroMaximo;

  @override
  Color get color => const Color(0xFFFF9800);

  @override
  String get descripcion =>
      'Números del $numeroMinimo al $numeroMaximo; se pueden repetir';

  @override
  bool esPosibleAgregar(
    List<int> actuales,
    int posible, {
    int? capacidad,
  }) =>
      posible >= numeroMinimo && posible <= numeroMaximo;

  @override
  Map<int, int> get puntuaciones => {1: 8, 2: 6, 3: 4};
}

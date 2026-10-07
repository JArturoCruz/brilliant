import 'tipo.dart';

/// Regla compartida por los tipos que exigen "todos los números distintos"
/// (Amarillo y Rojo). Se define una sola vez para no duplicar la misma
/// regla de negocio en dos clases distintas.
mixin ReglaTodosDistintos on Tipo {
  @override
  bool esPosibleAgregar(List<int> actuales, int posible) =>
      !actuales.contains(posible);
}

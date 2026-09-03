import 'region.dart';

class ValidadorRegiones {
  /// Regla Roja: Todos los números deben ser diferentes.
  static bool validarRoja(List<int> valores) {
    return valores.toSet().length == valores.length;
  }

  /// Regla Amarilla: Todos los números deben ser diferentes.
  static bool validarAmarilla(List<int> valores) {
    return valores.toSet().length == valores.length;
  }

  /// Regla Verde: Se puede insertar cualquier número sin restricción.
  static bool validarVerde(List<int> valores) {
    return true;
  }

  /// Regla Azul: Solo se permite un único número en toda la región.
  static bool validarAzul(List<int> valores) {
    return valores.toSet().length <= 1;
  }

  /// Regla Morada: Como máximo 2 números distintos en toda la región.
  static bool validarMorada(List<int> valores) {
    return valores.toSet().length <= 2;
  }

  /// Método general que enruta la validación según la región recibida.
  static bool esValido(RegionTablero region, List<int> valores) {
    switch (region) {
      case RegionTablero.amarilla:
        return validarAmarilla(valores);
      case RegionTablero.roja1:
      case RegionTablero.roja2:
        return validarRoja(valores);
      case RegionTablero.verde1:
      case RegionTablero.verde2:
        return validarVerde(valores);
      case RegionTablero.azul1:
      case RegionTablero.azul2:
        return validarAzul(valores);
      case RegionTablero.morada1:
      case RegionTablero.morada2:
        return validarMorada(valores);
    }
  }
}
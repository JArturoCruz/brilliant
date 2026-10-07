import 'posicion.dart';

/// Decide si un número puede escribirse en una celda de la ZonaInicial sin
/// repetirse. Es lógica de negocio pura (sin Flutter, sin Bloc), igual que
/// ValidadorDeJugadas lo es para el tablero completo.
class ValidadorEntradaZonaInicial {
  const ValidadorEntradaZonaInicial();

  /// Si [numero] ya está en otra celda de [valores] (distinta de [celda]),
  /// devuelve esa celda en conflicto. Si no hay conflicto, devuelve null.
  Posicion? conflictoAl(
    Map<Posicion, int?> valores,
    Posicion celda,
    int numero,
  ) {
    for (final entrada in valores.entries) {
      if (entrada.key != celda && entrada.value == numero) {
        return entrada.key;
      }
    }
    return null;
  }
}

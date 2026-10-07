/// Coordenada (fila, columna) dentro del tablero. Su única responsabilidad
/// es identificar una celda y permitir compararla (==, hashCode) para
/// poder usarla como clave de Map o elemento de Set.
class Posicion {
  final int fila;
  final int columna;

  const Posicion(this.fila, this.columna);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Posicion &&
          runtimeType == other.runtimeType &&
          fila == other.fila &&
          columna == other.columna;

  @override
  int get hashCode => fila.hashCode ^ columna.hashCode;

  @override
  String toString() => '($fila, $columna)';
}

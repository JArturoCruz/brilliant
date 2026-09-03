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

enum RegionTablero {
  amarilla,
  verde1,
  verde2,
  azul1,
  azul2,
  morada1,
  morada2,
  roja1,
  roja2,
}
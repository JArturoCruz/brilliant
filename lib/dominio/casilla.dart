enum EstadoIluminacion { ninguno, posibleAncla, posibleColocacion }

class Casilla {
  final int fila;
  final int columna;
  final int? valorActual; 
  final EstadoIluminacion iluminacion;

  Casilla({
    required this.fila,
    required this.columna,
    this.valorActual,
    this.iluminacion = EstadoIluminacion.ninguno,
  });

  Casilla copyWith({
    int? valorActual,
    EstadoIluminacion? iluminacion,
  }) {
    return Casilla(
      fila: fila,
      columna: columna,
      valorActual: valorActual ?? this.valorActual,
      iluminacion: iluminacion ?? this.iluminacion,
    );
  }
}
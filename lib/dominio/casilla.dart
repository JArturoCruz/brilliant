enum EstadoIluminacion { ninguno, posibleAncla, posibleColocacion }

class Casilla {
  final int fila;
  final int columna;
  final int? valorActual; 
  final EstadoIluminacion iluminacion;
  final bool esProvisional; 

  Casilla({
    required this.fila,
    required this.columna,
    this.valorActual,
    this.iluminacion = EstadoIluminacion.ninguno,
    this.esProvisional = false,
  });

  Casilla copyWith({
    int? valorActual,
    EstadoIluminacion? iluminacion,
    bool? esProvisional,
  }) {
    return Casilla(
      fila: fila,
      columna: columna,
      valorActual: valorActual ?? this.valorActual,
      iluminacion: iluminacion ?? this.iluminacion,
      esProvisional: esProvisional ?? this.esProvisional,
    );
  }
}
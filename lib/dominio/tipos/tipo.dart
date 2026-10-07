import 'dart:ui';

/// Contrato de tipo de región: color, descripción, regla de validez y
/// puntuación. Cada implementación concentra únicamente la regla propia
/// de su color; la puntuación se expone aparte mediante [puntosPorPosicion].
abstract class Tipo {
  const Tipo();

  Color get color;
  String get descripcion;
  bool esPosibleAgregar(List<int> actuales, int posible);

  /// Puntos otorgados según la POSICIÓN en la que un jugador completa esta
  /// región (es una carrera: solo puntúan los 3 primeros en completarla).
  /// Clave = posición de finalización (1 = primero, 2 = segundo, 3 =
  /// tercero). De la 4ta posición en adelante no se otorgan puntos.
  Map<int, int> get puntuaciones;
}

/// Traduce el mapa [Tipo.puntuaciones] a una consulta directa por posición,
/// sin que cada Tipo tenga que repetir el valor por defecto (0).
extension TipoPuntuacion on Tipo {
  int puntosPorPosicion(int posicion) => puntuaciones[posicion] ?? 0;
}

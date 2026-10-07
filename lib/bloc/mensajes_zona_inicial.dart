import '../dominio/posicion.dart';

/// Construye los textos que el usuario ve ante entradas inválidas en la
/// ZonaInicial. Separa "qué dice el mensaje" (aquí) de "cuándo se
/// dispara" (responsabilidad del Cubit) y de "cómo se muestra"
/// (responsabilidad de la capa de presentación).
class MensajesZonaInicial {
  const MensajesZonaInicial._();

  static String numeroRepetido(int numero, Posicion celdaEnConflicto) {
    return 'El $numero ya está en la casilla de la fila '
        '${celdaEnConflicto.fila + 1}, columna ${celdaEnConflicto.columna + 1}. '
        'Bórralo o cámbialo primero.';
  }

  static String caracterInvalido(String caracter) {
    return '«$caracter» no es válido. Solo se permiten los números del 1 al 6.';
  }
}

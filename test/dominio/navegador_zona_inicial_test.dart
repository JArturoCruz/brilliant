import 'package:brilliant/dominio/navegador_zona_inicial.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const navegador = NavegadorZonaInicial();
  const posiciones = [Posicion(0, 0), Posicion(0, 1), Posicion(0, 2)];

  group('NavegadorZonaInicial.siguiente', () {
    test('sin selección previa, avanza a la primera posición', () {
      expect(navegador.siguiente(posiciones, null, 1), posiciones[0]);
    });

    test('avanza una posición hacia adelante', () {
      expect(navegador.siguiente(posiciones, posiciones[0], 1), posiciones[1]);
    });

    test('da la vuelta al pasarse del final', () {
      expect(navegador.siguiente(posiciones, posiciones[2], 1), posiciones[0]);
    });

    test('retrocede una posición', () {
      expect(navegador.siguiente(posiciones, posiciones[1], -1), posiciones[0]);
    });

    test('da la vuelta al retroceder desde el inicio', () {
      expect(navegador.siguiente(posiciones, posiciones[0], -1), posiciones[2]);
    });
  });

  group('NavegadorZonaInicial.siguienteVacia', () {
    test('devuelve la primera posición con valor null', () {
      final valores = {
        posiciones[0]: 1,
        posiciones[1]: null,
        posiciones[2]: null,
      };
      expect(navegador.siguienteVacia(posiciones, valores), posiciones[1]);
    });

    test('devuelve null si no hay ninguna celda vacía', () {
      final valores = {
        posiciones[0]: 1,
        posiciones[1]: 2,
        posiciones[2]: 3,
      };
      expect(navegador.siguienteVacia(posiciones, valores), isNull);
    });
  });
}

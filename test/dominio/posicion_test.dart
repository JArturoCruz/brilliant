import 'package:brilliant/dominio/posicion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Posicion', () {
    test('dos posiciones con la misma fila y columna son iguales', () {
      expect(const Posicion(2, 3), const Posicion(2, 3));
      expect(const Posicion(2, 3).hashCode, const Posicion(2, 3).hashCode);
    });

    test('posiciones con distinta fila o columna no son iguales', () {
      expect(const Posicion(2, 3), isNot(const Posicion(3, 2)));
      expect(const Posicion(2, 3), isNot(const Posicion(2, 4)));
    });

    test('toString muestra (fila, columna)', () {
      expect(const Posicion(1, 5).toString(), '(1, 5)');
    });

    test('sirve como clave de Map', () {
      final mapa = {const Posicion(0, 0): 'a'};
      expect(mapa[const Posicion(0, 0)], 'a');
    });
  });
}

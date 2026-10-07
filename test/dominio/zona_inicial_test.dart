import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZonaInicial', () {
    test('tiene exactamente 6 celdas', () {
      expect(ZonaInicial.posiciones.length, ZonaInicial.cantidadCeldas);
    });

    test('es válida con los números 1 a 6 en cualquier orden', () {
      expect(ZonaInicial.esValida([6, 1, 4, 2, 5, 3]), isTrue);
    });

    test('no es válida si falta alguna celda por llenar', () {
      expect(ZonaInicial.esValida([1, 2, 3, 4, 5, null]), isFalse);
    });

    test('no es válida si un número se repite', () {
      expect(ZonaInicial.esValida([1, 1, 3, 4, 5, 6]), isFalse);
    });

    test('no es válida si algún número está fuera de 1-6', () {
      expect(ZonaInicial.esValida([1, 2, 3, 4, 5, 7]), isFalse);
    });

    test('no es válida con una lista de longitud distinta a 6', () {
      expect(ZonaInicial.esValida([1, 2, 3, 4, 5]), isFalse);
    });
  });
}

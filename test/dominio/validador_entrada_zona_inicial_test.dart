import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/validador_entrada_zona_inicial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validador = ValidadorEntradaZonaInicial();
  const a = Posicion(0, 0);
  const b = Posicion(0, 1);

  group('ValidadorEntradaZonaInicial', () {
    test('no hay conflicto si el número no está en ninguna otra celda', () {
      final valores = {a: null, b: 2};
      expect(validador.conflictoAl(valores, a, 5), isNull);
    });

    test('devuelve la celda donde ya está el número repetido', () {
      final valores = {a: null, b: 5};
      expect(validador.conflictoAl(valores, a, 5), b);
    });

    test('no reporta conflicto contra la propia celda que se está editando', () {
      final valores = {a: 5, b: null};
      expect(validador.conflictoAl(valores, a, 5), isNull);
    });
  });
}

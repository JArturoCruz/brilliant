import 'package:brilliant/dominio/tipos/tipo.dart';
import 'package:brilliant/dominio/tipos/tipo_verde.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tipo = TipoVerde();

  group('TipoVerde', () {
    test('acepta cualquier número, repetido o no', () {
      expect(tipo.esPosibleAgregar([], 1), isTrue);
      expect(tipo.esPosibleAgregar([1, 2, 3], 3), isTrue);
      expect(tipo.esPosibleAgregar([1, 1, 1], 6), isTrue);
    });

    test('puntuaciones: 4/3/2 para 1º/2º/3º y 0 de ahí en adelante', () {
      expect(tipo.puntosPorPosicion(1), 4);
      expect(tipo.puntosPorPosicion(2), 3);
      expect(tipo.puntosPorPosicion(3), 2);
      expect(tipo.puntosPorPosicion(5), 0);
    });
  });
}

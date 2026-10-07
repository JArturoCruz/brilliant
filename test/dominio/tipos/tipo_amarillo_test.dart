import 'package:brilliant/dominio/tipos/tipo.dart';
import 'package:brilliant/dominio/tipos/tipo_amarillo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tipo = TipoAmarillo();

  group('TipoAmarillo', () {
    test('acepta un número que todavía no está en la región', () {
      expect(tipo.esPosibleAgregar([1, 2], 3), isTrue);
    });

    test('rechaza un número ya colocado (regla de todos distintos)', () {
      expect(tipo.esPosibleAgregar([1, 2], 2), isFalse);
    });

    test('puntuaciones: 8/6/4 para 1º/2º/3º', () {
      expect(tipo.puntosPorPosicion(1), 8);
      expect(tipo.puntosPorPosicion(2), 6);
      expect(tipo.puntosPorPosicion(3), 4);
      expect(tipo.puntosPorPosicion(4), 0);
    });
  });
}

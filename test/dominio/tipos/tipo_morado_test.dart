import 'package:brilliant/dominio/tipos/tipo.dart';
import 'package:brilliant/dominio/tipos/tipo_morado.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tipo = TipoMorado();

  group('TipoMorado', () {
    test('acepta el primer y el segundo número distinto', () {
      expect(tipo.esPosibleAgregar([], 1), isTrue);
      expect(tipo.esPosibleAgregar([1], 2), isTrue);
    });

    test('acepta repetir alguno de los dos números ya usados', () {
      expect(tipo.esPosibleAgregar([1, 2], 1), isTrue);
      expect(tipo.esPosibleAgregar([1, 2], 2), isTrue);
    });

    test('rechaza un tercer número distinto', () {
      expect(tipo.esPosibleAgregar([1, 2], 3), isFalse);
    });

    test('puntuaciones: 8/6/4 para 1º/2º/3º', () {
      expect(tipo.puntosPorPosicion(1), 8);
      expect(tipo.puntosPorPosicion(2), 6);
      expect(tipo.puntosPorPosicion(3), 4);
      expect(tipo.puntosPorPosicion(4), 0);
    });
  });
}

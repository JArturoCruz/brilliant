import 'package:brilliant/dominio/tipos/tipo.dart';
import 'package:brilliant/dominio/tipos/tipo_azul.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tipo = TipoAzul();

  group('TipoAzul', () {
    test('acepta cualquier número si la región está vacía', () {
      expect(tipo.esPosibleAgregar([], 4), isTrue);
    });

    test('acepta el mismo número ya colocado', () {
      expect(tipo.esPosibleAgregar([4, 4], 4), isTrue);
    });

    test('rechaza un número distinto al ya colocado', () {
      expect(tipo.esPosibleAgregar([4], 5), isFalse);
    });

    test('puntuaciones: 7/5/3 para 1º/2º/3º y 0 de ahí en adelante', () {
      expect(tipo.puntosPorPosicion(1), 7);
      expect(tipo.puntosPorPosicion(2), 5);
      expect(tipo.puntosPorPosicion(3), 3);
      expect(tipo.puntosPorPosicion(4), 0);
    });

    test('expone su color y descripción', () {
      expect(tipo.descripcion, isNotEmpty);
      expect(tipo.color, isNotNull);
    });
  });
}

import 'package:brilliant/dominio/tipos/estado_region.dart';
import 'package:brilliant/dominio/tipos/tipo_azul.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tipo = TipoAzul();

  group('TipoEstadoRegion.regionEsValida', () {
    test('true si todos los valores respetan la regla del Tipo', () {
      expect(tipo.regionEsValida([3, 3, 3]), isTrue);
    });

    test('false si algún valor rompe la regla del Tipo', () {
      expect(tipo.regionEsValida([3, 3, 4]), isFalse);
    });
  });

  group('TipoEstadoRegion.calcularEstado', () {
    test('incompleta si hay alguna celda sin llenar', () {
      expect(tipo.calcularEstado([3, null, 3]), EstadoRegion.incompleta);
    });

    test('completa si todas las celdas están llenas y la regla se cumple', () {
      expect(tipo.calcularEstado([3, 3, 3]), EstadoRegion.completa);
    });

    test('incompleta si todas las celdas están llenas pero la regla se rompe', () {
      expect(tipo.calcularEstado([3, 4, 3]), EstadoRegion.incompleta);
    });
  });
}

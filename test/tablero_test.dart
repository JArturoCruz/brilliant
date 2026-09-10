import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tablero.dart';
import 'package:brilliant/validador.dart';

void main() {
  group('Extracción y coordenadas del tablero', () {
    test('Extrae lista vacía cuando el tablero no tiene números', () {
      final tablero = TableroJuego();
      expect(tablero.extraer(RegionTablero.amarilla), isEmpty);
    });

    test('Extrae únicamente números de las celdas ocupadas de la región amarilla (5 celdas)', () {
      final tablero = TableroJuego();
      tablero.asignarValor(0, 0, 10);
      tablero.asignarValor(3, 3, 20);
      tablero.asignarValor(6, 6, 30);

      final valores = tablero.extraer(RegionTablero.amarilla);
      expect(valores, equals([10, 20, 30]));
    });

    test('Regiones del mismo color mantienen independencia de coordenadas', () {
      final tablero = TableroJuego();
      tablero.asignarValor(0, 2, 7); // Pertenece a Azul 1
      tablero.asignarValor(4, 6, 9); // Pertenece a Azul 2

      expect(tablero.extraer(RegionTablero.azul1), equals([7]));
      expect(tablero.extraer(RegionTablero.azul2), equals([9]));
    });

    test('Suma total de celdas mapeadas da exactamente 49 (7x7)', () {
      final totalCeldas = TableroJuego.coordenadasPorRegion.values
          .fold<int>(0, (acum, lista) => acum + lista.length);
      expect(totalCeldas, equals(49));
    });
  });

  group('Reglas: Región Roja (Todos los números deben ser diferentes)', () {
    test('Región vacía es válida', () {
      expect(ValidadorRegiones.validarRoja([]), isTrue);
    });

    test('Región medio llena con números únicos es válida', () {
      expect(ValidadorRegiones.validarRoja([1, 4, 8]), isTrue);
    });

    test('Región llena con números diferentes es válida', () {
      expect(ValidadorRegiones.validarRoja([1, 2, 3, 4, 5, 6]), isTrue);
    });

    test('Región con números repetidos es inválida', () {
      expect(ValidadorRegiones.validarRoja([3, 5, 3]), isFalse);
    });
  });

  group('Reglas: Región Amarilla (Todos los números deben ser diferentes)', () {
    test('Región vacía es válida', () {
      expect(ValidadorRegiones.validarAmarilla([]), isTrue);
    });

    test('Región con 5 números únicos es válida', () {
      expect(ValidadorRegiones.validarAmarilla([10, 20, 30, 40, 50]), isTrue);
    });

    test('Región con duplicados es inválida', () {
      expect(ValidadorRegiones.validarAmarilla([7, 2, 7]), isFalse);
    });
  });

  group('Reglas: Región Verde (Cualquier número permitido)', () {
    test('Válido vacía, con números repetidos o únicos', () {
      expect(ValidadorRegiones.validarVerde([]), isTrue);
      expect(ValidadorRegiones.validarVerde([9, 9, 9, 9]), isTrue);
      expect(ValidadorRegiones.validarVerde([1, 2, 3, 4]), isTrue);
    });
  });

  group('Reglas: Región Azul (Solo un único número permitido)', () {
    test('Región vacía es válida', () {
      expect(ValidadorRegiones.validarAzul([]), isTrue);
    });

    test('Región con un solo número o varias repeticiones del mismo es válida', () {
      expect(ValidadorRegiones.validarAzul([6]), isTrue);
      expect(ValidadorRegiones.validarAzul([6, 6, 6, 6]), isTrue);
    });

    test('Región con dos o más números distintos es inválida', () {
      expect(ValidadorRegiones.validarAzul([6, 5]), isFalse);
      expect(ValidadorRegiones.validarAzul([6, 6, 6, 1]), isFalse);
    });
  });

  group('Reglas: Región Morada (Máximo 2 números distintos)', () {
    test('Región vacía o con un solo número repetido es válida', () {
      expect(ValidadorRegiones.validarMorada([]), isTrue);
      expect(ValidadorRegiones.validarMorada([4, 4, 4]), isTrue);
    });

    test('Región medio llena o llena con exactamente 2 números distintos es válida', () {
      expect(ValidadorRegiones.validarMorada([2, 8, 2, 8, 8]), isTrue);
    });

    test('Región con 3 o más números distintos es inválida', () {
      expect(ValidadorRegiones.validarMorada([2, 4, 9]), isFalse);
      expect(ValidadorRegiones.validarMorada([1, 2, 3, 1, 2]), isFalse);
    });
  });

  group('Prueba Integral: Validación general con esValido()', () {
    test('Detecta cuando una región azul contiene números no uniformes', () {
      final tablero = TableroJuego();
      tablero.asignarValor(0, 2, 4); // Azul 1
      tablero.asignarValor(1, 2, 5); // Azul 1 (distinto)

      final numerosExtraidos = tablero.extraer(RegionTablero.azul1);
      final resultado = ValidadorRegiones.esValido(RegionTablero.azul1, numerosExtraidos);

      expect(resultado, isFalse);
    });

    test('Acepta una región morada con solo 2 números alternados', () {
      final tablero = TableroJuego();
      tablero.asignarValor(0, 3, 1); // Morada 1
      tablero.asignarValor(0, 4, 2); // Morada 1
      tablero.asignarValor(0, 5, 1); // Morada 1

      final numerosExtraidos = tablero.extraer(RegionTablero.morada1);
      final resultado = ValidadorRegiones.esValido(RegionTablero.morada1, numerosExtraidos);

      expect(resultado, isTrue);
    });
  });
}
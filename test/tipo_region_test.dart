import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tipo_region.dart';

/// Tipo auxiliar solo para probar el mecanismo de bonificación,
/// ya que ningún tipo real lo sobreescribe todavía.
class _TipoConBonoDePrueba extends TipoRegion {
  const _TipoConBonoDePrueba();

  @override
  String get nombre => 'Prueba';

  @override
  int get puntuacionBase => 100;

  @override
  bool esValido(List<int> valores) => valores.toSet().length == valores.length;

  @override
  bool cumpleBonificacion(List<int?> valoresCompletos) => true;
}

void main() {
  group('TipoAmarilla', () {
    const tipo = TipoAmarilla();

    test('nombre y puntuación base', () {
      expect(tipo.nombre, 'Amarilla');
      expect(tipo.puntuacionBase, 50);
    });

    test('válida cuando todos los valores son distintos', () {
      expect(tipo.esValido([1, 2, 3, 4, 5]), isTrue);
    });

    test('inválida cuando hay valores repetidos', () {
      expect(tipo.esValido([1, 2, 2, 4, 5]), isFalse);
    });
  });

  group('TipoVerde', () {
    const tipo = TipoVerde();

    test('nombre y puntuación base', () {
      expect(tipo.nombre, 'Verde');
      expect(tipo.puntuacionBase, 20);
    });

    test('siempre es válida, sin restricción', () {
      expect(tipo.esValido([1, 1, 1, 1]), isTrue);
      expect(tipo.esValido([]), isTrue);
    });
  });

  group('TipoAzul', () {
    const tipo = TipoAzul();

    test('nombre y puntuación base', () {
      expect(tipo.nombre, 'Azul');
      expect(tipo.puntuacionBase, 40);
    });

    test('válida cuando hay un único número repetido', () {
      expect(tipo.esValido([3, 3, 3]), isTrue);
    });

    test('válida cuando está vacía (0 distintos)', () {
      expect(tipo.esValido([]), isTrue);
    });

    test('inválida cuando hay más de un número distinto', () {
      expect(tipo.esValido([3, 3, 4]), isFalse);
    });
  });

  group('TipoMorada', () {
    const tipo = TipoMorada();

    test('nombre y puntuación base', () {
      expect(tipo.nombre, 'Morada');
      expect(tipo.puntuacionBase, 30);
    });

    test('válida con hasta 2 números distintos', () {
      expect(tipo.esValido([1, 1, 2, 2, 1, 2]), isTrue);
    });

    test('inválida con 3 o más números distintos', () {
      expect(tipo.esValido([1, 2, 3]), isFalse);
    });
  });

  group('TipoRoja', () {
    const tipo = TipoRoja();

    test('nombre y puntuación base', () {
      expect(tipo.nombre, 'Roja');
      expect(tipo.puntuacionBase, 60);
    });

    test('válida cuando todos los valores son distintos', () {
      expect(tipo.esValido([1, 2, 3, 4, 5, 6, 7]), isTrue);
    });

    test('inválida cuando hay valores repetidos', () {
      expect(tipo.esValido([1, 2, 2]), isFalse);
    });
  });

  group('calcularEstado', () {
    const tipo = TipoAzul();

    test('incompleta si hay al menos una celda vacía', () {
      final estado = tipo.calcularEstado([3, null, 3]);
      expect(estado, EstadoRegion.incompleta);
    });

    test('incompleta si está llena pero no cumple la regla', () {
      final estado = tipo.calcularEstado([3, 4]);
      expect(estado, EstadoRegion.incompleta);
    });

    test('completa si está llena y cumple la regla', () {
      final estado = tipo.calcularEstado([3, 3, 3]);
      expect(estado, EstadoRegion.completa);
    });

    test('completaConBonificacion cuando el tipo lo define', () {
      const tipoBono = _TipoConBonoDePrueba();
      final estado = tipoBono.calcularEstado([1, 2, 3]);
      expect(estado, EstadoRegion.completaConBonificacion);
    });
  });

  group('calcularPuntuacion', () {
    test('0 puntos si la región está incompleta', () {
      const tipo = TipoRoja();
      expect(tipo.calcularPuntuacion([1, null, 3]), 0);
    });

    test('puntuación base si está completa sin bonificación', () {
      const tipo = TipoRoja();
      expect(tipo.calcularPuntuacion([1, 2, 3]), tipo.puntuacionBase);
    });

    test('puntuación base + 5 si hay bonificación', () {
      const tipoBono = _TipoConBonoDePrueba();
      expect(
        tipoBono.calcularPuntuacion([1, 2, 3]),
        tipoBono.puntuacionBase + TipoRegion.puntosBonificacion,
      );
    });
  });

  group('TiposDeRegion', () {
    test('mapea correctamente cada RegionTablero a su Tipo', () {
      expect(TiposDeRegion.obtenerTipo(RegionTablero.amarilla), isA<TipoAmarilla>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.verde1), isA<TipoVerde>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.verde2), isA<TipoVerde>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.azul1), isA<TipoAzul>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.azul2), isA<TipoAzul>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.morada1), isA<TipoMorada>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.morada2), isA<TipoMorada>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.roja1), isA<TipoRoja>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.roja2), isA<TipoRoja>());
    });
  });
}
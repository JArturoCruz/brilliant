import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/region.dart';
import 'package:brilliant/tablero.dart';
import 'package:brilliant/tipo.dart';
import 'package:brilliant/topologia_tablero.dart';
import 'package:brilliant/validador_juego.dart';

void main() {
  group('TipoAzul', () {
    const tipo = TipoAzul();

    test('color y descripción', () {
      expect(tipo.color, const Color(0xFF2196F3));
      expect(tipo.descripcion, 'Todos los números deben de ser iguales');
    });

    test('puntuaciones por posición de finalización', () {
      expect(tipo.puntuaciones, {1: 7, 2: 5, 3: 3});
    });

    test('se puede agregar si la región está vacía', () {
      expect(tipo.esPosibleAgregar([], 5), isTrue);
    });

    test('se puede agregar el mismo número repetido', () {
      expect(tipo.esPosibleAgregar([5, 5], 5), isTrue);
    });

    test('no se puede agregar un número distinto', () {
      expect(tipo.esPosibleAgregar([5, 5], 6), isFalse);
    });
  });

  group('TipoVerde', () {
    const tipo = TipoVerde();

    test('color y descripción', () {
      expect(tipo.color, const Color(0xFF4CAF50));
      expect(tipo.descripcion, 'Se puede colocar cualquier número');
    });

    test('puntuaciones por posición de finalización', () {
      expect(tipo.puntuaciones, {1: 4, 2: 3, 3: 2});
    });

    test('siempre se puede agregar, sin restricción', () {
      expect(tipo.esPosibleAgregar([1, 2, 3], 3), isTrue);
      expect(tipo.esPosibleAgregar([], 9), isTrue);
    });
  });

  group('TipoMorado', () {
    const tipo = TipoMorado();

    test('color y descripción', () {
      expect(tipo.color, const Color(0xFF9C27B0));
      expect(tipo.descripcion, 'Máximo dos números diferentes por zona');
    });

    test('puntuaciones por posición de finalización', () {
      expect(tipo.puntuaciones, {1: 8, 2: 6, 3: 4});
    });

    test('se puede agregar si ya hay 0 o 1 números distintos', () {
      expect(tipo.esPosibleAgregar([], 4), isTrue);
      expect(tipo.esPosibleAgregar([4, 4], 7), isTrue);
    });

    test('se puede repetir un número ya usado aunque haya 2 distintos', () {
      expect(tipo.esPosibleAgregar([4, 7], 4), isTrue);
    });

    test('no se puede agregar un tercer número distinto', () {
      expect(tipo.esPosibleAgregar([4, 7], 9), isFalse);
    });
  });

  group('TipoAmarillo', () {
    const tipo = TipoAmarillo();

    test('color y descripción', () {
      expect(tipo.color, const Color(0xFFFFC107));
      expect(tipo.descripcion, 'Todos los números deben de ser distintos');
    });

    test('puntuaciones por posición de finalización', () {
      expect(tipo.puntuaciones, {1: 8, 2: 6, 3: 4});
    });

    test('no se puede agregar un número ya presente', () {
      expect(tipo.esPosibleAgregar([1, 2, 3], 2), isFalse);
    });

    test('se puede agregar un número no presente', () {
      expect(tipo.esPosibleAgregar([1, 2, 3], 4), isTrue);
    });
  });

  group('TipoRojo', () {
    const tipo = TipoRojo();

    test('color y descripción', () {
      expect(tipo.color, const Color(0xFFF44336));
      expect(tipo.descripcion, 'Todos los números deben de ser distintos');
    });

    test('comparte la misma regla que Amarillo (todos distintos)', () {
      expect(tipo.esPosibleAgregar([1, 2], 2), isFalse);
      expect(tipo.esPosibleAgregar([1, 2], 3), isTrue);
    });
  });

  group('extension TipoEstadoRegion', () {
    const tipo = TipoAzul();

    test('regionEsValida es true si todos cumplen la regla entre sí', () {
      expect(tipo.regionEsValida([5, 5, 5]), isTrue);
    });

    test('regionEsValida es false si algún valor rompe la regla', () {
      expect(tipo.regionEsValida([5, 5, 6]), isFalse);
    });

    test('calcularEstado: incompleta si hay celdas vacías', () {
      expect(tipo.calcularEstado([5, null, 5]), EstadoRegion.incompleta);
    });

    test('calcularEstado: incompleta si está llena pero es inválida', () {
      expect(tipo.calcularEstado([5, 6]), EstadoRegion.incompleta);
    });

    test('calcularEstado: completa si está llena y es válida', () {
      expect(tipo.calcularEstado([5, 5, 5]), EstadoRegion.completa);
    });
  });

  group('extension TipoPuntuacion', () {
    const tipo = TipoAzul();

    test('otorga puntos al 1º, 2º y 3º en completar la región', () {
      expect(tipo.puntosPorPosicion(1), 7);
      expect(tipo.puntosPorPosicion(2), 5);
      expect(tipo.puntosPorPosicion(3), 3);
    });

    test('no otorga puntos de la 4ta posición en adelante', () {
      expect(tipo.puntosPorPosicion(4), 0);
      expect(tipo.puntosPorPosicion(10), 0);
    });
  });

  group('TiposDeRegion', () {
    test('mapea correctamente cada RegionTablero a su Tipo', () {
      expect(TiposDeRegion.obtenerTipo(RegionTablero.amarilla), isA<TipoAmarillo>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.verde1), isA<TipoVerde>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.verde2), isA<TipoVerde>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.azul1), isA<TipoAzul>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.azul2), isA<TipoAzul>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.morada1), isA<TipoMorado>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.morada2), isA<TipoMorado>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.roja1), isA<TipoRojo>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.roja2), isA<TipoRojo>());
    });
  });

  group('TopologiaTablero', () {
    test('regionDeCelda identifica la región correcta', () {
      expect(TopologiaTablero.regionDeCelda(0, 0), RegionTablero.amarilla);
      expect(TopologiaTablero.regionDeCelda(0, 2), RegionTablero.azul1);
    });

    test('regionDeCelda es null en una coordenada fuera del tablero', () {
      // El tablero 7x7 está completamente cubierto por las 9 regiones
      // (49 celdas en total), así que no existe una celda "libre" dentro
      // del rango 0-6. Se usa una coordenada fuera de rango para probar
      // el caso en que no hay región asociada.
      expect(TopologiaTablero.regionDeCelda(10, 10), isNull);
    });
  });

  group('ValidadorDeJugadas (integración tablero + topología + tipo)', () {
    const validador = ValidadorDeJugadas();

    test('respeta la regla Azul (todos iguales)', () {
      final tablero = TableroJuego();
      tablero.asignarValor(0, 2, 4); // celda de azul1
      expect(validador.puedeAsignar(tablero, 1, 2, 4), isTrue);
      expect(validador.puedeAsignar(tablero, 1, 2, 5), isFalse);
    });

    test('respeta la regla Amarillo (todos distintos)', () {
      final tablero = TableroJuego();
      tablero.asignarValor(0, 0, 3); // celda de amarilla
      expect(validador.puedeAsignar(tablero, 0, 6, 3), isFalse);
      expect(validador.puedeAsignar(tablero, 0, 6, 4), isTrue);
    });

    test('es false si la celda no pertenece a ninguna región', () {
      final tablero = TableroJuego();
      // (10,10) está fuera del tablero 7x7, que ya está completamente
      // cubierto por las 9 regiones (no hay celdas "libres" dentro de rango).
      expect(validador.puedeAsignar(tablero, 10, 10, 1), isFalse);
    });

    test('estadoDe refleja el estado real de la región', () {
      final tablero = TableroJuego();
      // azul1 tiene 4 celdas: (0,2) (1,2) (1,3) (2,3)
      expect(validador.estadoDe(tablero, RegionTablero.azul1), EstadoRegion.incompleta);

      tablero.asignarValor(0, 2, 4);
      tablero.asignarValor(1, 2, 4);
      tablero.asignarValor(1, 3, 4);
      tablero.asignarValor(2, 3, 4);
      expect(validador.estadoDe(tablero, RegionTablero.azul1), EstadoRegion.completa);
    });
  });
}
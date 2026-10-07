import 'package:brilliant/dominio/region.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/dominio/tipos/estado_region.dart';
import 'package:brilliant/dominio/topologia_tablero.dart';
import 'package:brilliant/dominio/validador_de_jugadas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validador = ValidadorDeJugadas();

  group('ValidadorDeJugadas.puedeAsignar', () {
    test('false si la celda no pertenece a ninguna región', () {
      final tablero = TableroJuego();
      expect(validador.puedeAsignar(tablero, 20, 20, 1), isFalse);
    });

    test('azul: solo permite repetir el mismo número', () {
      final tablero = TableroJuego();
      final pos = TopologiaTablero.posicionesDe(RegionTablero.azul1);
      tablero.asignarValor(pos[0].fila, pos[0].columna, 3);

      expect(validador.puedeAsignar(tablero, pos[1].fila, pos[1].columna, 3), isTrue);
      expect(validador.puedeAsignar(tablero, pos[1].fila, pos[1].columna, 4), isFalse);
    });

    test('verde: acepta cualquier número', () {
      final tablero = TableroJuego();
      final pos = TopologiaTablero.posicionesDe(RegionTablero.verde1);
      tablero.asignarValor(pos[0].fila, pos[0].columna, 6);

      expect(validador.puedeAsignar(tablero, pos[1].fila, pos[1].columna, 1), isTrue);
    });

    test('morado: admite como máximo dos números distintos', () {
      final tablero = TableroJuego();
      final pos = TopologiaTablero.posicionesDe(RegionTablero.morada1);
      tablero.asignarValor(pos[0].fila, pos[0].columna, 1);
      tablero.asignarValor(pos[1].fila, pos[1].columna, 2);

      expect(validador.puedeAsignar(tablero, pos[2].fila, pos[2].columna, 1), isTrue);
      expect(validador.puedeAsignar(tablero, pos[2].fila, pos[2].columna, 3), isFalse);
    });

    test('amarilla/roja: no admite números repetidos', () {
      final tablero = TableroJuego();
      final pos = TopologiaTablero.posicionesDe(RegionTablero.amarilla);
      tablero.asignarValor(pos[0].fila, pos[0].columna, 2);

      expect(validador.puedeAsignar(tablero, pos[1].fila, pos[1].columna, 2), isFalse);
      expect(validador.puedeAsignar(tablero, pos[1].fila, pos[1].columna, 3), isTrue);
    });
  });

  group('ValidadorDeJugadas.estadoDe', () {
    test('incompleta mientras falte alguna celda', () {
      final tablero = TableroJuego();
      expect(validador.estadoDe(tablero, RegionTablero.verde1), EstadoRegion.incompleta);
    });

    test('completa cuando todas las celdas respetan la regla', () {
      final tablero = TableroJuego();
      for (final pos in TopologiaTablero.posicionesDe(RegionTablero.azul1)) {
        tablero.asignarValor(pos.fila, pos.columna, 5);
      }
      expect(validador.estadoDe(tablero, RegionTablero.azul1), EstadoRegion.completa);
    });

    test('incompleta (regla rota) cuando los valores no respetan el tipo', () {
      final tablero = TableroJuego();
      final pos = TopologiaTablero.posicionesDe(RegionTablero.amarilla);
      for (var i = 0; i < pos.length; i++) {
        // Repite el 1 en todas las celdas: rompe la regla de "todos distintos".
        tablero.asignarValor(pos[i].fila, pos[i].columna, 1);
      }
      expect(validador.estadoDe(tablero, RegionTablero.amarilla), EstadoRegion.incompleta);
    });
  });
}

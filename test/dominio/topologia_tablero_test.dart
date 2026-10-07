import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/region.dart';
import 'package:brilliant/dominio/topologia_tablero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TopologiaTablero', () {
    test('el tablero mide 7x7', () {
      expect(TopologiaTablero.filas, 7);
      expect(TopologiaTablero.columnas, 7);
    });

    test('las 49 celdas están cubiertas por exactamente una región', () {
      final vistas = <Posicion>{};
      for (var f = 0; f < 7; f++) {
        for (var c = 0; c < 7; c++) {
          final region = TopologiaTablero.regionDeCelda(f, c);
          expect(region, isNotNull,
              reason: 'La celda ($f, $c) debería pertenecer a una región');
          vistas.add(Posicion(f, c));
        }
      }
      expect(vistas.length, 49);
    });

    test('posicionesDe(region) contiene exactamente las celdas de esa región', () {
      for (final region in RegionTablero.values) {
        for (final pos in TopologiaTablero.posicionesDe(region)) {
          expect(TopologiaTablero.regionDeCelda(pos.fila, pos.columna), region);
        }
      }
    });

    test('ninguna celda se repite entre dos regiones distintas', () {
      final contador = <Posicion, int>{};
      for (final region in RegionTablero.values) {
        for (final pos in TopologiaTablero.posicionesDe(region)) {
          contador[pos] = (contador[pos] ?? 0) + 1;
        }
      }
      expect(contador.values.every((v) => v == 1), isTrue);
    });
  });
}

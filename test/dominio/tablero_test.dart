import 'package:brilliant/dominio/region.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/dominio/topologia_tablero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TableroJuego', () {
    test('una celda nueva empieza vacía (null)', () {
      final tablero = TableroJuego();
      expect(tablero.obtenerValor(0, 0), isNull);
    });

    test('asignarValor guarda el valor y obtenerValor lo devuelve', () {
      final tablero = TableroJuego();
      tablero.asignarValor(2, 3, 5);
      expect(tablero.obtenerValor(2, 3), 5);
    });

    test('asignarValor con coordenadas fuera de rango lanza RangeError', () {
      final tablero = TableroJuego();
      expect(() => tablero.asignarValor(-1, 0, 1), throwsRangeError);
      expect(() => tablero.asignarValor(0, 7, 1), throwsRangeError);
      expect(() => tablero.asignarValor(7, 0, 1), throwsRangeError);
    });

    test('extraer omite las celdas vacías de la región', () {
      final tablero = TableroJuego();
      final posiciones = TopologiaTablero.posicionesDe(RegionTablero.verde1);
      tablero.asignarValor(posiciones[0].fila, posiciones[0].columna, 4);
      tablero.asignarValor(posiciones[1].fila, posiciones[1].columna, 2);

      expect(tablero.extraer(RegionTablero.verde1), containsAll([4, 2]));
      expect(tablero.extraer(RegionTablero.verde1).length, 2);
    });

    test('extraerCompleto conserva los null en su posición', () {
      final tablero = TableroJuego();
      final posiciones = TopologiaTablero.posicionesDe(RegionTablero.verde1);
      tablero.asignarValor(posiciones[0].fila, posiciones[0].columna, 4);

      final completo = tablero.extraerCompleto(RegionTablero.verde1);
      expect(completo.length, posiciones.length);
      expect(completo.first, 4);
      expect(completo.skip(1).every((v) => v == null), isTrue);
    });
  });
}

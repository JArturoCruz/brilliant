import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZonaInicial', () {
    test('tiene exactamente 6 celdas', () {
      expect(ZonaInicial.posiciones.length, ZonaInicial.cantidadCeldas);
    });

    test('usa las posiciones iniciales solicitadas para el mapa 2', () {
      expect(ZonaInicial.posicionesParaMapa(MapaTablero.mapa2), const [
        Posicion(0, 4),
        Posicion(2, 0),
        Posicion(3, 2),
        Posicion(4, 5),
        Posicion(5, 1),
        Posicion(6, 4),
      ]);
    });

    test('mantiene las posiciones originales para el mapa 1', () {
      expect(
        ZonaInicial.posicionesParaMapa(MapaTablero.mapa1),
        ZonaInicial.posiciones,
      );
    });

    test('usa las posiciones iniciales solicitadas para el mapa 3', () {
      expect(ZonaInicial.posicionesParaMapa(MapaTablero.mapa3), const [
        Posicion(1, 2),
        Posicion(1, 5),
        Posicion(3, 3),
        Posicion(4, 1),
        Posicion(4, 6),
        Posicion(6, 2),
      ]);
    });

    test('es válida con los números 1 a 6 en cualquier orden', () {
      expect(ZonaInicial.esValida([6, 1, 4, 2, 5, 3]), isTrue);
    });

    test('no es válida si falta alguna celda por llenar', () {
      expect(ZonaInicial.esValida([1, 2, 3, 4, 5, null]), isFalse);
    });

    test('no es válida si un número se repite', () {
      expect(ZonaInicial.esValida([1, 1, 3, 4, 5, 6]), isFalse);
    });

    test('no es válida si algún número está fuera de 1-6', () {
      expect(ZonaInicial.esValida([1, 2, 3, 4, 5, 7]), isFalse);
    });

    test('no es válida con una lista de longitud distinta a 6', () {
      expect(ZonaInicial.esValida([1, 2, 3, 4, 5]), isFalse);
    });
  });
}

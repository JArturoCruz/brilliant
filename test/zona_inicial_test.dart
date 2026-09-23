import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant/region.dart';
import 'package:brilliant/tablero.dart';
import 'package:brilliant/zona_inicial.dart';
// OJO: Si pusiste tu Cubit dentro de zona_inicial.dart, debes BORRAR la siguiente línea. 
// Si lo tienes en su propio archivo, déjala.
import 'package:brilliant/zona_inicial_cubit.dart'; 

void main() {
  group('ZonaInicial', () {
    test('tiene exactamente 6 posiciones', () {
      expect(ZonaInicial.posiciones.length, 6);
    });

    test('es inválida si falta alguna celda por llenar', () {
      // Se agrega <int?> explícitamente para evitar choques de tipos
      final valores = <int?>[1, 2, 3, 4, 5, null];
      expect(ZonaInicial.esValida(valores), isFalse);
    });

    test('es inválida si hay números repetidos', () {
      final valores = <int?>[1, 2, 2, 4, 5, 6];
      expect(ZonaInicial.esValida(valores), isFalse);
    });

    test('es inválida si algún número está fuera de 1-6', () {
      final valores = <int?>[1, 2, 3, 4, 5, 7];
      expect(ZonaInicial.esValida(valores), isFalse);
    });

    test('es válida con los números 1 a 6 sin repetir, en cualquier orden', () {
      final valores = <int?>[6, 3, 1, 5, 2, 4];
      expect(ZonaInicial.esValida(valores), isTrue);
    });
  });

  group('ZonaInicialCubit', () {
    // Nota que los test con Cubit ahora tienen "async"
    test('el estado inicial no es válido y todas las celdas están vacías', () async {
      final cubit = ZonaInicialCubit();
      expect(cubit.state.esValida, isFalse);
      expect(cubit.state.valores.values.every((v) => v == null), isTrue);
      await cubit.close(); // Se agregó "await"
    });

    test('sigue inválido mientras falten celdas por llenar', () async {
      final cubit = ZonaInicialCubit();
      for (var i = 0; i < 5; i++) {
        cubit.asignarValor(ZonaInicial.posiciones[i], i + 1);
      }
      expect(cubit.state.esValida, isFalse);
      await cubit.close();
    });

    test('se vuelve válido al llenar las 6 celdas con 1-6 sin repetir', () async {
      final cubit = ZonaInicialCubit();
      for (var i = 0; i < 6; i++) {
        cubit.asignarValor(ZonaInicial.posiciones[i], i + 1);
      }
      expect(cubit.state.esValida, isTrue);
      await cubit.close();
    });

    test('no se vuelve válido si hay un número repetido', () async {
      final cubit = ZonaInicialCubit();
      final posiciones = ZonaInicial.posiciones;
      cubit.asignarValor(posiciones[0], 1);
      cubit.asignarValor(posiciones[1], 1); // repetido
      cubit.asignarValor(posiciones[2], 3);
      cubit.asignarValor(posiciones[3], 4);
      cubit.asignarValor(posiciones[4], 5);
      cubit.asignarValor(posiciones[5], 6);
      expect(cubit.state.esValida, isFalse);
      await cubit.close();
    });

    test('ignora asignaciones a celdas fuera de la ZonaInicial', () async {
      final cubit = ZonaInicialCubit();
      const fuera = Posicion(0, 0); // pertenece a "amarilla", no a ZonaInicial
      cubit.asignarValor(fuera, 9);
      expect(cubit.state.valores.containsKey(fuera), isFalse);
      await cubit.close();
    });

    test('aplicarATablero no escribe nada si aún no es válida', () async {
      final cubit = ZonaInicialCubit();
      final tablero = TableroJuego();
      cubit.asignarValor(ZonaInicial.posiciones[0], 1); // incompleto
      cubit.aplicarATablero(tablero);

      final pos = ZonaInicial.posiciones[0];
      expect(tablero.obtenerValor(pos.fila, pos.columna), isNull);
      await cubit.close();
    });

    test('aplicarATablero escribe los 6 valores cuando ya es válida', () async {
      final cubit = ZonaInicialCubit();
      final tablero = TableroJuego();
      final posiciones = ZonaInicial.posiciones;
      for (var i = 0; i < 6; i++) {
        cubit.asignarValor(posiciones[i], i + 1);
      }
      cubit.aplicarATablero(tablero);

      for (var i = 0; i < 6; i++) {
        final pos = posiciones[i];
        expect(tablero.obtenerValor(pos.fila, pos.columna), i + 1);
      }
      await cubit.close();
    });
  });
}
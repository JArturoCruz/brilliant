import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/zona_inicial.dart';

void main() {
  group('ZonaInicialCubit - Pruebas Unitarias', () {
    late ZonaInicialCubit cubit;

    setUp(() => cubit = ZonaInicialCubit());
    tearDown(() => cubit.close());

    test('El estado inicial está vacío y no es válido', () {
      expect(cubit.state.valores.values.every((valor) => valor == null), isTrue);
      expect(cubit.state.esValida, isFalse);
    });

    test('Permite seleccionar una celda válida de la zona inicial', () {
      final primeraPos = ZonaInicial.posiciones.first;
      cubit.seleccionarCelda(primeraPos);
      expect(cubit.state.seleccionada, primeraPos);
    });

    test('Asigna valores y valida correctamente al completar las 6 celdas', () {
      for (var i = 0; i < ZonaInicial.posiciones.length; i++) {
        final pos = ZonaInicial.posiciones[i];
        cubit.seleccionarCelda(pos);
        cubit.asignarASeleccionada(i + 1);
      }
      expect(cubit.state.valores.length, 6);
      expect(cubit.state.esValida, isTrue);
    });
  });
}

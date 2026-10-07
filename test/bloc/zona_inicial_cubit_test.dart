import 'package:brilliant/bloc/mensajes_zona_inicial.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZonaInicialCubit - estado inicial', () {
    test('arranca sin valores, no válida, no iniciada, primera celda seleccionada', () {
      final cubit = ZonaInicialCubit();
      expect(cubit.state.esValida, isFalse);
      expect(cubit.state.iniciada, isFalse);
      expect(cubit.state.seleccionada, ZonaInicial.posiciones.first);
      expect(cubit.state.valores.values.every((v) => v == null), isTrue);
      cubit.close();
    });
  });

  group('ZonaInicialCubit - seleccionarCelda', () {
    test('cambia la celda seleccionada si pertenece a la ZonaInicial', () {
      final cubit = ZonaInicialCubit();
      final otra = ZonaInicial.posiciones[2];
      cubit.seleccionarCelda(otra);
      expect(cubit.state.seleccionada, otra);
      cubit.close();
    });

    test('ignora una celda que no pertenece a la ZonaInicial', () {
      final cubit = ZonaInicialCubit();
      final seleccionPrevia = cubit.state.seleccionada;
      cubit.seleccionarCelda(const Posicion(6, 6)); // esquina amarilla, no es zona inicial
      expect(cubit.state.seleccionada, seleccionPrevia);
      cubit.close();
    });
  });

  group('ZonaInicialCubit - moverSeleccion', () {
    test('avanza circularmente entre las 6 celdas', () {
      final cubit = ZonaInicialCubit();
      final primera = ZonaInicial.posiciones.first;
      final segunda = ZonaInicial.posiciones[1];
      expect(cubit.state.seleccionada, primera);

      cubit.moverSeleccion(1);
      expect(cubit.state.seleccionada, segunda);

      // Retrocede y vuelve a la primera.
      cubit.moverSeleccion(-1);
      expect(cubit.state.seleccionada, primera);
      cubit.close();
    });
  });

  group('ZonaInicialCubit - asignarASeleccionada', () {
    test('coloca el número en la celda seleccionada y avanza a la siguiente vacía', () {
      final cubit = ZonaInicialCubit();
      final primera = ZonaInicial.posiciones.first;
      final segunda = ZonaInicial.posiciones[1];

      cubit.asignarASeleccionada(4);

      expect(cubit.state.valores[primera], 4);
      expect(cubit.state.seleccionada, segunda);
      cubit.close();
    });

    test('si el número ya está en otra celda, no lo coloca y avisa', () {
      final cubit = ZonaInicialCubit();
      final primera = ZonaInicial.posiciones.first;
      final segunda = ZonaInicial.posiciones[1];

      cubit.asignarASeleccionada(4); // va en 'primera', selección pasa a 'segunda'
      final mensajeIdPrevio = cubit.state.mensajeId;

      cubit.asignarASeleccionada(4); // 'segunda' seleccionada, pero el 4 ya está en 'primera'

      expect(cubit.state.valores[segunda], isNull);
      expect(cubit.state.seleccionada, segunda); // no avanza al haber conflicto
      expect(cubit.state.mensajeId, mensajeIdPrevio + 1);
      expect(cubit.state.mensaje, MensajesZonaInicial.numeroRepetido(4, primera));
      cubit.close();
    });

    test('no hace nada si el juego ya inició', () {
      final cubit = ZonaInicialCubit();
      for (var i = 0; i < 6; i++) {
        cubit.asignarASeleccionada(i + 1);
      }
      cubit.aplicarATablero(TableroJuego());
      final estadoPrevio = cubit.state;

      cubit.asignarASeleccionada(3);

      expect(cubit.state, same(estadoPrevio));
      cubit.close();
    });
  });

  group('ZonaInicialCubit - borrarSeleccionada', () {
    test('deja la celda seleccionada en null', () {
      final cubit = ZonaInicialCubit();
      final primera = ZonaInicial.posiciones.first;
      cubit.asignarASeleccionada(2);
      cubit.seleccionarCelda(primera);

      cubit.borrarSeleccionada();

      expect(cubit.state.valores[primera], isNull);
      cubit.close();
    });
  });

  group('ZonaInicialCubit - rechazarEntrada', () {
    test('emite el mensaje de carácter inválido sin tocar los valores', () {
      final cubit = ZonaInicialCubit();
      final valoresPrevios = Map.of(cubit.state.valores);

      cubit.rechazarEntrada('a');

      expect(cubit.state.mensaje, MensajesZonaInicial.caracterInvalido('a'));
      expect(cubit.state.mensajeId, 1);
      expect(cubit.state.valores, valoresPrevios);
      cubit.close();
    });

    test('dos rechazos seguidos incrementan mensajeId cada vez', () {
      final cubit = ZonaInicialCubit();
      cubit.rechazarEntrada('a');
      cubit.rechazarEntrada('a');
      expect(cubit.state.mensajeId, 2);
      cubit.close();
    });
  });

  group('ZonaInicialCubit - flujo completo', () {
    test('llenar las 6 celdas con 1 a 6 sin repetir deja esValida en true', () {
      final cubit = ZonaInicialCubit();
      for (var i = 0; i < 6; i++) {
        cubit.asignarASeleccionada(i + 1);
      }
      expect(cubit.state.esValida, isTrue);
      expect(cubit.state.cantidadLlenas, 6);
      cubit.close();
    });

    test('aplicarATablero no hace nada si todavía no es válida', () {
      final cubit = ZonaInicialCubit();
      final tablero = TableroJuego();
      cubit.asignarASeleccionada(1); // solo una celda, todavía incompleto

      cubit.aplicarATablero(tablero);

      expect(cubit.state.iniciada, isFalse);
      expect(tablero.obtenerValor(
        ZonaInicial.posiciones.first.fila,
        ZonaInicial.posiciones.first.columna,
      ), 1); // el valor sigue solo en el estado del cubit, no se copia al tablero
      cubit.close();
    });

    test('aplicarATablero copia los valores y marca iniciada = true', () {
      final cubit = ZonaInicialCubit();
      final tablero = TableroJuego();
      for (var i = 0; i < 6; i++) {
        cubit.asignarASeleccionada(i + 1);
      }
      final valoresFinales = Map.of(cubit.state.valores);

      cubit.aplicarATablero(tablero);

      expect(cubit.state.iniciada, isTrue);
      expect(cubit.state.seleccionada, isNull);
      for (final entrada in valoresFinales.entries) {
        expect(tablero.obtenerValor(entrada.key.fila, entrada.key.columna), entrada.value);
      }
      cubit.close();
    });

    test('tras iniciar, seleccionarCelda, asignarValor, moverSeleccion y borrar ya no hacen nada', () {
      final cubit = ZonaInicialCubit();
      for (var i = 0; i < 6; i++) {
        cubit.asignarASeleccionada(i + 1);
      }
      cubit.aplicarATablero(TableroJuego());
      final estadoPrevio = cubit.state;

      cubit.seleccionarCelda(ZonaInicial.posiciones.first);
      cubit.moverSeleccion(1);
      cubit.borrarSeleccionada();
      cubit.asignarValor(ZonaInicial.posiciones.first, 1);

      expect(cubit.state, same(estadoPrevio));
      cubit.close();
    });
  });
}

import 'package:brilliant/presentacion/teclado/clasificador_tecla.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const clasificador = ClasificadorTecla();
  final teclado = HardwareKeyboard.instance;

  group('ClasificadorTecla', () {
    test('un dígito del 1 al 6 se clasifica como digitoValido', () {
      final resultado = clasificador.clasificar(_down('3'), teclado);
      expect(resultado.tipo, TipoTecla.digitoValido);
      expect(resultado.digito, 3);
    });

    test('una letra se clasifica como caracterInvalido', () {
      final resultado = clasificador.clasificar(_down('a'), teclado);
      expect(resultado.tipo, TipoTecla.caracterInvalido);
      expect(resultado.caracter, 'a');
    });

    test('el dígito 7 (fuera de 1-6) se clasifica como caracterInvalido', () {
      final resultado = clasificador.clasificar(_down('7'), teclado);
      expect(resultado.tipo, TipoTecla.caracterInvalido);
      expect(resultado.caracter, '7');
    });

    test('el dígito 0 (fuera de 1-6) se clasifica como caracterInvalido', () {
      final resultado = clasificador.clasificar(_down('0'), teclado);
      expect(resultado.tipo, TipoTecla.caracterInvalido);
    });

    test('un carácter de control (p. ej. backspace) se ignora', () {
      final resultado = clasificador.clasificar(_down('\x08'), teclado);
      expect(resultado.tipo, TipoTecla.ignorar);
    });

    test('un espacio se ignora', () {
      final resultado = clasificador.clasificar(_down(' '), teclado);
      expect(resultado.tipo, TipoTecla.ignorar);
    });

    test('un evento sin carácter (p. ej. una flecha) se ignora', () {
      final evento = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );
      final resultado = clasificador.clasificar(evento, teclado);
      expect(resultado.tipo, TipoTecla.ignorar);
    });

    test('un KeyUpEvent siempre se ignora, aunque lleve un dígito válido', () {
      const evento = KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.digit3,
        logicalKey: LogicalKeyboardKey.digit3,
        timeStamp: Duration.zero,
      );
      final resultado = clasificador.clasificar(evento, teclado);
      expect(resultado.tipo, TipoTecla.ignorar);
    });
  });
}

KeyDownEvent _down(String caracter) => KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyA,
      logicalKey: LogicalKeyboardKey.keyA,
      character: caracter,
      timeStamp: Duration.zero,
    );
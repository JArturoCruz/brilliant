import 'package:brilliant/bloc/mensajes_zona_inicial.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MensajesZonaInicial', () {
    test('numeroRepetido menciona el número y la celda en fila/columna 1-based', () {
      final mensaje = MensajesZonaInicial.numeroRepetido(5, const Posicion(1, 3));
      expect(mensaje, contains('5'));
      expect(mensaje, contains('fila 2'));
      expect(mensaje, contains('columna 4'));
    });

    test('caracterInvalido menciona el carácter rechazado', () {
      final mensaje = MensajesZonaInicial.caracterInvalido('a');
      expect(mensaje, contains('a'));
      expect(mensaje, contains('1 al 6'));
    });
  });
}

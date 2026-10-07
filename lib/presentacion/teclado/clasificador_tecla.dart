import 'package:flutter/services.dart';

/// Qué significa, para la ZonaInicial, la tecla que se acaba de presionar.
enum TipoTecla { digitoValido, ignorar, caracterInvalido }

/// Resultado inmutable de clasificar una tecla: el [tipo] y, según el
/// caso, el [digito] (1-6) o el [caracter] rechazado.
class ResultadoTecla {
  final TipoTecla tipo;
  final int? digito;
  final String? caracter;

  const ResultadoTecla._(this.tipo, {this.digito, this.caracter});

  const ResultadoTecla.digito(int digito)
      : this._(TipoTecla.digitoValido, digito: digito);
  const ResultadoTecla.ignorar() : this._(TipoTecla.ignorar);
  const ResultadoTecla.invalida(String caracter)
      : this._(TipoTecla.caracterInvalido, caracter: caracter);
}

/// Traduce un KeyEvent crudo a un [ResultadoTecla]. Es lógica pura, sin
/// efectos secundarios: no toca el Cubit ni el árbol de widgets, solo
/// clasifica. Eso permite probarla por separado de la UI.
class ClasificadorTecla {
  const ClasificadorTecla();

  static const int _codigoUno = 0x31;
  static const int _codigoSeis = 0x36;

  ResultadoTecla clasificar(KeyEvent evento, HardwareKeyboard teclado) {
    if (evento is! KeyDownEvent) return const ResultadoTecla.ignorar();

    if (teclado.isControlPressed ||
        teclado.isMetaPressed ||
        teclado.isAltPressed) {
      return const ResultadoTecla.ignorar(); // Ctrl+R, Cmd+C, etc.
    }

    final caracter = evento.character;
    if (caracter == null || caracter.trim().isEmpty) {
      return const ResultadoTecla.ignorar(); // flechas, Enter, Tab, espacio...
    }

    final codigo = caracter.codeUnitAt(0);
    if (caracter.length == 1 && codigo >= _codigoUno && codigo <= _codigoSeis) {
      return ResultadoTecla.digito(codigo - _codigoUno + 1);
    }
    if (codigo < 0x20 || codigo == 0x7F) {
      return const ResultadoTecla.ignorar(); // Backspace, Delete, Escape...
    }

    return ResultadoTecla.invalida(caracter);
  }
}

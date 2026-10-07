import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import 'interceptor_entrada_invalida.dart';

/// Traduce el teclado a llamadas al Cubit:
///  - 1 a 6 (fila superior o teclado numérico): coloca el número.
///  - Backspace / Delete: borra la casilla seleccionada.
///  - Flechas: mueven la selección entre las 6 casillas señaladas.
///  - Cualquier otro carácter: lo resuelve InterceptorEntradaInvalida.
class AtajosTecladoZonaInicial extends StatelessWidget {
  const AtajosTecladoZonaInicial({super.key, required this.child});

  final Widget child;

  static const _digitos = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];

  static const _numpad = [
    LogicalKeyboardKey.numpad1,
    LogicalKeyboardKey.numpad2,
    LogicalKeyboardKey.numpad3,
    LogicalKeyboardKey.numpad4,
    LogicalKeyboardKey.numpad5,
    LogicalKeyboardKey.numpad6,
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ZonaInicialCubit>();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        for (var i = 0; i < 6; i++) ...{
          SingleActivator(_digitos[i]): () => cubit.asignarASeleccionada(i + 1),
          SingleActivator(_numpad[i]): () => cubit.asignarASeleccionada(i + 1),
        },
        const SingleActivator(LogicalKeyboardKey.backspace):
            cubit.borrarSeleccionada,
        const SingleActivator(LogicalKeyboardKey.delete):
            cubit.borrarSeleccionada,
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            cubit.moverSeleccion(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            cubit.moverSeleccion(1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            cubit.moverSeleccion(-1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            cubit.moverSeleccion(-1),
      },
      child: InterceptorEntradaInvalida(child: child),
    );
  }
}

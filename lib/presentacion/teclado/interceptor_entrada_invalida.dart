import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import 'clasificador_tecla.dart';

/// Atrapa cualquier tecla que no fue absorbida por los atajos conocidos
/// (ver AtajosTecladoZonaInicial) y, si es un carácter que no es un dígito
/// del 1 al 6, pide al Cubit que avise al usuario. Delega la clasificación
/// en ClasificadorTecla; su única responsabilidad es conectar ese
/// resultado con el foco de Flutter y el Cubit.
class InterceptorEntradaInvalida extends StatelessWidget {
  const InterceptorEntradaInvalida({
    super.key,
    required this.child,
    this.clasificador = const ClasificadorTecla(),
  });

  final Widget child;
  final ClasificadorTecla clasificador;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ZonaInicialCubit>();

    return Focus(
      autofocus: true,
      onKeyEvent: (nodo, evento) {
        final resultado =
            clasificador.clasificar(evento, HardwareKeyboard.instance);
        if (resultado.tipo != TipoTecla.caracterInvalido) {
          return KeyEventResult.ignored;
        }
        cubit.rechazarEntrada(resultado.caracter!);
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';

/// Muestra en un SnackBar los avisos que emite el Cubit (número repetido,
/// carácter inválido, etc.). Su única responsabilidad es "cómo" se
/// muestran; el "qué" y el "cuándo" los decide el Cubit.
class MensajesZonaInicialListener extends StatelessWidget {
  const MensajesZonaInicialListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ZonaInicialCubit, ZonaInicialState>(
      listenWhen: (previo, actual) =>
          actual.mensajeId != previo.mensajeId && actual.mensaje != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.mensaje!),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
      },
      child: child,
    );
  }
}

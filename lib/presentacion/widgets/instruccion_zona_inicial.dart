import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/juego_bloc.dart';
import '../../bloc/juego_state.dart';
import '../../bloc/zona_inicial_cubit.dart';
import '../../dominio/zona_inicial.dart';

/// Texto de ayuda sobre el tablero: su único trabajo es describir en
/// palabras el estado actual del llenado.
class InstruccionZonaInicial extends StatelessWidget {
  const InstruccionZonaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
      builder: (context, zonaState) {
        return BlocBuilder<JuegoBloc, JuegoState>(
          builder: (context, juegoState) {
            if (zonaState.iniciada &&
                juegoState.fase != FaseTurno.inicio) {
              return const SizedBox.shrink();
            }

            final texto = zonaState.iniciada
                ? '¡Configuración lista!'
                : 'Toca una casilla señalada y coloca los números del 1 al 6 '
                    'sin repetir (${zonaState.cantidadLlenas}/'
                    '${ZonaInicial.cantidadCeldas})';
            return Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            );
          },
        );
      },
    );
  }
}

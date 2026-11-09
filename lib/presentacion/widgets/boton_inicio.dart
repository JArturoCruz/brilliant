import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import '../../dominio/posicion.dart';
import '../../dominio/tablero.dart';

/// Botón que confirma la configuración inicial. Solo se habilita cuando
/// las 6 celdas son válidas y aún no se ha iniciado la partida.
class BotonInicio extends StatelessWidget {
  const BotonInicio({
    super.key,
    required this.tablero,
    this.onStart,
  });

  final TableroJuego tablero;
  final Future<void> Function(Map<Posicion, int>)? onStart;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            // Deshabilitado hasta que las 6 celdas sean válidas.
            onPressed: state.esValida && !state.iniciada
                ? () async {
                      final valoresValidos = {
                        for (final entry in state.valores.entries)
                          if (entry.value != null) entry.key: entry.value!
                      };

                      if (onStart != null) {
                        await onStart!(valoresValidos);
                      } else {
                        context.read<ZonaInicialCubit>().aplicarATablero(tablero);
                        context.read<JuegoBloc>().add(IniciarTurno(valoresValidos));
                      }
                  }
                : null,
            child: const Text('Inicio', style: TextStyle(fontSize: 18)),
          ),
        );
      },
    );
  }
}

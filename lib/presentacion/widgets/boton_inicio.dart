import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import '../../dominio/tablero.dart';

/// Botón que confirma la configuración inicial. Solo se habilita cuando
/// las 6 celdas son válidas y aún no se ha iniciado la partida.
class BotonInicio extends StatelessWidget {
  const BotonInicio({super.key, required this.tablero});

  final TableroJuego tablero;

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
                ? () {
                    // 1. Tu lógica original: Aplica la configuración de las 6 zonas
                    context.read<ZonaInicialCubit>().aplicarATablero(tablero);

                    // 2. Filtramos el mapa para garantizar que no haya nulos y coincida el tipo
                    final valoresValidos = {
                      for (final entry in state.valores.entries)
                        if (entry.value != null) entry.key: entry.value!
                    };

                    // 3. Le pasamos las 6 posiciones validadas al BLoC y tiramos dados
                    context.read<JuegoBloc>().add(IniciarTurno(valoresValidos));
                  }
                : null,
            child: const Text('Inicio', style: TextStyle(fontSize: 18)),
          ),
        );
      },
    );
  }
}
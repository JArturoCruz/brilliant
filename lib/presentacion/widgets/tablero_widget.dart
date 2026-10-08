import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import '../../dominio/posicion.dart';
import '../../dominio/topologia_tablero.dart';
import 'celda_tablero_widget.dart';

/// Arma la cuadrícula 7x7 a partir de TopologiaTablero. Su única
/// responsabilidad es el layout del tablero; el pintado de cada celda vive
/// en CeldaTableroWidget.
class TableroWidget extends StatelessWidget {
  const TableroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        // 1. Escuchamos al JuegoBloc para saber el estado de la partida (iluminación, dados)
        child: BlocBuilder<JuegoBloc, JuegoState>(
          builder: (context, juegoState) {
            // 2. Mantenemos tu Cubit original para las 6 zonas iniciales
            return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
              builder: (context, zonaState) {
                return Column(
                  children: [
                    for (var f = 0; f < TopologiaTablero.filas; f++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var c = 0; c < TopologiaTablero.columnas; c++)
                              Expanded(
                                // 3. Capturamos los clics de las fases del juego
                                child: GestureDetector(
                                  // Usamos hit test opaque para asegurar que capture el toque sobre la celda
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    // Verificamos si estamos en la fase de elegir el ancla en el tablero
                                    if (juegoState.fase == FaseTurno.seleccionandoCasilla) {
                                      context.read<JuegoBloc>().add(SeleccionarCasillaAncla(f, c));
                                    } 
                                    // NUEVO -> Fase: Colocando el número sobrante
                                    else if (juegoState.fase == FaseTurno.colocandoNumero) {
                                      context.read<JuegoBloc>().add(ColocarNumero(f, c));
                                    }
                                  },
                                  child: CeldaTableroWidget(
                                    posicion: Posicion(f, c),
                                    state: zonaState,
                                    // 4. PASAMOS LOS DATOS DEL JUEGO A LA CELDA
                                    casillaJuego: juegoState.tablero[f][c], 
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
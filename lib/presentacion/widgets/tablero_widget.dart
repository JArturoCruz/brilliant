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
        child: BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
          builder: (context, state) {
            return Column(
              children: [
                for (var f = 0; f < TopologiaTablero.filas; f++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < TopologiaTablero.columnas; c++)
                          Expanded(
                            child: CeldaTableroWidget(
                              posicion: Posicion(f, c),
                              state: state,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

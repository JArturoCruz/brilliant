import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'region.dart';
import 'tipo.dart';
import 'topologia_tablero.dart';
import 'zona_inicial.dart';
import 'bloc/zona_inicial_cubit.dart';

/// Dibuja el tablero 7x7. Los colores salen de TopologiaTablero + Tipo,
/// así que el diseño vive en un solo lugar. Las 6 celdas de la ZonaInicial
/// se señalan con borde blanco y son interactivas mientras no se inicie.
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
                            child: _Celda(posicion: Posicion(f, c), state: state),
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

class _Celda extends StatelessWidget {
  final Posicion posicion;
  final ZonaInicialState state;

  const _Celda({required this.posicion, required this.state});

  @override
  Widget build(BuildContext context) {
    final region =
        TopologiaTablero.regionDeCelda(posicion.fila, posicion.columna);
    final color = region == null
        ? Colors.grey.shade800
        : TiposDeRegion.obtenerTipo(region).color;

    final esInicial = ZonaInicial.posiciones.contains(posicion);
    final seleccionada = state.seleccionada == posicion;
    final valor = state.valores[posicion];

    Widget? contenido;
    if (valor != null) {
      contenido = _texto('$valor', Colors.white);
    } else if (esInicial) {
      contenido = _texto('?', Colors.white70);
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        onTap: esInicial && !state.iniciada
            ? () => context.read<ZonaInicialCubit>().seleccionarCelda(posicion)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: esInicial
                ? Border.all(color: Colors.white, width: seleccionada ? 4 : 2)
                : null,
            boxShadow: seleccionada
                ? [
                    BoxShadow(
                      color: Colors.white.withAlpha(160),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: contenido,
        ),
      ),
    );
  }

  Widget _texto(String s, Color c) => Padding(
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          child: Text(
            s,
            style: TextStyle(
              color: c,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
            ),
          ),
        ),
      );
}
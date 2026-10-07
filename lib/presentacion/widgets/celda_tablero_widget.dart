import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import '../../dominio/posicion.dart';
import '../../dominio/tipos/tipos_de_region.dart';
import '../../dominio/topologia_tablero.dart';
import '../../dominio/zona_inicial.dart';

/// Una sola celda del tablero: su único trabajo es pintarse según su
/// región y reaccionar al toque cuando pertenece a la ZonaInicial. No
/// decide reglas de juego ni sabe nada del resto del tablero.
class CeldaTableroWidget extends StatelessWidget {
  const CeldaTableroWidget({
    super.key,
    required this.posicion,
    required this.state,
  });

  final Posicion posicion;
  final ZonaInicialState state;

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

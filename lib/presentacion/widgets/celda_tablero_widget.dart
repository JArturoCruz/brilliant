import 'package:brilliant/dominio/casilla.dart';
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
    this.casillaJuego, // Recibimos el estado de la casilla desde JuegoBloc
  });

  final Posicion posicion;
  final ZonaInicialState state;
  final Casilla? casillaJuego; // Nueva variable opcional

  @override
  Widget build(BuildContext context) {
    final region =
        TopologiaTablero.regionDeCelda(posicion.fila, posicion.columna);
    final color = region == null
        ? Colors.grey.shade800
        : TiposDeRegion.obtenerTipo(region).color;

    final esInicial = ZonaInicial.posiciones.contains(posicion);
    final seleccionada = state.seleccionada == posicion;
    final valorInicial = state.valores[posicion];

    // 1. LÓGICA DE CONTENIDO (¿Qué número mostramos?)
    Widget? contenido;
    
    // Si el juego ya inició, mostramos los números generados por el JuegoBloc
    if (state.iniciada && casillaJuego?.valorActual != null) {
      contenido = _texto('${casillaJuego!.valorActual}', Colors.white);
    } 
    // Si no ha iniciado, mantenemos tu lógica de la configuración inicial
    else if (valorInicial != null) {
      contenido = _texto('$valorInicial', Colors.white);
    } else if (esInicial) {
      contenido = _texto('?', Colors.white70);
    } else if (casillaJuego?.valorActual != null) {
      // Opcional: Mostrar los números del tablero de fondo tenuemente antes de iniciar
      contenido = _texto('${casillaJuego!.valorActual}', Colors.white24);
    }

    // 2. LÓGICA DE DECORACIÓN (Bordes y sombras de iluminación)
    Border? bordeActual;
    List<BoxShadow>? sombraActual;

    // Si la casilla está iluminada por las reglas del juego (posible ancla)
    if (casillaJuego?.iluminacion == EstadoIluminacion.posibleAncla) {
      bordeActual = Border.all(color: Colors.yellowAccent, width: 4);
      sombraActual = [
        BoxShadow(
          color: Colors.yellowAccent.withAlpha(160),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
    } 
    // Si la casilla está iluminada para colocar el segundo dado
    else if (casillaJuego?.iluminacion == EstadoIluminacion.posibleColocacion) {
      bordeActual = Border.all(color: Colors.greenAccent, width: 4);
      sombraActual = [
        BoxShadow(
          color: Colors.greenAccent.withAlpha(160),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
    } 
    // Si no está iluminada por el juego, aplicamos tu lógica original de zona inicial
    else if (esInicial) {
      bordeActual = Border.all(color: Colors.white, width: seleccionada ? 4 : 2);
      if (seleccionada) {
        sombraActual = [
          BoxShadow(
            color: Colors.white.withAlpha(160),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ];
      }
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        // Al estar iniciada la partida, esto es null y el tap pasa a TableroWidget
        onTap: esInicial && !state.iniciada
            ? () => context.read<ZonaInicialCubit>().seleccionarCelda(posicion)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: bordeActual,
            boxShadow: sombraActual,
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
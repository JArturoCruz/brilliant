import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/casilla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import '../../dominio/mapa_tablero.dart';
import '../../dominio/posicion.dart';
import '../../dominio/region.dart';
import '../../dominio/topologia_tablero.dart';
import '../tema_mesa.dart';

/// Una sola celda del tablero: su único trabajo es pintarse según su
/// región y reaccionar al toque cuando pertenece a la ZonaInicial. No
/// decide reglas de juego ni sabe nada del resto del tablero.
class CeldaTableroWidget extends StatelessWidget {
  const CeldaTableroWidget({
    super.key,
    required this.posicion,
    required this.state,
    this.mapa = MapaTablero.mapa1,
    this.casillaJuego,
  });

  final Posicion posicion;
  final ZonaInicialState state;
  final MapaTablero mapa;
  final Casilla? casillaJuego;

  @override
  Widget build(BuildContext context) {
    final region = TopologiaTablero.regionDeCelda(
      posicion.fila,
      posicion.columna,
      mapa: mapa,
    );
    final regionColor = region == null ? null : mapa.tipoDe(region).color;
    final color = regionColor == null
        ? TemaMesa.papel
        : region == RegionTablero.blanca
        ? regionColor
        : Color.lerp(regionColor, TemaMesa.papel, 0.16)!;
    final fragmentada = region != null && mapa.regionEstaFragmentada(region);

    final esInicial = state.valores.containsKey(posicion);
    final seleccionada = state.seleccionada == posicion;
    final valorInicial = state.valores[posicion];

    // Envolvemos el contenido con BlocBuilder<JuegoBloc, JuegoState> para detectar
    // al instante si esta celda es la elegida provisionalmente para confirmar.
    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, juegoState) {
        // Verificamos si esta celda específica es la que está en espera de confirmación
        final esProvisionalActual =
            juegoState.fase == FaseTurno.confirmandoJugada &&
            juegoState.filaProvisional == posicion.fila &&
            juegoState.columnaProvisional == posicion.columna;
        final esAnclaSeleccionada =
            juegoState.fase == FaseTurno.colocandoNumero &&
            juegoState.filaAncla == posicion.fila &&
            juegoState.columnaAncla == posicion.columna;

        // 1. LÓGICA DE CONTENIDO (¿Qué número mostramos?)
        Widget? contenido;

        if (esProvisionalActual && juegoState.numeroColocar != null) {
          contenido = KeyedSubtree(
            key: ValueKey('provisional-${juegoState.numeroColocar}'),
            child: _texto('${juegoState.numeroColocar}'),
          );
        }
        // Si el juego ya inició y la casilla tiene valor, mostramos el número oficial
        else if (state.iniciada && casillaJuego?.valorActual != null) {
          contenido = KeyedSubtree(
            key: ValueKey('confirmado-${casillaJuego!.valorActual}'),
            child: _texto('${casillaJuego!.valorActual}'),
          );
        }
        // Si no ha iniciado, mantenemos tu lógica de la configuración inicial
        else if (valorInicial != null) {
          contenido = KeyedSubtree(
            key: ValueKey('inicial-$valorInicial'),
            child: _texto('$valorInicial'),
          );
        } else if (esInicial) {
          contenido = KeyedSubtree(
            key: const ValueKey('casilla-inicial-vacia'),
            child: _texto('?'),
          );
        } else if (casillaJuego?.valorActual != null) {
          contenido = KeyedSubtree(
            key: ValueKey('numero-previo-${casillaJuego!.valorActual}'),
            child: _texto('${casillaJuego!.valorActual}'),
          );
        }

        // 2. LÓGICA DE DECORACIÓN (Bordes y sombras de iluminación)
        Border? bordeActual;
        List<BoxShadow>? sombraActual;
        var colorActual = color;

        // Si está en fase provisional, le ponemos un borde especial (ej. ámbar o blanco intermitente)
        if (esProvisionalActual) {
          bordeActual = Border.all(color: TemaMesa.nogalOscuro, width: 3);
          sombraActual = [
            BoxShadow(
              color: TemaMesa.dorado.withAlpha(150),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ];
        }
        // Si la casilla está iluminada por las reglas del juego (posible ancla)
        else if (casillaJuego?.iluminacion == EstadoIluminacion.posibleAncla) {
          const resaltado = Color(0xFFFFEB3B);
          colorActual = Color.lerp(color, resaltado, 0.35)!;
          bordeActual = Border.all(color: resaltado, width: 3.5);
          sombraActual = [
            BoxShadow(
              color: resaltado.withAlpha(180),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            const BoxShadow(color: Colors.black87, spreadRadius: 1.5),
          ];
        }
        // Si la casilla está iluminada para colocar el segundo dado
        else if (casillaJuego?.iluminacion ==
            EstadoIluminacion.posibleColocacion) {
          const resaltado = Color(0xFF00E676);
          colorActual = Color.lerp(color, resaltado, 0.35)!;
          bordeActual = Border.all(color: resaltado, width: 3.5);
          sombraActual = [
            BoxShadow(
              color: resaltado.withAlpha(180),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            const BoxShadow(color: Colors.black87, spreadRadius: 1.5),
          ];
        }
        // Si no está iluminada por el juego, aplicamos tu lógica original de zona inicial
        else if (esInicial) {
          bordeActual = Border.all(
            color: TemaMesa.papelClaro,
            width: seleccionada ? 4 : 2,
          );
          if (seleccionada) {
            sombraActual = [
              BoxShadow(
                color: TemaMesa.nogalOscuro.withAlpha(140),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ];
          }
        }

        return Padding(
          padding: const EdgeInsets.all(3),
          child: GestureDetector(
            onTap: esInicial && !state.iniciada
                ? () => context.read<ZonaInicialCubit>().seleccionarCelda(
                    posicion,
                  )
                : null,
            child: AnimatedScale(
              scale: esAnclaSeleccionada
                  ? 1.12
                  : casillaJuego?.iluminacion ==
                        EstadoIluminacion.posibleColocacion
                  ? 1.035
                  : 1,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorActual,
                  borderRadius: BorderRadius.circular(7),
                  border: bordeActual,
                  boxShadow: sombraActual,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (fragmentada)
                      Positioned(
                        top: 1,
                        left: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            mapa.etiquetaRegion(region),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child:
                          contenido ??
                          const SizedBox.shrink(key: ValueKey('sin-numero')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _texto(String s) => Padding(
    padding: const EdgeInsets.all(4),
    child: FittedBox(
      child: Text(s, style: TemaMesa.numeroTablero.copyWith(fontSize: 30)),
    ),
  );
}

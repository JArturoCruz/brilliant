import 'dart:math' as math;

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
    final triangulo = mapa.id == 4 && region == RegionTablero.roja2;

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
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
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
                    if (fragmentada)
                      Positioned(
                        top: 3,
                        left: 3,
                        child: triangulo
                            ? CustomPaint(
                                key: ValueKey(
                                  'triangulo-zona-${posicion.fila}-${posicion.columna}',
                                ),
                                size: const Size(10, 10),
                                painter: _PintorTriangulo(
                                  Color.lerp(color, Colors.black, 0.5)!,
                                  Color.lerp(color, Colors.white, 0.4)!,
                                ),
                              )
                            : Transform.rotate(
                                key: ValueKey(
                                  'rombo-zona-${posicion.fila}-${posicion.columna}',
                                ),
                                angle: math.pi / 4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Color.lerp(color, Colors.black, 0.5),
                                    border: Border.all(
                                      color: Color.lerp(
                                        color,
                                        Colors.white,
                                        0.4,
                                      )!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
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

class _PintorTriangulo extends CustomPainter {
  const _PintorTriangulo(this.color, this.borde);

  final Color color;
  final Color borde;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0.5)
      ..lineTo(size.width - 0.5, size.height - 0.5)
      ..lineTo(0.5, size.height - 0.5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PintorTriangulo anterior) =>
      anterior.color != color || anterior.borde != borde;
}

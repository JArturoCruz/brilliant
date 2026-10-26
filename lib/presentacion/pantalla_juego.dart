import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/presentacion/widgets/historial_partida_widget.dart';
import 'package:brilliant/presentacion/widgets/panel_datos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/zona_inicial_cubit.dart';
import '../dominio/tablero.dart';
import 'mensajes/mensajes_zona_inicial_listener.dart';
import 'teclado/atajos_teclado_zona_inicial.dart';
import 'widgets/boton_inicio.dart';
import 'widgets/instruccion_zona_inicial.dart';
import 'widgets/puntuaciones_disponibles_widget.dart';
import 'widgets/selector_numeros_zona_inicial.dart';
import 'widgets/tablero_widget.dart';

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key, this.mapa = MapaTablero.mapa1});

  final MapaTablero mapa;

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  final TableroJuego tablero = TableroJuego();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<JuegoBloc>(create: (_) => JuegoBloc(mapa: widget.mapa)),
        BlocProvider<ZonaInicialCubit>(
          create: (_) => ZonaInicialCubit(mapa: widget.mapa),
        ),
      ],
      child: AtajosTecladoZonaInicial(
        child: MensajesZonaInicialListener(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              title: const Text(
                'Brilliant',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: BlocBuilder<JuegoBloc, JuegoState>(
                    builder: (context, state) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withAlpha(230),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.amber.shade400,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber.shade700,
                              size: 26,
                            ),
                            const SizedBox(width: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                              child: Text(
                                '${state.puntuacionTotal}',
                                key: ValueKey<int>(state.puntuacionTotal),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            children: [
                              const InstruccionZonaInicial(),
                              const SizedBox(height: 16),
                              _TableroConPuntuaciones(
                                mapa: widget.mapa,
                                altoDisponible: constraints.maxHeight - 100,
                                enVertical: constraints.maxWidth < 600,
                              ),
                              const SizedBox(height: 24),
                              _PanelPartida(tablero: tablero, compacto: true),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const InstruccionZonaInicial(),
                                  const SizedBox(height: 16),
                                  _TableroConPuntuaciones(
                                    mapa: widget.mapa,
                                    altoDisponible: constraints.maxHeight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(child: _PanelPartida(tablero: tablero)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableroConPuntuaciones extends StatelessWidget {
  const _TableroConPuntuaciones({
    required this.mapa,
    required this.altoDisponible,
    this.enVertical = false,
  });

  final MapaTablero mapa;
  final double altoDisponible;
  final bool enVertical;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (enVertical) {
          final ladoTablero = constraints.maxWidth
              .clamp(1.0, (altoDisponible * 0.72).clamp(120.0, 560.0))
              .toDouble();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: ladoTablero,
                child: TableroWidget(mapa: mapa),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: constraints.maxWidth,
                child: PuntuacionesDisponiblesWidget(
                  mapa: mapa,
                  horizontal: true,
                ),
              ),
            ],
          );
        }

        const espacioEntre = 8.0;
        final anchoPanel = (constraints.maxWidth * 0.4)
            .clamp(120.0, 220.0)
            .toDouble();
        final anchoTablero = constraints.maxWidth - anchoPanel - espacioEntre;
        final maximoPorAlto = (altoDisponible * 0.9).clamp(120.0, 720.0);
        final ladoTablero = anchoTablero.clamp(1.0, maximoPorAlto);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: ladoTablero,
              child: TableroWidget(mapa: mapa),
            ),
            const SizedBox(width: espacioEntre),
            SizedBox(
              width: anchoPanel,
              child: PuntuacionesDisponiblesWidget(mapa: mapa),
            ),
          ],
        );
      },
    );
  }
}

class _PanelPartida extends StatelessWidget {
  const _PanelPartida({required this.tablero, this.compacto = false});

  final TableroJuego tablero;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Registro de Partida',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          if (compacto)
            const HistorialPartidaWidget()
          else
            const Expanded(child: HistorialPartidaWidget()),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),
          BlocBuilder<JuegoBloc, JuegoState>(
            builder: (context, juegoState) {
              if (juegoState.fase == FaseTurno.inicio) {
                return Column(
                  children: [
                    const SelectorNumerosZonaInicial(),
                    const SizedBox(height: 20),
                    BotonInicio(tablero: tablero),
                  ],
                );
              }
              return const PanelDados();
            },
          ),
        ],
      ),
    );
  }
}

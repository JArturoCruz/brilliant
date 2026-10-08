import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/presentacion/widgets/panel_datos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/zona_inicial_cubit.dart';
import 'dominio/tablero.dart';
import 'presentacion/mensajes/mensajes_zona_inicial_listener.dart';
import 'presentacion/teclado/atajos_teclado_zona_inicial.dart';
import 'presentacion/widgets/boton_inicio.dart';
import 'presentacion/widgets/instruccion_zona_inicial.dart';
import 'presentacion/widgets/selector_numeros_zona_inicial.dart';
import 'presentacion/widgets/tablero_widget.dart';

void main() {
  runApp(const BrilliantApp());
}

class BrilliantApp extends StatelessWidget {
  const BrilliantApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Proveemos ambos Blocs de forma global para que la pantalla y los widgets compartan estado
    return MultiBlocProvider(
      providers: [
        BlocProvider<JuegoBloc>(create: (context) => JuegoBloc()),
        BlocProvider<ZonaInicialCubit>(create: (context) => ZonaInicialCubit()),
      ],
      child: MaterialApp(
        title: 'Brilliant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const PantallaConfiguracionInicial(),
      ),
    );
  }
}

class PantallaConfiguracionInicial extends StatefulWidget {
  const PantallaConfiguracionInicial({super.key});

  @override
  State<PantallaConfiguracionInicial> createState() =>
      _PantallaConfiguracionInicialState();
}

class _PantallaConfiguracionInicialState
    extends State<PantallaConfiguracionInicial> {
  final TableroJuego tablero = TableroJuego();

  @override
  Widget build(BuildContext context) {
    return AtajosTecladoZonaInicial(
      child: MensajesZonaInicialListener(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Brilliant',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              // 🌟 Puntuación dentro de la estrella integrada en el AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: BlocBuilder<JuegoBloc, JuegoState>(
                  builder: (context, state) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50.withAlpha(230),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.amber.shade400, width: 2),
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
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(scale: animation, child: child);
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const InstruccionZonaInicial(),
                      const SizedBox(height: 16),
                      const TableroWidget(),
                      const SizedBox(height: 20),
                      
                      // Intercambia dinámicamente entre la configuración inicial y el panel de dados del juego
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
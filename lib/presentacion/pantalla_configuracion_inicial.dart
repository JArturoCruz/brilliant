import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/zona_inicial_cubit.dart';
import '../dominio/tablero.dart';
import 'mensajes/mensajes_zona_inicial_listener.dart';
import 'teclado/atajos_teclado_zona_inicial.dart';
import 'widgets/boton_inicio.dart';
import 'widgets/instruccion_zona_inicial.dart';
import 'widgets/selector_numeros_zona_inicial.dart';
import 'widgets/tablero_widget.dart';

/// Pantalla de configuración inicial. Su única responsabilidad es componer
/// el layout a partir de widgets ya resueltos en otro lado (instrucción,
/// tablero, selector, botón) y proveer el Cubit local que todos comparten.
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
    return BlocProvider(
      create: (_) => ZonaInicialCubit(),
      child: AtajosTecladoZonaInicial(
        child: MensajesZonaInicialListener(
          child: Scaffold(
            appBar: AppBar(title: const Text('Brilliant')),
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
                        const SelectorNumerosZonaInicial(),
                        const SizedBox(height: 20),
                        BotonInicio(tablero: tablero),
                      ],
                    ),
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

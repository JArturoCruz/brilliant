import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PanelDados extends StatelessWidget {
  const PanelDados({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, state) {
        if (state.dado1 == null || state.dado2 == null) return const SizedBox.shrink();

        String mensaje = '';
        if (state.fase == FaseTurno.seleccionandoAncla) {
          mensaje = 'Elige qué dado será tu ancla:';
        } else if (state.fase == FaseTurno.seleccionandoCasilla) {
          mensaje = 'Toca una casilla amarilla o cambia de dado.';
        } else if (state.fase == FaseTurno.colocandoNumero) {
          mensaje = 'Coloca el número verde.';
        } else if (state.fase == FaseTurno.confirmandoJugada) {
          mensaje = '¿Confirmas colocar el ${state.numeroColocar}?';
        } else if (state.fase == FaseTurno.turnoTerminado) {
          mensaje = '¡Turno terminado!';
        }

        bool permitirCambioDado = state.fase == FaseTurno.seleccionandoAncla || 
                                 state.fase == FaseTurno.seleccionandoCasilla || 
                                 state.fase == FaseTurno.colocandoNumero;

        return Column(
          children: [
            Text(
              mensaje,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BotonDado(
                  valor: state.dado1!,
                  esAncla: state.indiceDadoAncla == 1,
                  esColocar: state.indiceDadoAncla == 2,
                  onTap: permitirCambioDado
                      ? () => context.read<JuegoBloc>().add(SeleccionarNumeroAncla(
                            numeroElegido: state.dado1!,
                            numeroParaColocar: state.dado2!,
                            indiceDado: 1,
                          ))
                      : null,
                ),
                const SizedBox(width: 32),
                _BotonDado(
                  valor: state.dado2!,
                  esAncla: state.indiceDadoAncla == 2,
                  esColocar: state.indiceDadoAncla == 1,
                  onTap: permitirCambioDado
                      ? () => context.read<JuegoBloc>().add(SeleccionarNumeroAncla(
                            numeroElegido: state.dado2!,
                            numeroParaColocar: state.dado1!,
                            indiceDado: 2,
                          ))
                      : null,
                ),
              ],
            ),
            if (state.fase == FaseTurno.confirmandoJugada) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => context.read<JuegoBloc>().add(CancelarConfirmacion()),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () => context.read<JuegoBloc>().add(ConfirmarJugada()),
                    child: const Text('Confirmar Jugada'),
                  ),
                ],
              ),
            ],
            if (state.fase == FaseTurno.turnoTerminado) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.read<JuegoBloc>().add(IniciarTurno(const {})),
                child: const Text('Siguiente Turno'),
              ),
            ]
          ],
        );
      },
    );
  }
}

class _BotonDado extends StatelessWidget {
  final int valor;
  final bool esAncla;
  final bool esColocar;
  final VoidCallback? onTap;

  const _BotonDado({
    required this.valor,
    this.esAncla = false,
    this.esColocar = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color colorFondo = Colors.deepPurple.shade50;
    Color colorBorde = Colors.deepPurple;
    Color colorTexto = Colors.deepPurple;
    
    if (esAncla) {
      colorFondo = Colors.yellow.shade100;
      colorBorde = Colors.orange;
      colorTexto = Colors.orange.shade800;
    } else if (esColocar) {
      colorFondo = Colors.green.shade100;
      colorBorde = Colors.green.shade700;
      colorTexto = Colors.green.shade800;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorde, width: (esAncla || esColocar) ? 4 : 2),
        ),
        alignment: Alignment.center,
        child: Text(
          valor.toString(),
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorTexto),
        ),
      ),
    );
  }
}
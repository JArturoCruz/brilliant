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
        // 1. Fase: El usuario debe tocar uno de los dados para hacerlo su ancla
        if (state.fase == FaseTurno.seleccionandoAncla) {
          return Column(
            children: [
              const Text(
                'Elige qué dado será tu ancla:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BotonDado(
                    valor: state.dado1!,
                    onTap: () => context.read<JuegoBloc>().add(
                          SeleccionarNumeroAncla(
                            numeroElegido: state.dado1!,
                            numeroParaColocar: state.dado2!,
                          ),
                        ),
                  ),
                  const SizedBox(width: 32),
                  _BotonDado(
                    valor: state.dado2!,
                    onTap: () => context.read<JuegoBloc>().add(
                          SeleccionarNumeroAncla(
                            numeroElegido: state.dado2!,
                            numeroParaColocar: state.dado1!,
                          ),
                        ),
                  ),
                ],
              ),
            ],
          );
        }

        // 2. Fase: El usuario debe tocar una casilla en el tablero
        if (state.fase == FaseTurno.seleccionandoCasilla) {
          return Text(
            'Ancla: ${state.numeroAncla}. Toca una casilla en el tablero con ese número.',
            style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          );
        }

        // 3. Fase: El usuario debe colocar el otro número en las celdas adyacentes iluminadas
        if (state.fase == FaseTurno.colocandoNumero) {
          return Text(
            'Coloca el número ${state.numeroColocar} en una casilla iluminada.',
            style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          );
        }

        // Si el juego no ha iniciado, no mostramos nada aquí
        return const SizedBox.shrink();
      },
    );
  }
}

// Widget privado para dibujar el dado clickeable
class _BotonDado extends StatelessWidget {
  final int valor;
  final VoidCallback onTap;

  const _BotonDado({required this.valor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          valor.toString(),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
      ),
    );
  }
}
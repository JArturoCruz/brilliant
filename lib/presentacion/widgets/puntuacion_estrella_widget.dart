import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


/// Widget que muestra la puntuación total actual dentro de un contenedor en forma de estrella
/// con un diseño limpio, moderno y animado.
class PuntuacionEstrellaWidget extends StatelessWidget {
  const PuntuacionEstrellaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // Icono de estrella con un toque dorado brillante
              Icon(
                Icons.star_rounded,
                color: Colors.amber.shade700,
                size: 28,
              ),
              const SizedBox(width: 8),
              // Animación sutil al cambiar la puntuación
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  '${state.puntuacionTotal}',
                  // Usamos la puntuación como Key para disparar la animación al cambiar
                  key: ValueKey<int>(state.puntuacionTotal),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
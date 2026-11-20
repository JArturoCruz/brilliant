import 'dart:async';

import 'package:flutter/material.dart';

import '../../datos/audio_juego.dart';

class BotonAudio extends StatelessWidget {
  const BotonAudio({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = AudioJuego.instancia;
    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) => IconButton(
        key: const Key('game-audio-toggle'),
        tooltip:
            audio.error ??
            (audio.habilitado ? 'Silenciar sonidos' : 'Activar sonidos'),
        onPressed: () => unawaited(
          audio.error != null ? audio.reintentar() : audio.alternar(),
        ),
        icon: Icon(
          audio.error != null
              ? Icons.volume_mute_rounded
              : audio.habilitado
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          color: audio.error != null
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
    );
  }
}

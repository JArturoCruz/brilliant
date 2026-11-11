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
        tooltip: audio.habilitado ? 'Silenciar sonidos' : 'Activar sonidos',
        onPressed: () => unawaited(audio.alternar()),
        icon: Icon(
          audio.habilitado ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        ),
      ),
    );
  }
}

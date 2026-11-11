import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SonidoJuego { dados, ancla, numero, zonaCompleta, victoria }

class AudioJuego extends ChangeNotifier {
  AudioJuego._();

  static final AudioJuego instancia = AudioJuego._();

  final AudioPlayer _musica = AudioPlayer();
  final Map<SonidoJuego, AudioPlayer> _efectos = {
    for (final sonido in SonidoJuego.values) sonido: AudioPlayer(),
  };

  bool _habilitado = true;
  bool _musicaIniciada = false;

  bool get habilitado => _habilitado;

  Future<void> alternar() async {
    _habilitado = !_habilitado;
    notifyListeners();
    if (_habilitado) {
      await _iniciarMusica();
    } else {
      await _detenerAudio();
    }
  }

  Future<void> reproducir(SonidoJuego sonido) async {
    if (!_habilitado) return;
    await _iniciarMusica();
    final reproductor = _efectos[sonido]!;
    await _operacionAudio('efecto ${sonido.name}', () async {
      await reproductor.stop();
      await reproductor.play(AssetSource(_rutaEfecto(sonido)));
    });
  }

  Future<void> detenerMusica() async {
    if (!_musicaIniciada) return;
    await _operacionAudio('música ambiental', _musica.stop);
    _musicaIniciada = false;
  }

  Future<void> _iniciarMusica() async {
    if (!_habilitado || _musicaIniciada) return;
    await _operacionAudio('música ambiental', () async {
      await _musica.setReleaseMode(ReleaseMode.loop);
      await _musica.play(AssetSource('audio/ambient.wav'));
      _musicaIniciada = true;
    });
  }

  Future<void> _detenerAudio() async {
    await detenerMusica();
    for (final reproductor in _efectos.values) {
      await _operacionAudio('efecto de juego', reproductor.stop);
    }
  }

  Future<void> _operacionAudio(
    String nombre,
    Future<void> Function() operacion,
  ) async {
    try {
      await operacion();
    } catch (error, stackTrace) {
      debugPrint('No se pudo reproducir $nombre: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _rutaEfecto(SonidoJuego sonido) => switch (sonido) {
    SonidoJuego.dados => 'audio/dice.wav',
    SonidoJuego.ancla => 'audio/anchor.wav',
    SonidoJuego.numero => 'audio/place.wav',
    SonidoJuego.zonaCompleta => 'audio/complete.wav',
    SonidoJuego.victoria => 'audio/victory.wav',
  };
}

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SonidoJuego { dados, ancla, numero, zonaCompleta, zonaRival, victoria }

class AudioJuego extends ChangeNotifier {
  AudioJuego._()
    : _efectos = {
        for (final sonido in SonidoJuego.values) sonido: AudioPlayer(),
      };

  @visibleForTesting
  AudioJuego.paraPruebas(this._efectos);

  static final AudioJuego instancia = AudioJuego._();

  final Map<SonidoJuego, AudioPlayer> _efectos;

  bool _habilitado = true;
  Future<void> _colaAvisos = Future.value();
  final Map<SonidoJuego, Future<void>> _colasEfectos = {};
  final Map<SonidoJuego, Completer<void>> _efectosActuales = {};
  int _versionAudio = 0;
  String? _error;

  bool get habilitado => _habilitado;
  String? get error => _error;

  Future<void> alternar() async {
    _habilitado = !_habilitado;
    _error = null;
    if (!_habilitado) _versionAudio++;
    notifyListeners();
    if (!_habilitado) await _detenerAudio();
  }

  Future<void> reproducir(SonidoJuego sonido) async {
    if (!_habilitado) return;
    final esAviso =
        sonido == SonidoJuego.zonaCompleta ||
        sonido == SonidoJuego.zonaRival ||
        sonido == SonidoJuego.victoria;
    final anterior = esAviso
        ? _colaAvisos
        : _colasEfectos[sonido] ?? Future<void>.value();
    final version = _versionAudio;
    final reproduccion = anterior.then((_) async {
      if (!_habilitado || version != _versionAudio) return;
      await _reproducirEfecto(sonido);
    });
    if (esAviso) {
      _colaAvisos = reproduccion;
    } else {
      _colasEfectos[sonido] = reproduccion;
    }
    await reproduccion;
  }

  Future<void> _reproducirEfecto(SonidoJuego sonido) async {
    final reproductor = _efectos[sonido]!;
    final version = _versionAudio;
    await _operacionAudio('efecto ${sonido.name}', () async {
      final finalizado = Completer<void>();
      _efectosActuales[sonido] = finalizado;
      final suscripcion = reproductor.onPlayerComplete.listen((_) {
        if (!finalizado.isCompleted) finalizado.complete();
      });
      try {
        await reproductor.stop();
        if (!_habilitado || version != _versionAudio) return;
        await reproductor.play(AssetSource(_rutaEfecto(sonido)));
        if (!_habilitado || version != _versionAudio) {
          await reproductor.stop();
          return;
        }
        await finalizado.future.timeout(const Duration(seconds: 8));
      } finally {
        if (identical(_efectosActuales[sonido], finalizado)) {
          _efectosActuales.remove(sonido);
        }
        await suscripcion.cancel();
      }
    });
  }

  Future<void> reintentar() async {
    _habilitado = true;
    _error = null;
    notifyListeners();
    await reproducir(SonidoJuego.ancla);
  }

  Future<void> _detenerAudio() async {
    for (final efecto in _efectosActuales.values) {
      if (!efecto.isCompleted) efecto.complete();
    }
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
      _error = 'No se pudo reproducir el audio. Toca para reintentar.';
      notifyListeners();
    }
  }

  String _rutaEfecto(SonidoJuego sonido) => switch (sonido) {
    SonidoJuego.dados => 'audio/dice.mp3',
    SonidoJuego.ancla => 'audio/anchor.wav',
    SonidoJuego.numero => 'audio/place.wav',
    SonidoJuego.zonaCompleta => 'audio/complete.wav',
    SonidoJuego.zonaRival => 'audio/rival_complete.wav',
    SonidoJuego.victoria => 'audio/victory.wav',
  };
}

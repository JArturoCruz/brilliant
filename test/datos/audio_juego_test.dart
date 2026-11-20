import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:brilliant/datos/audio_juego.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReproductorFalso implements AudioPlayer {
  _ReproductorFalso(this.reproducciones);

  final List<String> reproducciones;
  final completados = StreamController<void>.broadcast(sync: true);
  int fallosPendientes = 0;

  @override
  Stream<void> get onPlayerComplete => completados.stream;

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (source is AssetSource) reproducciones.add(source.path);
    if (fallosPendientes > 0) {
      fallosPendientes--;
      throw StateError('Error de prueba');
    }
  }

  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'reproduce avisos consecutivos sin cortar los sonidos anteriores',
    () async {
      final reproducciones = <String>[];
      final efectos = {
        for (final sonido in SonidoJuego.values)
          sonido: _ReproductorFalso(reproducciones),
      };
      final audio = AudioJuego.paraPruebas(efectos);
      final primero = audio.reproducir(SonidoJuego.zonaRival);
      final segundo = audio.reproducir(SonidoJuego.zonaRival);
      final tercero = audio.reproducir(SonidoJuego.zonaCompleta);
      await Future<void>.delayed(Duration.zero);
      expect(reproducciones, ['audio/rival_complete.wav']);

      efectos[SonidoJuego.zonaRival]!.completados.add(null);
      await primero;
      await Future<void>.delayed(Duration.zero);
      expect(reproducciones, [
        'audio/rival_complete.wav',
        'audio/rival_complete.wav',
      ]);

      efectos[SonidoJuego.zonaRival]!.completados.add(null);
      await segundo;
      await Future<void>.delayed(Duration.zero);
      expect(reproducciones.last, 'audio/complete.wav');
      efectos[SonidoJuego.zonaCompleta]!.completados.add(null);
      await tercero;
      audio.dispose();
      for (final reproductor in efectos.values) {
        await reproductor.completados.close();
      }
    },
  );

  test(
    'silenciar cancela los avisos pendientes sin reproducirlos después',
    () async {
      final reproducciones = <String>[];
      final efectos = {
        for (final sonido in SonidoJuego.values)
          sonido: _ReproductorFalso(reproducciones),
      };
      final audio = AudioJuego.paraPruebas(efectos);
      final primero = audio.reproducir(SonidoJuego.zonaRival);
      final segundo = audio.reproducir(SonidoJuego.zonaCompleta);
      await Future<void>.delayed(Duration.zero);
      await audio.alternar();
      await primero;
      await segundo;
      expect(
        reproducciones.where((path) => path == 'audio/complete.wav'),
        isEmpty,
      );
      await audio.alternar();
      expect(reproducciones, ['audio/rival_complete.wav']);
      audio.dispose();
      for (final reproductor in efectos.values) {
        await reproductor.completados.close();
      }
    },
  );

  test(
    'los efectos repetidos no se cortan y continúan tras un fallo',
    () async {
      final reproducciones = <String>[];
      final efectos = {
        for (final sonido in SonidoJuego.values)
          sonido: _ReproductorFalso(reproducciones),
      };
      final audio = AudioJuego.paraPruebas(efectos);
      efectos[SonidoJuego.numero]!.fallosPendientes = 1;
      final primero = audio.reproducir(SonidoJuego.numero);
      final segundo = audio.reproducir(SonidoJuego.numero);
      await primero;
      await Future<void>.delayed(Duration.zero);
      expect(audio.error, isNotNull);
      expect(
        reproducciones.where((path) => path == 'audio/place.wav').length,
        2,
      );
      efectos[SonidoJuego.numero]!.completados.add(null);
      await segundo;
      audio.dispose();
      for (final reproductor in efectos.values) {
        await reproductor.completados.close();
      }
    },
  );
}

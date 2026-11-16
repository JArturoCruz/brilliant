import '../../datos/multijugador/multiplayer_client.dart';

bool debeSonarZonaRival(Iterable<RoomEvent> eventos, String jugadorId) {
  final zonaRival = eventos.any((evento) => evento.playerId != jugadorId);
  // Servidores anteriores no incluyen puntos; una zona propia evita el sonido.
  final puntuoJugador = eventos.any(
    (evento) => evento.playerId == jugadorId && evento.points != 0,
  );
  return zonaRival && !puntuoJugador;
}

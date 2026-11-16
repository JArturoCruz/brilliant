import 'package:brilliant/datos/multijugador/multiplayer_client.dart';
import 'package:brilliant/presentacion/multijugador/sonido_zona_rival.dart';
import 'package:flutter_test/flutter_test.dart';

RoomEvent evento(String jugador, String region, int? puntos) => RoomEvent(
  id: '$jugador-$region',
  message: '',
  playerId: jugador,
  region: region,
  round: 1,
  points: puntos,
);

void main() {
  test('suena solo para quienes no puntuaron en la ronda', () {
    final eventos = [evento('uno', 'azul1', 8), evento('dos', 'amarilla', 6)];
    expect(debeSonarZonaRival(eventos, 'uno'), isFalse);
    expect(debeSonarZonaRival(eventos, 'dos'), isFalse);
    expect(debeSonarZonaRival(eventos, 'tres'), isTrue);
  });

  test('compartir la misma zona no produce sonido triste', () {
    final eventos = [evento('uno', 'azul1', 8), evento('dos', 'azul1', 8)];
    expect(debeSonarZonaRival(eventos, 'uno'), isFalse);
    expect(debeSonarZonaRival(eventos, 'dos'), isFalse);
    expect(debeSonarZonaRival(eventos, 'tres'), isTrue);
  });

  test('una zona sin puntos no evita el sonido de una zona rival', () {
    final eventos = [evento('uno', 'azul1', 0), evento('dos', 'amarilla', 6)];
    expect(debeSonarZonaRival(eventos, 'uno'), isTrue);
    expect(debeSonarZonaRival(eventos, 'dos'), isFalse);
    expect(debeSonarZonaRival([eventos.first], 'uno'), isFalse);
    expect(debeSonarZonaRival([], 'uno'), isFalse);
  });

  test('mantiene compatibilidad con eventos sin campo de puntos', () {
    final anterior = RoomEvent.fromJson({
      'id': 'anterior',
      'message': 'Zona completada',
      'playerId': 'uno',
      'region': 'azul1',
      'round': 1,
    });
    final actual = RoomEvent.fromJson({
      'id': 'actual',
      'message': 'Zona completada',
      'playerId': 'dos',
      'region': 'amarilla',
      'round': 1,
      'points': 6,
    });
    expect(actual.points, 6);
    expect(debeSonarZonaRival([anterior, actual], 'uno'), isFalse);
  });
}

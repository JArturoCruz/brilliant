import 'dart:convert';

import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/datos/multijugador/multiplayer_client.dart';
import 'package:brilliant/presentacion/pantalla_multijugador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryTokenStore implements AuthTokenStore {
  @override
  Future<String?> read() async => 'session-token';

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

void main() {
  const user = AuthUser(
    id: 'player-1',
    name: 'Jugador Uno',
    email: 'one@example.com',
  );

  Map<String, dynamic> roomJson({int players = 1}) => {
    'code': 'ABC234',
    'mapId': 1,
    'phase': 'waiting',
    'hostId': 'player-1',
    'players': List.generate(players, (index) {
      final id = 'player-${index + 1}';
      return {
        'id': id,
        'name': index == 0 ? 'Jugador Uno' : 'Jugador Dos',
        'isHost': index == 0,
        'connected': true,
        'score': 0,
        'forfeited': false,
        'isWinner': false,
      };
    }),
    'board': List.generate(7, (_) => List<int?>.filled(7, null)),
    'dice': null,
    'turnPlayerId': null,
    'scoreToWin': 0,
    'revision': 1,
    'winners': <String>[],
    'finishReason': null,
    'events': [
      {
        'id': 'event-1',
        'message': 'Jugador Uno creó la sala.',
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
    ],
  };

  Map<String, dynamic> lobbyJson() => {
    'activePlayers': [
      {'id': 'player-1', 'name': 'Jugador Uno'},
      {'id': 'player-2', 'name': 'Jugador Dos'},
    ],
    'rooms': <Object>[],
  };

  MultiplayerClient clientWith(
    Future<http.Response> Function(http.Request) handler,
  ) => MultiplayerClient(
    authClient: AuthClient(
      baseUrl: 'http://localhost:3000',
      tokenStore: _MemoryTokenStore(),
      httpClient: MockClient(handler),
    ),
  );

  testWidgets('creates a room from the authenticated lobby', (tester) async {
    final requests = <String>[];
    final client = clientWith((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/lobby')) {
        return http.Response(jsonEncode(lobbyJson()), 200);
      }
      if (request.url.path.endsWith('/rooms')) {
        expect(jsonDecode(request.body), {'mapId': 1});
        return http.Response(jsonEncode(roomJson()), 201);
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaMultijugador(user: user, client: client),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jugadores activos (2)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-multiplayer-room')));
    await tester.pumpAndSettle();

    expect(find.text('Sala ABC234'), findsOneWidget);
    expect(
      find.textContaining('Comparte el código para invitar'),
      findsOneWidget,
    );
    expect(requests, contains('POST /api/multiplayer/rooms'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('joins a room with an invitation code and shows its players', (
    tester,
  ) async {
    final requests = <String>[];
    final client = clientWith((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/lobby')) {
        return http.Response(jsonEncode(lobbyJson()), 200);
      }
      if (request.url.path.endsWith('/join')) {
        expect(request.url.path, endsWith('/rooms/ABC234/join'));
        return http.Response(jsonEncode(roomJson(players: 2)), 200);
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaMultijugador(user: user, client: client),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('invite-code-input')),
      'abc234',
    );
    await tester.tap(find.byKey(const Key('join-room-by-code')));
    await tester.pumpAndSettle();

    expect(find.text('Sala ABC234'), findsOneWidget);
    expect(find.textContaining('Jugador Dos'), findsOneWidget);
    expect(find.byKey(const Key('start-multiplayer-game')), findsOneWidget);
    expect(requests, contains('POST /api/multiplayer/rooms/ABC234/join'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows connection loss and recovers on retry', (tester) async {
    var failedOnce = false;
    final client = clientWith((request) async {
      if (!failedOnce) {
        failedOnce = true;
        throw http.ClientException('offline');
      }
      return http.Response(jsonEncode(lobbyJson()), 200);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaMultijugador(user: user, client: client),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Conexión interrumpida'), findsOneWidget);

    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();

    expect(find.text('Jugadores activos (2)'), findsOneWidget);
    expect(find.textContaining('Conexión interrumpida'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

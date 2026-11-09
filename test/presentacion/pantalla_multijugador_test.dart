import 'dart:convert';

import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/datos/multijugador/multiplayer_client.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/pantalla_multijugador.dart';
import 'package:brilliant/presentacion/widgets/selector_numeros_zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  Map<String, dynamic> roomJson({
    int players = 1,
    String phase = 'waiting',
    int revision = 1,
    List<List<int?>>? board,
    List<int>? dice,
    String? turnPlayerId,
    bool ready = false,
  }) => {
    'code': 'ABC234',
    'mapId': 1,
    'phase': phase,
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
        'ready': ready,
      };
    }),
    'board': board ?? List.generate(7, (_) => List<int?>.filled(7, null)),
    'dice': dice,
    'turnPlayerId': turnPlayerId,
    'scoreToWin': 0,
    'revision': revision,
    'winners': <String>[],
    'finishReason': null,
    'events': [
      {
        'id': 'event-1',
        'message': 'Jugador Uno creó la sala.',
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
    ],
    'regionCounters': <String, int>{},
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

  testWidgets(
    'uses the original board and submits setup and moves to the server',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var latestRoom = roomJson(players: 2, phase: 'setup', revision: 2);
      final client = clientWith((request) async {
        if (request.url.path.endsWith('/lobby')) {
          return http.Response(jsonEncode(lobbyJson()), 200);
        }
        if (request.method == 'POST' && request.url.path.endsWith('/rooms')) {
          return http.Response(jsonEncode(roomJson(players: 2)), 201);
        }
        if (request.url.path.endsWith('/start')) {
          latestRoom = roomJson(players: 2, phase: 'setup', revision: 2);
          return http.Response(jsonEncode(latestRoom), 200);
        }
        if (request.url.path.endsWith('/ABC234')) {
          return http.Response(jsonEncode(latestRoom), 200);
        }
        if (request.url.path.endsWith('/setup')) {
          expect(jsonDecode(request.body), {
            'values': [1, 2, 3, 4, 5, 6],
          });
          final board = List.generate(7, (_) => List<int?>.filled(7, null));
          for (var index = 0; index < ZonaInicial.posiciones.length; index++) {
            final position = ZonaInicial.posiciones[index];
            board[position.fila][position.columna] = index + 1;
          }
          latestRoom = roomJson(
            players: 2,
            phase: 'playing',
            revision: 3,
            board: board,
            dice: [2, 3],
            turnPlayerId: user.id,
            ready: true,
          );
          return http.Response(jsonEncode(latestRoom), 200);
        }
        if (request.url.path.endsWith('/move')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['revision'], 3);
          expect(body['anchorDieIndex'], 0);
          expect(body['anchor'], {'row': 3, 'column': 1});
          expect(body['destination'], {'row': 2, 'column': 1});
          final board = List.generate(7, (_) => List<int?>.filled(7, null));
          for (var index = 0; index < ZonaInicial.posiciones.length; index++) {
            final position = ZonaInicial.posiciones[index];
            board[position.fila][position.columna] = index + 1;
          }
          board[2][1] = 3;
          latestRoom = roomJson(
            players: 2,
            phase: 'playing',
            revision: 4,
            board: board,
            dice: [2, 3],
            turnPlayerId: 'player-2',
            ready: true,
          );
          return http.Response(jsonEncode(latestRoom), 200);
        }
        return http.Response('{}', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: PantallaMultijugador(user: user, client: client),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-multiplayer-room')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-multiplayer-game')));
      await tester.pumpAndSettle();

      expect(find.text('Brilliant · ABC234'), findsOneWidget);
      expect(find.byType(TableroWidget), findsOneWidget);
      expect(find.byType(SelectorNumerosZonaInicial), findsOneWidget);
      final gameContext = tester.element(find.byType(TableroWidget));
      final cubit = gameContext.read<ZonaInicialCubit>();
      final gameBloc = gameContext.read<JuegoBloc>();
      for (var index = 0; index < ZonaInicial.posiciones.length; index++) {
        cubit.asignarASeleccionada(index + 1);
      }
      await tester.pumpAndSettle();
      expect(cubit.state.esValida, isTrue);
      expect(cubit.state.iniciada, isFalse);
      expect(find.text('Inicio'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Inicio'))
            .onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.text('Inicio'));
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      expect(find.text('Es tu turno'), findsOneWidget);
      expect(find.byKey(const ValueKey('dado-1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dado-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('game-cell-3-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('game-cell-2-1')));
      await tester.pumpAndSettle();
      expect(gameBloc.state.fase, FaseTurno.confirmandoJugada);
      expect(find.text('¿Confirmas colocar el 3?'), findsOneWidget);
      await tester.tap(find.text('Confirmar Jugada'));
      await tester.pumpAndSettle();
      expect(find.text('Turno de Jugador Dos'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

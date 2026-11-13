import 'dart:convert';

import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/datos/multijugador/multiplayer_client.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/zona_inicial.dart';
import 'package:brilliant/presentacion/pantalla_multijugador.dart';
import 'package:brilliant/presentacion/seleccion_mapa/widgets/vista_previa_mapa.dart';
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
    int round = 1,
    bool currentPlayerForfeited = false,
    Set<String> forfeitedIds = const {},
    List<List<int?>>? board,
    List<int>? dice,
    String? playedPlayerId,
    Map<String, int>? regionCounters,
    bool ready = false,
    List<int> scores = const [],
    List<String> winners = const [],
    String? finishReason,
    Map<String, List<List<int?>>> playerBoards = const {},
    List<Map<String, dynamic>>? events,
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
        'score': index < scores.length ? scores[index] : 0,
        'forfeited':
            (index == 0 && currentPlayerForfeited) || forfeitedIds.contains(id),
        'isWinner': winners.contains(id),
        'ready': ready,
        'playedThisRound': id == playedPlayerId,
        'board': playerBoards[id],
      };
    }),
    'board': board ?? List.generate(7, (_) => List<int?>.filled(7, null)),
    'dice': dice,
    'round': round,
    'scoreToWin': 0,
    'revision': revision,
    'winners': winners,
    'finishReason': finishReason,
    'events':
        events ??
        [
          {
            'id': 'event-1',
            'message': 'Jugador Uno creó la sala.',
            'createdAt': '2026-01-01T00:00:00.000Z',
          },
        ],
    'regionCounters': regionCounters ?? <String, int>{},
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

  testWidgets('updates the map preview when selecting a map', (tester) async {
    final client = clientWith((request) async {
      if (request.url.path.endsWith('/lobby')) {
        return http.Response(jsonEncode(lobbyJson()), 200);
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaMultijugador(user: user, client: client),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<VistaPreviaMapa>(find.byType(VistaPreviaMapa)).mapa,
      MapaTablero.mapa1,
    );

    await tester.tap(find.byKey(const Key('multiplayer-map-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa 3').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<VistaPreviaMapa>(find.byType(VistaPreviaMapa)).mapa,
      MapaTablero.mapa3,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

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

  testWidgets(
    'returns to the lobby with a notice when the host dissolves the room',
    (tester) async {
      final requests = <String>[];
      final client = clientWith((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/lobby')) {
          return http.Response(jsonEncode(lobbyJson()), 200);
        }
        if (request.url.path.endsWith('/join')) {
          return http.Response(jsonEncode(roomJson(players: 2)), 200);
        }
        if (request.url.path.endsWith('/ABC234')) {
          return http.Response(
            jsonEncode({
              'code': 'ROOM_DISSOLVED',
              'message': 'El anfitrión abandonó la sala.',
            }),
            410,
          );
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
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Lobby'), findsOneWidget);
      expect(
        find.text('El anfitrión abandonó la sala. Serás redirigido al lobby.'),
        findsOneWidget,
      );
      expect(requests, contains('GET /api/multiplayer/lobby'));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('returns setup players to the lobby when the host leaves', (
    tester,
  ) async {
    final client = clientWith((request) async {
      if (request.url.path.endsWith('/lobby')) {
        return http.Response(jsonEncode(lobbyJson()), 200);
      }
      if (request.url.path.endsWith('/join')) {
        return http.Response(jsonEncode(roomJson(phase: 'setup')), 200);
      }
      if (request.url.path.endsWith('/ABC234')) {
        return http.Response(
          jsonEncode({
            'code': 'ROOM_DISSOLVED',
            'message': 'El anfitrión abandonó la sala antes de iniciar.',
          }),
          410,
        );
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
    await tester.ensureVisible(find.byKey(const Key('join-room-by-code')));
    await tester.tap(find.byKey(const Key('join-room-by-code')));
    await tester.pumpAndSettle();

    expect(find.text('Lobby'), findsOneWidget);
    expect(
      find.text('El anfitrión abandonó la sala antes de iniciar.'),
      findsOneWidget,
    );
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
    expect(
      find.textContaining('Se perdió la conexión con el servidor'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('wait-for-server')), findsOneWidget);

    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();

    expect(find.text('Jugadores activos (2)'), findsOneWidget);
    expect(
      find.textContaining('Se perdió la conexión con el servidor'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('returns a player to the lobby after the server forfeits them', (
    tester,
  ) async {
    final forfeitedRoom = roomJson(
      players: 2,
      phase: 'playing',
      currentPlayerForfeited: true,
    );
    final client = clientWith((request) async {
      if (request.url.path.endsWith('/lobby')) {
        return http.Response(jsonEncode(lobbyJson()), 200);
      }
      if (request.url.path.endsWith('/join')) {
        return http.Response(jsonEncode(forfeitedRoom), 200);
      }
      if (request.url.path.endsWith('/ABC234')) {
        return http.Response(jsonEncode(forfeitedRoom), 200);
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
    await tester.ensureVisible(find.byKey(const Key('join-room-by-code')));
    await tester.tap(find.byKey(const Key('join-room-by-code')));
    await tester.pumpAndSettle();

    expect(find.text('Lobby'), findsOneWidget);
    expect(
      find.textContaining('Se agotó el minuto sin conexión'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('queues leaving the room while the server is unreachable', (
    tester,
  ) async {
    var online = false;
    final requests = <String>[];
    final client = clientWith((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/lobby')) {
        return http.Response(jsonEncode(lobbyJson()), 200);
      }
      if (request.method == 'POST' && request.url.path.endsWith('/rooms')) {
        return http.Response(jsonEncode(roomJson()), 201);
      }
      if (request.url.path.endsWith('/leave')) {
        if (!online) throw http.ClientException('offline');
        return http.Response(
          jsonEncode({'dissolved': false, 'message': 'Saliste de la sala.'}),
          200,
        );
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
    await tester.tap(find.byKey(const Key('leave-multiplayer-room')));
    await tester.pumpAndSettle();

    expect(find.text('Lobby'), findsOneWidget);
    expect(
      find.textContaining('salida está pendiente'),
      findsAtLeastNWidgets(1),
    );
    expect(find.byKey(const Key('multiplayer-connection-lost')), findsNothing);
    online = true;
    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();

    expect(requests.where((request) => request.endsWith('/leave')).length, 3);
    expect(find.text('Saliste de la sala.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('supports setup, moves, and reconnect on a phone-sized screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var latestRoom = roomJson(players: 2, phase: 'setup', revision: 2);
    var moveAttempts = 0;
    String? firstMoveCommandId;
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
          ready: true,
        );
        return http.Response(jsonEncode(latestRoom), 200);
      }
      if (request.url.path.endsWith('/move')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        moveAttempts++;
        if (moveAttempts == 1) {
          firstMoveCommandId = body['commandId'] as String;
          throw http.ClientException('offline');
        }
        expect(body['commandId'], firstMoveCommandId);
        expect(body['round'], 1);
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
          round: 1,
          board: board,
          dice: [2, 3],
          playedPlayerId: user.id,
          regionCounters: {'azul1': 1},
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
    expect(find.byKey(const Key('mobile-game-content')), findsOneWidget);
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
    expect(find.text('Ronda 1: dados compartidos por todos'), findsOneWidget);
    expect(find.byKey(const ValueKey('dado-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dado-1')));
    await tester.pump();
    final anchorCell = find.byKey(const Key('game-cell-3-1'));
    await tester.ensureVisible(anchorCell);
    await tester.tap(anchorCell);
    await tester.pump();
    final destinationCell = find.byKey(const Key('game-cell-2-1'));
    await tester.ensureVisible(destinationCell);
    await tester.tap(destinationCell);
    await tester.pumpAndSettle();
    expect(gameBloc.state.fase, FaseTurno.confirmandoJugada);
    expect(find.text('¿Confirmas colocar el 3?'), findsOneWidget);
    final confirmMove = find.text('Confirmar Jugada');
    await tester.ensureVisible(confirmMove);
    await tester.tap(confirmMove);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('multiplayer-connection-lost')),
      findsOneWidget,
    );
    expect(find.textContaining('Tu jugada está pendiente'), findsOneWidget);
    expect(find.byKey(const Key('wait-for-game-server')), findsOneWidget);
    expect(find.byKey(const Key('leave-game-while-offline')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(moveAttempts, 2);
    expect(
      find.text('Ronda completada (1/2). Esperando a los demás jugadores…'),
      findsOneWidget,
    );
    expect(gameBloc.state.contadorCompletadasPorRegion['azul1'], 1);
    final controlPosition = tester.getTopLeft(
      find.byKey(const Key('mobile-game-controls')),
    );
    await tester.drag(
      find.byKey(const Key('mobile-game-content')),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const Key('mobile-game-controls'))),
      controlPosition,
    );
    expect(find.text('Jugador Uno creó la sala.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows final multiplayer results and returns to the lobby', (
    tester,
  ) async {
    final requests = <String>[];
    final client = clientWith((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/lobby')) {
        return http.Response(jsonEncode(lobbyJson()), 200);
      }
      if (request.url.path.endsWith('/join')) {
        return http.Response(
          jsonEncode(roomJson(players: 2, phase: 'playing', ready: true)),
          200,
        );
      }
      if (request.method == 'GET' && request.url.path.endsWith('/ABC234')) {
        return http.Response(
          jsonEncode(
            roomJson(
              players: 2,
              phase: 'finished',
              revision: 5,
              scores: [30, 22],
              winners: ['player-1'],
              finishReason: 'score',
              playerBoards: {
                'player-1': List.generate(7, (_) => List<int?>.filled(7, 1)),
                'player-2': List.generate(7, (_) => List<int?>.filled(7, 2)),
              },
            ),
          ),
          200,
        );
      }
      if (request.method == 'POST' && request.url.path.endsWith('/leave')) {
        return http.Response(
          jsonEncode({'dissolved': false, 'message': 'Saliste de la sala.'}),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaMultijugador(user: user, client: client),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('invite-code-input')),
      'abc234',
    );
    await tester.tap(find.byKey(const Key('join-room-by-code')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byKey(const Key('multiplayer-results-dialog')), findsOneWidget);
    expect(find.text('¡Ganó Jugador Uno!'), findsOneWidget);
    expect(find.text('Puntuaciones finales'), findsOneWidget);
    expect(find.text('30 pts'), findsOneWidget);
    expect(find.text('22 pts'), findsOneWidget);
    expect(find.text('Se alcanzó la puntuación objetivo.'), findsOneWidget);
    expect(find.text('Tableros finales'), findsOneWidget);
    final previews = tester
        .widgetList<VistaPreviaMapa>(find.byType(VistaPreviaMapa))
        .toList();
    expect(
      previews.map((preview) => preview.valores?.first.first),
      containsAll([1, 2]),
    );

    await tester.tap(find.byKey(const Key('finished-return-to-lobby')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byKey(const Key('multiplayer-results-dialog')), findsNothing);
    expect(find.text('Lobby'), findsOneWidget);
    expect(requests, contains('POST /api/multiplayer/rooms/ABC234/leave'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'el último jugador gana y confirma los resultados antes de salir',
    (tester) async {
      final boards = {
        'player-1': List.generate(7, (_) => List<int?>.filled(7, 1)),
        'player-2': List.generate(7, (_) => List<int?>.filled(7, 2)),
      };
      var room = roomJson(
        players: 2,
        phase: 'playing',
        ready: true,
        dice: [1, 2],
        playerBoards: boards,
      );
      var leaveRequests = 0;
      final client = clientWith((request) async {
        if (request.url.path.endsWith('/lobby')) {
          return http.Response(jsonEncode(lobbyJson()), 200);
        }
        if (request.url.path.endsWith('/leave')) {
          leaveRequests++;
          return http.Response(jsonEncode({'dissolved': false}), 200);
        }
        if (request.url.path.endsWith('/join') ||
            request.url.path.endsWith('/ABC234')) {
          return http.Response(jsonEncode(room), 200);
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
        'ABC234',
      );
      await tester.tap(find.byKey(const Key('join-room-by-code')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('show-player-boards')));
      await tester.pumpAndSettle();

      room = roomJson(
        players: 2,
        phase: 'finished',
        revision: 2,
        ready: true,
        scores: [0, 8],
        forfeitedIds: {'player-2'},
        winners: ['player-1'],
        finishReason: 'last_player',
        playerBoards: boards,
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Tableros de jugadores'), findsNothing);
      expect(find.text('¡Ganó Jugador Uno!'), findsOneWidget);
      expect(
        find.text(
          'Los demás jugadores abandonaron o se desconectaron. El último jugador gana automáticamente.',
        ),
        findsOneWidget,
      );
      final resultDialog = find.byKey(const Key('multiplayer-results-dialog'));
      final ranking = tester
          .widgetList<ListTile>(
            find.descendant(of: resultDialog, matching: find.byType(ListTile)),
          )
          .toList();
      expect((ranking.first.title! as Text).data, 'Jugador Uno');
      expect(find.text('0 pts'), findsOneWidget);
      expect(find.text('8 pts'), findsOneWidget);
      expect(
        tester
            .widgetList<VistaPreviaMapa>(find.byType(VistaPreviaMapa))
            .map((preview) => preview.valores?.first.first),
        containsAll([1, 2]),
      );
      expect(leaveRequests, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('multiplayer-results-dialog')),
        findsOneWidget,
      );
      expect(leaveRequests, 0);

      await tester.tap(find.byKey(const Key('finished-return-to-lobby')));
      await tester.pumpAndSettle();
      expect(leaveRequests, 1);
      expect(find.text('Lobby'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'actualiza el tablero rival abierto y avisa cuando completa zona',
    (tester) async {
      final mine = List.generate(7, (_) => List<int?>.filled(7, null));
      mine[0][0] = 1;
      final rival = List.generate(7, (_) => List<int?>.filled(7, null));
      var latestRoom = roomJson(
        players: 2,
        phase: 'playing',
        ready: true,
        dice: [1, 2],
        board: mine,
        playerBoards: {'player-1': mine, 'player-2': rival},
      );
      final client = clientWith((request) async {
        if (request.url.path.endsWith('/lobby'))
          return http.Response(jsonEncode(lobbyJson()), 200);
        if (request.url.path.endsWith('/join') ||
            request.url.path.endsWith('/ABC234')) {
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
      await tester.enterText(
        find.byKey(const Key('invite-code-input')),
        'abc234',
      );
      await tester.tap(find.byKey(const Key('join-room-by-code')));
      await tester.pumpAndSettle();
      final bloc = tester.element(find.byType(TableroWidget)).read<JuegoBloc>();
      bloc.add(
        SeleccionarNumeroAncla(
          numeroElegido: 1,
          numeroParaColocar: 2,
          indiceDado: 1,
        ),
      );
      await tester.pump();
      expect(bloc.state.fase, FaseTurno.seleccionandoCasilla);
      await tester.tap(find.byKey(const Key('show-player-boards')));
      await tester.pumpAndSettle();
      expect(find.text('Jugador Dos'), findsOneWidget);
      expect(
        tester
            .widget<VistaPreviaMapa>(find.byType(VistaPreviaMapa))
            .valores![0][0],
        isNull,
      );

      final updated = List.generate(7, (_) => List<int?>.filled(7, null));
      updated[0][0] = 4;
      latestRoom = roomJson(
        players: 2,
        phase: 'playing',
        ready: true,
        revision: 2,
        dice: [1, 2],
        board: mine,
        playerBoards: {'player-1': mine, 'player-2': updated},
        events: [
          {'id': 'event-1', 'message': 'Jugador Uno creó la sala.'},
          {
            'id': 'event-2',
            'message': 'Jugador Dos completó amarilla.',
            'playerId': 'player-2',
            'region': 'amarilla',
            'round': 1,
          },
        ],
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(bloc.state.fase, FaseTurno.seleccionandoCasilla);
      expect(bloc.state.numeroAncla, 1);
      expect(
        tester
            .widget<VistaPreviaMapa>(find.byType(VistaPreviaMapa))
            .valores![0][0],
        4,
      );
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rival-zone-notice')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('rival-zone-notice')),
          matching: find.text('Jugador Dos completó amarilla.'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

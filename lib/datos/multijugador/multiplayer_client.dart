import 'dart:convert';
import 'dart:math';

import 'package:brilliant/datos/autenticacion/auth_client.dart';

class MultiplayerApiException implements Exception {
  const MultiplayerApiException(
    this.message, {
    this.code,
    this.requestId,
    this.statusCode,
  });

  final String message;
  final String? code;
  final String? requestId;
  final int? statusCode;

  bool get isConnectionFailure => statusCode == null || statusCode! >= 500;

  String get userMessage => requestId == null
      ? message
      : '$message\nCódigo de referencia: $requestId';

  @override
  String toString() => message;
}

class LobbyPlayer {
  const LobbyPlayer({required this.id, required this.name});

  final String id;
  final String name;
}

class LobbyRoom {
  const LobbyRoom({
    required this.code,
    required this.mapId,
    required this.hostName,
    required this.playerCount,
    required this.connectedPlayerCount,
  });

  final String code;
  final int mapId;
  final String hostName;
  final int playerCount;
  final int connectedPlayerCount;
}

class LobbySnapshot {
  const LobbySnapshot({required this.players, required this.rooms});

  final List<LobbyPlayer> players;
  final List<LobbyRoom> rooms;

  factory LobbySnapshot.fromJson(Map<String, dynamic> json) => LobbySnapshot(
    players: _list(json['activePlayers'])
        .map((value) {
          final player = _object(value);
          return LobbyPlayer(
            id: _string(player['id']),
            name: _string(player['name']),
          );
        })
        .toList(growable: false),
    rooms: _list(json['rooms'])
        .map((value) {
          final room = _object(value);
          return LobbyRoom(
            code: _string(room['code']),
            mapId: _integer(room['mapId']),
            hostName: _string(room['hostName']),
            playerCount: _integer(room['playerCount']),
            connectedPlayerCount: _integer(room['connectedPlayerCount']),
          );
        })
        .toList(growable: false),
  );
}

class RoomPlayer {
  const RoomPlayer({
    required this.id,
    required this.name,
    required this.isHost,
    required this.connected,
    required this.score,
    required this.forfeited,
    required this.isWinner,
    required this.ready,
    required this.playedThisRound,
  });

  final String id;
  final String name;
  final bool isHost;
  final bool connected;
  final int score;
  final bool forfeited;
  final bool isWinner;
  final bool ready;
  final bool playedThisRound;

  factory RoomPlayer.fromJson(Map<String, dynamic> json) => RoomPlayer(
    id: _string(json['id']),
    name: _string(json['name']),
    isHost: json['isHost'] == true,
    connected: json['connected'] == true,
    score: _integer(json['score']),
    forfeited: json['forfeited'] == true,
    isWinner: json['isWinner'] == true,
    ready: json['ready'] == true,
    playedThisRound: json['playedThisRound'] == true,
  );
}

class RoomEvent {
  const RoomEvent({required this.id, required this.message});

  final String id;
  final String message;

  factory RoomEvent.fromJson(Map<String, dynamic> json) =>
      RoomEvent(id: _string(json['id']), message: _string(json['message']));
}

class RoomSnapshot {
  const RoomSnapshot({
    required this.code,
    required this.mapId,
    required this.phase,
    required this.hostId,
    required this.players,
    required this.board,
    required this.dice,
    required this.round,
    required this.scoreToWin,
    required this.revision,
    required this.winners,
    required this.finishReason,
    required this.events,
    required this.regionCounters,
  });

  final String code;
  final int mapId;
  final String phase;
  final String hostId;
  final List<RoomPlayer> players;
  final List<List<int?>> board;
  final List<int>? dice;
  final int round;
  final int scoreToWin;
  final int revision;
  final List<String> winners;
  final String? finishReason;
  final List<RoomEvent> events;
  final Map<String, int> regionCounters;

  factory RoomSnapshot.fromJson(Map<String, dynamic> json) => RoomSnapshot(
    code: _string(json['code']),
    mapId: _integer(json['mapId']),
    phase: _string(json['phase']),
    hostId: _string(json['hostId']),
    players: _list(json['players'])
        .map((value) => RoomPlayer.fromJson(_object(value)))
        .toList(growable: false),
    board: _list(json['board'])
        .map(
          (row) =>
              _list(row)
                  .map((value) => value == null ? null : _integer(value))
                  .toList(growable: false),
        )
        .toList(growable: false),
    dice: json['dice'] == null
        ? null
        : _list(json['dice']).map(_integer).toList(growable: false),
    scoreToWin: _integer(json['scoreToWin']),
    revision: _integer(json['revision']),
    round: _integer(json['round']),
    winners: _list(json['winners']).map(_string).toList(growable: false),
    finishReason: json['finishReason'] as String?,
    events: _list(json['events'])
        .map((value) => RoomEvent.fromJson(_object(value)))
        .toList(growable: false),
    regionCounters: _object(json['regionCounters'])
        .map((key, value) => MapEntry(key, _integer(value))),
  );

  String? playerName(String? playerId) {
    if (playerId == null) return null;
    for (final player in players) {
      if (player.id == playerId) return player.name;
    }
    return null;
  }
}

class LeaveRoomResult {
  const LeaveRoomResult({
    required this.dissolved,
    required this.message,
    this.room,
  });

  final bool dissolved;
  final String? message;
  final RoomSnapshot? room;

  factory LeaveRoomResult.fromJson(Map<String, dynamic> json) =>
      LeaveRoomResult(
        dissolved: json['dissolved'] == true,
        message: json['message'] as String?,
        room: json['room'] == null
            ? null
            : RoomSnapshot.fromJson(_object(json['room'])),
      );
}

class MultiplayerClient {
  MultiplayerClient({required this.authClient});

  static final MultiplayerClient shared = MultiplayerClient(
    authClient: AuthClient.shared,
  );

  final AuthClient authClient;
  static final Random _random = Random.secure();

  Future<LobbySnapshot> lobby() async =>
      LobbySnapshot.fromJson(await _request('GET', '/api/multiplayer/lobby'));

  Future<RoomSnapshot> createRoom({required int mapId}) async =>
      RoomSnapshot.fromJson(
        await _request(
          'POST',
          '/api/multiplayer/rooms',
          body: {'mapId': mapId},
        ),
      );

  Future<RoomSnapshot> joinRoom(String code) async => RoomSnapshot.fromJson(
    await _request(
      'POST',
      '/api/multiplayer/rooms/${Uri.encodeComponent(code)}/join',
    ),
  );

  Future<RoomSnapshot> getRoom(String code) async => RoomSnapshot.fromJson(
    await _request(
      'GET',
      '/api/multiplayer/rooms/${Uri.encodeComponent(code)}',
    ),
  );

  Future<RoomSnapshot> startRoom(String code) async => RoomSnapshot.fromJson(
    await _request(
      'POST',
      '/api/multiplayer/rooms/${Uri.encodeComponent(code)}/start',
    ),
  );

  Future<RoomSnapshot> submitInitialBoard({
    required String code,
    required List<int> values,
  }) async => RoomSnapshot.fromJson(
    await _request(
      'POST',
      '/api/multiplayer/rooms/${Uri.encodeComponent(code)}/setup',
      body: {'values': values},
    ),
  );

  Future<RoomSnapshot> skipRound({
    required String code,
    required int round,
  }) async => RoomSnapshot.fromJson(
    await _request(
      'POST',
      '/api/multiplayer/rooms/${Uri.encodeComponent(code)}/skip',
      body: {'round': round},
    ),
  );

  Future<LeaveRoomResult> leaveRoom(String code) async =>
      LeaveRoomResult.fromJson(
        await _request(
          'POST',
          '/api/multiplayer/rooms/${Uri.encodeComponent(code)}/leave',
        ),
      );

  Future<RoomSnapshot> playMove({
    required String code,
    required String commandId,
    required int round,
    required int anchorDieIndex,
    required int anchorRow,
    required int anchorColumn,
    required int destinationRow,
    required int destinationColumn,
  }) async => RoomSnapshot.fromJson(
    await _request(
      'POST',
      '/api/multiplayer/rooms/${Uri.encodeComponent(code)}/move',
      body: {
        'round': round,
        'anchorDieIndex': anchorDieIndex,
        'anchor': {'row': anchorRow, 'column': anchorColumn},
        'destination': {'row': destinationRow, 'column': destinationColumn},
        'commandId': commandId,
      },
    ),
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    try {
      final response = await authClient.authenticatedRequest(
        method,
        path,
        body: body,
      );
      final decoded = jsonDecode(response.body);
      return _object(decoded);
    } on AuthApiException catch (error) {
      throw MultiplayerApiException(
        error.message,
        code: error.code,
        requestId: error.requestId,
        statusCode: error.statusCode,
      );
    } on FormatException {
      throw const MultiplayerApiException(
        'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  String _newCommandId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String newCommandId() => _newCommandId();
}

Map<String, dynamic> _object(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const MultiplayerApiException(
    'El servidor devolvió datos de sala no válidos.',
  );
}

List<Object?> _list(Object? value) {
  if (value is List<Object?>) return value;
  throw const MultiplayerApiException(
    'El servidor devolvió datos de sala no válidos.',
  );
}

String _string(Object? value) {
  if (value is String) return value;
  throw const MultiplayerApiException(
    'El servidor devolvió datos de sala no válidos.',
  );
}

int _integer(Object? value) {
  if (value is int) return value;
  throw const MultiplayerApiException(
    'El servidor devolvió datos de sala no válidos.',
  );
}

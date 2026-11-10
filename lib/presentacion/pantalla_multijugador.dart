import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../datos/autenticacion/auth_client.dart';
import '../datos/multijugador/multiplayer_client.dart';
import '../dominio/mapa_tablero.dart';
import 'pantalla_juego.dart';
import 'seleccion_mapa/widgets/vista_previa_mapa.dart';
import 'tema_mesa.dart';

class PantallaMultijugador extends StatefulWidget {
  const PantallaMultijugador({required this.user, this.client, super.key});

  final AuthUser user;
  final MultiplayerClient? client;

  @override
  State<PantallaMultijugador> createState() => _PantallaMultijugadorState();
}

class _PantallaMultijugadorState extends State<PantallaMultijugador> {
  MultiplayerClient get _client => widget.client ?? MultiplayerClient.shared;

  final _inviteCodeController = TextEditingController();
  Timer? _pollTimer;
  LobbySnapshot? _lobby;
  RoomSnapshot? _room;
  String? _error;
  String? _notice;
  String? _connectionMessage;
  Position? _anchor;
  int _mapId = 1;
  int _anchorDieIndex = 0;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _isPolling = false;
  bool _gameScreenOpen = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_isPolling || !mounted) return;
    _isPolling = true;
    var refreshLobbyAfterDissolution = false;
    try {
      final room = _room;
      if (room == null) {
        final lobby = await _client.lobby();
        if (mounted) {
          setState(() {
            _lobby = lobby;
            _isLoading = false;
            if (_connectionMessage != null) _error = null;
            _connectionMessage = null;
          });
        }
      } else {
        final updatedRoom = await _client.getRoom(room.code);
        if (mounted) {
          setState(() {
            _room = updatedRoom;
            if (_connectionMessage != null) _error = null;
            _connectionMessage = null;
            if (updatedRoom.revision != room.revision) _anchor = null;
          });
          _openGameIfStarted(updatedRoom);
        }
      }
    } on MultiplayerApiException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = error.userMessage;
          _connectionMessage = error.statusCode == null
              ? 'Conexión interrumpida. Reintentando; vuelve en menos de 60 segundos para evitar conceder la partida.'
              : null;
          if (error.code == 'ROOM_DISSOLVED' ||
              error.code == 'ROOM_NOT_FOUND') {
            _room = null;
            _anchor = null;
            _error = null;
            _connectionMessage = null;
            _notice = error.code == 'ROOM_DISSOLVED'
                ? '${error.message} Serás redirigido al lobby.'
                : '${error.message} Regresaste al lobby.';
            refreshLobbyAfterDissolution = true;
          }
        });
      }
    } finally {
      _isPolling = false;
    }
    if (refreshLobbyAfterDissolution && mounted) await _refresh();
  }

  Future<void> _runRoomAction(Future<RoomSnapshot> Function() action) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      final room = await action();
      if (mounted) {
        setState(() {
          _room = room;
          _anchor = null;
          _connectionMessage = null;
          _error = null;
        });
        _openGameIfStarted(room);
      }
    } on MultiplayerApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.userMessage;
          if (error.statusCode == null) {
            _connectionMessage =
                'Conexión interrumpida. Reintentando automáticamente.';
          }
        });
        if (error.code == 'STALE_ROUND') await _refresh();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _createRoom() async {
    await _runRoomAction(() => _client.createRoom(mapId: _mapId));
  }

  Future<void> _joinRoom([String? code]) async {
    final inviteCode = (code ?? _inviteCodeController.text)
        .trim()
        .toUpperCase();
    if (inviteCode.isEmpty) {
      setState(() => _error = 'Escribe el código de invitación.');
      return;
    }
    await _runRoomAction(() => _client.joinRoom(inviteCode));
  }

  Future<void> _startRoom() async {
    final room = _room;
    if (room == null) return;
    await _runRoomAction(() => _client.startRoom(room.code));
  }

  void _openGameIfStarted(RoomSnapshot room) {
    if (!mounted ||
        _gameScreenOpen ||
        (room.phase != 'setup' && room.phase != 'playing')) {
      return;
    }
    _gameScreenOpen = true;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (_) => PantallaJuego(
              mapa: _mapForId(room.mapId),
              multiplayerClient: _client,
              multiplayerUser: widget.user,
              roomCode: room.code,
              onRoomLeft: (message) {
                if (!mounted) return;
                setState(() {
                  _room = null;
                  _notice = message;
                });
              },
            ),
          ),
        )
        .whenComplete(() {
          _gameScreenOpen = false;
          if (mounted) _refresh();
        });
  }

  MapaTablero _mapForId(int mapId) => switch (mapId) {
    1 => MapaTablero.mapa1,
    2 => MapaTablero.mapa2,
    3 => MapaTablero.mapa3,
    4 => MapaTablero.mapa4,
    _ => throw ArgumentError.value(mapId, 'mapId', 'Mapa desconocido'),
  };

  Future<void> _leaveRoom() async {
    final room = _room;
    if (room == null || _isBusy) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final result = await _client.leaveRoom(room.code);
      if (!mounted) return;
      setState(() {
        _room = null;
        _anchor = null;
        _notice =
            result.message ??
            (result.dissolved ? 'La sala se cerró.' : 'Saliste de la sala.');
        _connectionMessage = null;
      });
      await _refresh();
    } on MultiplayerApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _leaveAndPop() async {
    await _leaveRoom();
    if (mounted && _room == null) Navigator.of(context).maybePop();
  }

  Future<void> _onCellTap(int row, int column) async {
    final room = _room;
    if (room == null ||
        room.phase != 'playing' ||
        room.players
            .firstWhere((player) => player.id == widget.user.id)
            .playedThisRound ||
        _isBusy ||
        room.dice == null) {
      return;
    }

    final value = room.board[row][column];
    final diceValue = room.dice![_anchorDieIndex];
    final currentAnchor = _anchor;
    if (currentAnchor == null) {
      if (value != diceValue) {
        setState(
          () => _error = 'Selecciona una casilla con el valor $diceValue.',
        );
        return;
      }
      setState(() {
        _anchor = Position(row, column);
        _error = null;
      });
      return;
    }

    if (row == currentAnchor.row && column == currentAnchor.column) {
      setState(() => _anchor = null);
      return;
    }
    if (value != null ||
        (row - currentAnchor.row).abs() +
                (column - currentAnchor.column).abs() !=
            1) {
      setState(() => _error = 'Elige una casilla vacía junto al ancla.');
      return;
    }

    await _runRoomAction(
      () => _client.playMove(
        code: room.code,
        round: room.round,
        anchorDieIndex: _anchorDieIndex,
        anchorRow: currentAnchor.row,
        anchorColumn: currentAnchor.column,
        destinationRow: row,
        destinationColumn: column,
      ),
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      setState(() => _notice = 'Código $code copiado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _room == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _room != null && !_isBusy) _leaveAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Multijugador'),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _isPolling ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const IndicadorCargaMesa(mensaje: 'Preparando el lobby...')
              : LayoutBuilder(
                  builder: (context, _) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_connectionMessage != null)
                              _statusBanner(
                                _connectionMessage!,
                                icon: Icons.wifi_off,
                              ),
                            if (_error != null)
                              _statusBanner(_error!, isError: true),
                            if (_notice != null)
                              _statusBanner(_notice!, icon: Icons.info_outline),
                            if (_room == null) _buildLobby() else _buildRoom(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLobby() {
    final lobby = _lobby;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Lobby',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text('Conectado como ${widget.user.name}', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text('Jugadores activos (${lobby?.players.length ?? 0})'),
        const SizedBox(height: 8),
        if (lobby == null || lobby.players.isEmpty)
          const Text('No hay otros jugadores conectados.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lobby.players
                .map((player) => Chip(label: Text(player.name)))
                .toList(growable: false),
          ),
        const Divider(height: 32),
        Text('Crear una sala', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('multiplayer-map-selector'),
                initialValue: _mapId,
                decoration: const InputDecoration(labelText: 'Mapa'),
                items: List.generate(
                  4,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('Mapa ${index + 1}'),
                  ),
                ),
                onChanged: _isBusy
                    ? null
                    : (value) => setState(() => _mapId = value!),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 88,
              child: VistaPreviaMapa(mapa: _mapForId(_mapId)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('create-multiplayer-room'),
          onPressed: _isBusy ? null : _createRoom,
          icon: const Icon(Icons.add),
          label: const Text('Crear sala'),
        ),
        const Divider(height: 32),
        Text(
          'Unirse con código',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('invite-code-input'),
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código de invitación',
                  counterText: '',
                ),
                onSubmitted: (_) => _joinRoom(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('join-room-by-code'),
              onPressed: _isBusy ? null : _joinRoom,
              child: const Text('Unirme'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Salas disponibles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (lobby == null || lobby.rooms.isEmpty)
          const Text('Todavía no hay salas disponibles.')
        else
          ...lobby.rooms.map(
            (room) => Card(
              child: ListTile(
                title: Text('Sala ${room.code} · Mapa ${room.mapId}'),
                subtitle: Text(
                  '${room.playerCount}/6 jugadores · Anfitrión: ${room.hostName}',
                ),
                trailing: IconButton(
                  tooltip: 'Unirme a ${room.code}',
                  onPressed: _isBusy ? null : () => _joinRoom(room.code),
                  icon: const Icon(Icons.login),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _buildRoom() {
    final room = _room!;
    final isHost = room.hostId == widget.user.id;
    RoomPlayer? myPlayer;
    for (final player in room.players) {
      if (player.id == widget.user.id) {
        myPlayer = player;
        break;
      }
    }
    final canPlayThisRound = myPlayer?.playedThisRound == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sala ${room.code}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              key: const Key('copy-invite-code'),
              tooltip: 'Copiar código',
              onPressed: () => _copyCode(room.code),
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        Text('Mapa ${room.mapId} · ${room.players.length}/6 jugadores'),
        const SizedBox(height: 12),
        Text('Jugadores', style: Theme.of(context).textTheme.titleLarge),
        ...room.players.map(
          (player) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              player.connected ? Icons.circle : Icons.circle_outlined,
              size: 14,
              color: player.connected ? Colors.green : Colors.orange,
            ),
            title: Text(
              '${player.name}${player.id == widget.user.id ? ' (tú)' : ''}',
            ),
            subtitle: Text(
              [
                if (player.isHost) 'Anfitrión',
                if (!player.connected) 'Desconectado',
                if (player.forfeited) 'Concedió',
                if (room.phase != 'waiting') '${player.score} puntos',
                if (room.phase == 'playing' && player.playedThisRound)
                  'Ronda lista',
                if (player.isWinner) 'Ganador',
              ].join(' · '),
            ),
            trailing: player.isWinner
                ? const Icon(Icons.emoji_events, color: Colors.amber)
                : null,
          ),
        ),
        if (room.phase == 'waiting') ...[
          const SizedBox(height: 12),
          Text(
            isHost
                ? 'Comparte el código para invitar. Puedes iniciar con 2 a 6 jugadores.'
                : 'Espera a que el anfitrión inicie la partida.',
            textAlign: TextAlign.center,
          ),
          if (isHost) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('start-multiplayer-game'),
              onPressed: _isBusy || room.players.length < 2 ? null : _startRoom,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar partida'),
            ),
          ],
        ] else if (room.phase == 'playing') ...[
          const Divider(height: 32),
          Text(
            canPlayThisRound
                ? 'Ronda ${room.round}: juega con estos dados compartidos'
                : 'Ronda completada. Esperando a los demás jugadores…',
            key: const Key('current-turn-status'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text('Meta: ${room.scoreToWin} puntos', textAlign: TextAlign.center),
          if (room.dice != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dados: ${room.dice![0]} y ${room.dice![1]}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (canPlayThisRound) ...[
              const SizedBox(height: 8),
              Text(
                _anchor == null
                    ? 'Elige qué dado usar como ancla y toca una casilla con ese valor.'
                    : 'Toca una casilla vacía adyacente para colocar el otro dado.',
                textAlign: TextAlign.center,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Ancla ${room.dice![0]}'),
                    selected: _anchorDieIndex == 0,
                    onSelected: _anchor == null
                        ? (_) => setState(() => _anchorDieIndex = 0)
                        : null,
                  ),
                  ChoiceChip(
                    label: Text('Ancla ${room.dice![1]}'),
                    selected: _anchorDieIndex == 1,
                    onSelected: _anchor == null
                        ? (_) => setState(() => _anchorDieIndex = 1)
                        : null,
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 12),
          _buildBoard(room, canPlayThisRound),
          if (myPlayer != null)
            Text(
              'Tu puntuación: ${myPlayer.score}',
              textAlign: TextAlign.center,
            ),
        ] else ...[
          const Divider(height: 32),
          Text(
            room.winners.isEmpty
                ? 'La partida terminó sin ganador.'
                : room.winners.length == 1
                ? 'Ganó ${room.playerName(room.winners.single) ?? 'un jugador'}.'
                : 'Empate: ${room.winners.map((id) => room.playerName(id) ?? '').join(', ')}',
            key: const Key('multiplayer-result'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(_finishMessage(room), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('leave-multiplayer-room'),
          onPressed: _isBusy ? null : _leaveRoom,
          icon: const Icon(Icons.logout),
          label: const Text('Abandonar sala'),
        ),
        if (room.events.isNotEmpty) ...[
          const Divider(height: 32),
          Text('Actividad', style: Theme.of(context).textTheme.titleMedium),
          for (final event in room.events.reversed.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(event.message),
            ),
        ],
      ],
    );
  }

  Widget _buildBoard(RoomSnapshot room, bool isMyTurn) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        key: const Key('multiplayer-board'),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 49,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ 7;
          final column = index % 7;
          final value = room.board[row][column];
          final isAnchor = _anchor?.row == row && _anchor?.column == column;
          final selectableAnchor =
              isMyTurn &&
              _anchor == null &&
              value == room.dice?[_anchorDieIndex];
          return Material(
            color: isAnchor
                ? Theme.of(context).colorScheme.primary
                : value == null
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              key: Key('multiplayer-cell-$row-$column'),
              onTap: isMyTurn ? () => _onCellTap(row, column) : null,
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: Text(
                  value?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: selectableAnchor
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBanner(
    String message, {
    IconData icon = Icons.error_outline,
    bool isError = false,
  }) => Card(
    color: isError
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );

  String _finishMessage(RoomSnapshot room) {
    if (room.winners.isEmpty) {
      return 'No quedó ningún jugador conectado antes de vencer el plazo.';
    }
    return switch (room.finishReason) {
      'score' => 'Se alcanzó primero la puntuación objetivo.',
      'host_forfeit' || 'host_disconnected' =>
        'El anfitrión abandonó o perdió la conexión; los demás ganaron.',
      'player_forfeit' || 'player_disconnected' =>
        'Un jugador abandonó o no se reconectó a tiempo; los demás ganaron.',
      'no_moves' => 'No hubo jugadas válidas. Ganó la puntuación más alta.',
      _ => '',
    };
  }
}

class Position {
  const Position(this.row, this.column);

  final int row;
  final int column;
}

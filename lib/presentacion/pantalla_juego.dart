import 'dart:async';

import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/datos/multijugador/multiplayer_client.dart';
import 'package:brilliant/datos/audio_juego.dart';
import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/presentacion/widgets/historial_partida_widget.dart';
import 'package:brilliant/presentacion/widgets/instrucciones_juego_widget.dart';
import 'package:brilliant/presentacion/widgets/panel_datos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/zona_inicial_cubit.dart';
import '../dominio/tablero.dart';
import '../dominio/zona_inicial.dart';
import 'mensajes/mensajes_zona_inicial_listener.dart';
import 'seleccion_mapa/widgets/vista_previa_mapa.dart';
import 'teclado/atajos_teclado_zona_inicial.dart';
import 'widgets/boton_inicio.dart';
import 'widgets/boton_audio.dart';
import 'widgets/instruccion_zona_inicial.dart';
import 'widgets/puntuaciones_disponibles_widget.dart';
import 'widgets/selector_numeros_zona_inicial.dart';
import 'widgets/tablero_widget.dart';
import 'tema_mesa.dart';

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({
    super.key,
    this.mapa = MapaTablero.mapa1,
    this.multiplayerClient,
    this.multiplayerUser,
    this.roomCode,
    this.onRoomLeft,
    this.onRoomLeftOffline,
  });

  final MapaTablero mapa;
  final MultiplayerClient? multiplayerClient;
  final AuthUser? multiplayerUser;
  final String? roomCode;
  final ValueChanged<String>? onRoomLeft;
  final VoidCallback? onRoomLeftOffline;

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  final TableroJuego tablero = TableroJuego();
  Timer? _pollTimer;
  BuildContext? _gameContext;
  JuegoState? _lastObservedGameState;
  RoomSnapshot? _room;
  final ValueNotifier<RoomSnapshot?> _roomNotifier = ValueNotifier(null);
  String? _remoteError;
  bool _isPolling = false;
  bool _isBusy = false;
  bool _allowPop = false;
  bool _returningToLobby = false;
  bool _connectionLost = false;
  bool _waitingForConnection = false;
  bool _resultsDialogShown = false;
  bool _victorySoundPlayed = false;
  final Set<String> _seenRoomEvents = {};
  final Map<int, List<RoomEvent>> _pendingCompletions = {};
  bool _roomEventsInitialized = false;
  String? _completionNotice;
  Timer? _noticeTimer;
  int? _lastSynchronizedRevision;
  int? _lastSynchronizedRound;
  Future<RoomSnapshot> Function()? _pendingMoveRetry;

  bool get _isMultiplayer =>
      widget.multiplayerClient != null &&
      widget.multiplayerUser != null &&
      widget.roomCode != null;

  MultiplayerClient get _multiplayerClient => widget.multiplayerClient!;
  AuthUser get _multiplayerUser => widget.multiplayerUser!;

  @override
  void initState() {
    super.initState();
    if (_isMultiplayer) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshMultiplayer(),
      );
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _refreshMultiplayer(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _noticeTimer?.cancel();
    _roomNotifier.dispose();
    unawaited(AudioJuego.instancia.detenerMusica());
    super.dispose();
  }

  void _reproducirSonidosDeJugada(JuegoState anterior, JuegoState actual) {
    final nuevaTirada =
        actual.dado1 != null &&
        actual.dado2 != null &&
        (anterior.dado1 != actual.dado1 ||
            anterior.dado2 != actual.dado2 ||
            (actual.historial.length > anterior.historial.length &&
                actual.historial.isNotEmpty &&
                actual.historial.first.startsWith('🎲 Dados tirados:')));
    if (nuevaTirada) {
      unawaited(AudioJuego.instancia.reproducir(SonidoJuego.dados));
    }

    if (anterior.fase == FaseTurno.seleccionandoCasilla &&
        actual.fase == FaseTurno.colocandoNumero) {
      unawaited(AudioJuego.instancia.reproducir(SonidoJuego.ancla));
    }

    final casillasAnteriores = anterior.tablero
        .expand((fila) => fila)
        .where((casilla) => casilla.valorActual != null)
        .length;
    final casillasActuales = actual.tablero
        .expand((fila) => fila)
        .where((casilla) => casilla.valorActual != null)
        .length;
    if (casillasAnteriores >= 6 && casillasActuales > casillasAnteriores) {
      unawaited(AudioJuego.instancia.reproducir(SonidoJuego.numero));
    }

    final zonasCompletadas = actual.contadorCompletadasPorRegion.entries.fold(
      0,
      (total, entrada) =>
          total +
          entrada.value -
          (anterior.contadorCompletadasPorRegion[entrada.key] ?? 0),
    );
    for (var zona = 0; !_isMultiplayer && zona < zonasCompletadas; zona++) {
      unawaited(AudioJuego.instancia.reproducir(SonidoJuego.zonaCompleta));
    }

    if (!anterior.tableroCompleto &&
        actual.tableroCompleto &&
        !_victorySoundPlayed) {
      _victorySoundPlayed = true;
      unawaited(AudioJuego.instancia.reproducir(SonidoJuego.victoria));
    }
  }

  Future<void> _refreshMultiplayer({bool force = false}) async {
    if (!_isMultiplayer || _isPolling || (_isBusy && !force) || !mounted) {
      return;
    }
    _isPolling = true;
    Future<RoomSnapshot> Function()? pendingMove;
    try {
      final room = await _multiplayerClient.getRoom(widget.roomCode!);
      if (!mounted) return;
      RoomPlayer? currentPlayer;
      for (final player in room.players) {
        if (player.id == _multiplayerUser.id) currentPlayer = player;
      }
      if (currentPlayer == null || currentPlayer.forfeited) {
        _returnToLobby(
          'Se agotó el minuto sin conexión y saliste de la partida. '
          'Tus puntos y las zonas ya obtenidas se conservaron.',
        );
        return;
      }
      _handleRoomEvents(room);
      _synchronizeRoom(room);
      _roomNotifier.value = room;
      setState(() {
        _room = room;
        _remoteError = null;
        _connectionLost = false;
        _waitingForConnection = false;
      });
      _showResultsIfFinished(room);
      pendingMove = _pendingMoveRetry;
    } on MultiplayerApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'ROOM_DISSOLVED' || error.code == 'ROOM_NOT_FOUND') {
        _returnToLobby(error.message);
      } else {
        setState(() {
          _remoteError = error.userMessage;
          _connectionLost = error.isConnectionFailure;
        });
      }
    } finally {
      _isPolling = false;
    }
    if (pendingMove != null && mounted && !_isBusy) {
      await _runRoomAction(pendingMove, isQueuedMove: true);
    }
  }

  void _synchronizeRoom(RoomSnapshot room) {
    final context = _gameContext;
    if (context == null || !context.mounted) return;
    final currentPlayer = room.players.firstWhere(
      (player) => player.id == _multiplayerUser.id,
    );
    if (_lastSynchronizedRevision == room.revision) return;
    _lastSynchronizedRevision = room.revision;
    final previous = context.read<JuegoBloc>().state;
    final preserveSelection =
        _lastSynchronizedRound == room.round &&
        room.phase == 'playing' &&
        !currentPlayer.playedThisRound &&
        previous.fase != FaseTurno.inicio &&
        previous.fase != FaseTurno.turnoTerminado &&
        List.generate(7, (row) => row).every(
          (row) => List.generate(7, (column) => column).every(
            (column) =>
                previous.tablero[row][column].valorActual ==
                room.board[row][column],
          ),
        );
    _lastSynchronizedRound = room.round;

    final initialValues = <Posicion, int>{};
    for (final position in ZonaInicial.posicionesParaMapa(widget.mapa)) {
      final value = room.board[position.fila][position.columna];
      if (value != null) initialValues[position] = value;
    }
    context.read<ZonaInicialCubit>().restaurarDesdeServidor(
      valores: initialValues,
      iniciada:
          currentPlayer.ready ||
          room.phase == 'playing' ||
          room.phase == 'finished',
    );

    for (var row = 0; row < TableroJuego.filas; row++) {
      for (var column = 0; column < TableroJuego.columnas; column++) {
        tablero.asignarValor(row, column, room.board[row][column]);
      }
    }

    final hasPlayedThisRound = currentPlayer.playedThisRound;
    final phase = switch (room.phase) {
      'setup' => FaseTurno.inicio,
      'playing' when !hasPlayedThisRound => FaseTurno.seleccionandoAncla,
      _ => FaseTurno.turnoTerminado,
    };
    context.read<JuegoBloc>().add(
      SincronizarJuegoMultijugador(
        JuegoState(
          tablero: preserveSelection
              ? previous.tablero
              : [
                  for (var row = 0; row < TableroJuego.filas; row++)
                    [
                      for (
                        var column = 0;
                        column < TableroJuego.columnas;
                        column++
                      )
                        Casilla(
                          fila: row,
                          columna: column,
                          valorActual: room.board[row][column],
                        ),
                    ],
                ],
          fase: preserveSelection ? previous.fase : phase,
          dado1: room.dice == null ? null : room.dice![0],
          dado2: room.dice == null ? null : room.dice![1],
          numeroAncla: preserveSelection ? previous.numeroAncla : null,
          numeroColocar: preserveSelection ? previous.numeroColocar : null,
          indiceDadoAncla: preserveSelection ? previous.indiceDadoAncla : null,
          filaAncla: preserveSelection ? previous.filaAncla : null,
          columnaAncla: preserveSelection ? previous.columnaAncla : null,
          filaProvisional: preserveSelection ? previous.filaProvisional : null,
          columnaProvisional: preserveSelection
              ? previous.columnaProvisional
              : null,
          turnoSaltadoAutomaticamente: currentPlayer.noLegalMove,
          puntuacionTotal: currentPlayer.score,
          contadorCompletadasPorRegion: room.regionCounters,
          regionesCompletadas: room.regionCounters.entries
              .where((entry) => entry.value > 0)
              .map((entry) => entry.key)
              .toSet(),
          historial: room.events.reversed
              .map((event) => event.message)
              .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _submitInitialBoard(Map<Posicion, int> values) async {
    final room = _room;
    if (room == null) return;
    final positions = ZonaInicial.posicionesParaMapa(widget.mapa);
    final orderedValues = <int>[];
    for (final position in positions) {
      final value = values[position];
      if (value == null) {
        setState(() => _remoteError = 'Completa los seis números iniciales.');
        return;
      }
      orderedValues.add(value);
    }
    await _runRoomAction(
      () => _multiplayerClient.submitInitialBoard(
        code: room.code,
        values: orderedValues,
      ),
    );
  }

  Future<void> _submitMove() async {
    final room = _room;
    final context = _gameContext;
    if (room == null || context == null || !context.mounted) return;
    final state = context.read<JuegoBloc>().state;
    final anchorRow = state.filaAncla;
    final anchorColumn = state.columnaAncla;
    final destinationRow = state.filaProvisional;
    final destinationColumn = state.columnaProvisional;
    final anchorDieIndex = state.indiceDadoAncla;
    if (anchorRow == null ||
        anchorColumn == null ||
        destinationRow == null ||
        destinationColumn == null ||
        anchorDieIndex == null) {
      setState(
        () => _remoteError = 'Selecciona una jugada válida antes de confirmar.',
      );
      return;
    }
    if (_pendingMoveRetry != null) return;
    final commandId = _multiplayerClient.newCommandId();
    Future<RoomSnapshot> pendingMove() => _multiplayerClient.playMove(
      code: room.code,
      commandId: commandId,
      anchorDieIndex: anchorDieIndex - 1,
      round: room.round,
      anchorRow: anchorRow,
      anchorColumn: anchorColumn,
      destinationRow: destinationRow,
      destinationColumn: destinationColumn,
    );
    _pendingMoveRetry = pendingMove;
    await _runRoomAction(pendingMove, isQueuedMove: true);
  }

  Future<void> _skipTurn() async {
    final room = _room;
    if (room == null) return;
    await _runRoomAction(
      () => _multiplayerClient.skipRound(code: room.code, round: room.round),
    );
  }

  Future<void> _runRoomAction(
    Future<RoomSnapshot> Function() action, {
    bool isQueuedMove = false,
  }) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _remoteError = null;
    });
    try {
      final room = await action();
      if (!mounted) return;
      _handleRoomEvents(room);
      _synchronizeRoom(room);
      _roomNotifier.value = room;
      setState(() {
        _room = room;
        _remoteError = null;
        _connectionLost = false;
        _waitingForConnection = false;
        if (isQueuedMove) _pendingMoveRetry = null;
      });
      _showResultsIfFinished(room);
    } on MultiplayerApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _remoteError = error.userMessage;
        _connectionLost = error.isConnectionFailure;
        if (isQueuedMove && !error.isConnectionFailure) {
          _pendingMoveRetry = null;
        }
      });
      if (error.code == 'PLAYER_FORFEITED') {
        await _refreshMultiplayer(force: true);
      }
      if (error.code == 'STALE_STATE' || error.code == 'STALE_ROUND') {
        await _refreshMultiplayer(force: true);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _handleRoomEvents(RoomSnapshot room) {
    final incoming = room.events
        .where((event) => _seenRoomEvents.add(event.id))
        .toList();
    if (!_roomEventsInitialized) {
      _roomEventsInitialized = true;
      for (final event in incoming) {
        if (event.playerId == _multiplayerUser.id &&
            event.region != null &&
            event.round == room.round) {
          _pendingCompletions.putIfAbsent(event.round!, () => []).add(event);
        }
      }
      return;
    }
    for (final event in incoming) {
      if (event.playerId == null || event.region == null || event.round == null)
        continue;
      _pendingCompletions.putIfAbsent(event.round!, () => []).add(event);
      if (event.playerId == _multiplayerUser.id) {
        unawaited(AudioJuego.instancia.reproducir(SonidoJuego.zonaCompleta));
      } else {
        _noticeTimer?.cancel();
        _completionNotice = event.message;
        _noticeTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _completionNotice = null);
        });
      }
    }
    final settled = _pendingCompletions.keys
        .where((round) => round < room.round || room.phase == 'finished')
        .toList();
    for (final round in settled) {
      final events = _pendingCompletions.remove(round)!;
      final ownRegions = events
          .where((event) => event.playerId == _multiplayerUser.id)
          .map((event) => event.region)
          .toSet();
      final rivalOnly = events.any(
        (event) =>
            event.playerId != _multiplayerUser.id &&
            !ownRegions.contains(event.region),
      );
      if (rivalOnly) {
        unawaited(AudioJuego.instancia.reproducir(SonidoJuego.zonaRival));
      }
    }
  }

  Future<void> _leaveMultiplayerGame({bool returnToLobby = false}) async {
    final room = _room;
    if (room == null || _isBusy) return;
    setState(() {
      _isBusy = true;
      _remoteError = null;
    });
    try {
      final result = await _multiplayerClient.leaveRoom(room.code);
      if (!mounted) return;
      _returnToLobby(
        result.message ??
            (result.dissolved ? 'La sala se cerró.' : 'Saliste de la sala.'),
      );
    } on MultiplayerApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'ROOM_DISSOLVED' || error.code == 'ROOM_NOT_FOUND') {
        _returnToLobby(error.message);
      } else if (error.isConnectionFailure) {
        widget.onRoomLeftOffline?.call();
        _returnToLobby(
          'No se pudo avisar al servidor. Tu salida se registrará '
          'automáticamente al reconectar.',
        );
      } else if (returnToLobby) {
        _returnToLobby(error.userMessage);
      } else {
        setState(() => _remoteError = error.userMessage);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _returnToLobby(String message) {
    if (!mounted || _returningToLobby) return;
    _returningToLobby = true;
    setState(() => _allowPop = true);
    widget.onRoomLeft?.call(message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Widget _connectionNotice({bool compact = false}) => Card(
    key: const Key('multiplayer-connection-lost'),
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 12,
      ),
      child: compact
          ? Row(
              children: [
                const Icon(Icons.cloud_off_outlined, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _waitingForConnection
                        ? 'Esperando conexión…'
                        : _pendingMoveRetry != null
                        ? 'Sin conexión. Tu jugada está pendiente; se reintentará.'
                        : 'Sin conexión con el servidor.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (!_waitingForConnection)
                  TextButton(
                    key: const Key('wait-for-game-server'),
                    onPressed: () =>
                        setState(() => _waitingForConnection = true),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: const Text('Esperar'),
                  ),
                TextButton(
                  key: const Key('leave-game-while-offline'),
                  onPressed: _isBusy ? null : _leaveMultiplayerGame,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text('Salir'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _waitingForConnection
                      ? 'Esperando que vuelva la conexión con el servidor. '
                            'Se reintentará automáticamente.'
                      : 'Se perdió la conexión con el servidor. '
                            'Puedes esperar o salir de la sala.',
                ),
                if (_pendingMoveRetry != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Tu jugada está pendiente y se enviará automáticamente '
                      'al reconectar.',
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    if (!_waitingForConnection)
                      TextButton(
                        key: const Key('wait-for-game-server'),
                        onPressed: () =>
                            setState(() => _waitingForConnection = true),
                        child: const Text('Seguir esperando'),
                      ),
                    TextButton(
                      key: const Key('leave-game-while-offline'),
                      onPressed: _isBusy ? null : _leaveMultiplayerGame,
                      child: const Text('Salir de la sala'),
                    ),
                  ],
                ),
              ],
            ),
    ),
  );

  void _showResultsIfFinished(RoomSnapshot room) {
    if (room.phase != 'finished' || !mounted) return;
    if (room.winners.isNotEmpty && !_victorySoundPlayed) {
      _victorySoundPlayed = true;
      unawaited(AudioJuego.instancia.reproducir(SonidoJuego.victoria));
    }
    if (_resultsDialogShown) return;
    _resultsDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _PartidaFinalizadaDialog(
            room: room,
            mapa: widget.mapa,
            onReturnToLobby: () {
              Navigator.of(dialogContext).pop();
              _leaveMultiplayerGame(returnToLobby: true);
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<JuegoBloc>(create: (_) => JuegoBloc(mapa: widget.mapa)),
        BlocProvider<ZonaInicialCubit>(
          create: (_) => ZonaInicialCubit(mapa: widget.mapa),
        ),
      ],
      child: AtajosTecladoZonaInicial(
        child: Builder(
          builder: (context) {
            _gameContext = context;
            _lastObservedGameState ??= context.read<JuegoBloc>().state;
            return PopScope<Object?>(
              canPop: !_isMultiplayer || _allowPop,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && _isMultiplayer) _leaveMultiplayerGame();
              },
              child: BlocListener<JuegoBloc, JuegoState>(
                listener: (context, state) {
                  final anterior = _lastObservedGameState;
                  if (anterior != null) {
                    _reproducirSonidosDeJugada(anterior, state);
                  }
                  _lastObservedGameState = state;
                },
                child: MensajesZonaInicialListener(
                  child: _buildScaffold(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isMultiplayer ? 'Brilliant · ${widget.roomCode}' : 'Brilliant',
        ),
        actions: [
          const BotonAudio(),
          if (_isMultiplayer)
            IconButton(
              key: const Key('show-player-boards'),
              tooltip: 'Ver tableros de jugadores',
              onPressed: _room == null
                  ? null
                  : () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Tableros de jugadores'),
                          content: SizedBox(
                            width: 360,
                            child: ValueListenableBuilder<RoomSnapshot?>(
                              valueListenable: _roomNotifier,
                              builder: (context, room, _) =>
                                  SingleChildScrollView(
                                    child: room == null
                                        ? const Text('Esperando tableros…')
                                        : _TablerosJugadores(
                                            room: room,
                                            mapa: widget.mapa,
                                            excludePlayerId:
                                                _multiplayerUser.id,
                                          ),
                                  ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
              icon: const Icon(Icons.grid_view_rounded),
            ),
          if (_isMultiplayer)
            IconButton(
              key: const Key('leave-multiplayer-game'),
              tooltip: 'Abandonar partida',
              onPressed: _leaveMultiplayerGame,
              icon: const Icon(Icons.logout),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<JuegoBloc, JuegoState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withAlpha(230),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.amber.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade700,
                        size: 26,
                      ),
                      const SizedBox(width: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                        child: Text(
                          '${state.puntuacionTotal}',
                          key: ValueKey<int>(state.puntuacionTotal),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_completionNotice != null)
              Container(
                key: const Key('rival-zone-notice'),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6B4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TemaMesa.dorado),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: TemaMesa.nogal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _completionNotice!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Cerrar aviso',
                      onPressed: () => setState(() => _completionNotice = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 960 ||
                      constraints.maxHeight < 640) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_connectionLost) _connectionNotice(compact: true),
                        Expanded(
                          child: SingleChildScrollView(
                            key: const Key('mobile-game-content'),
                            padding: const EdgeInsets.all(8),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const InstruccionZonaInicial(),
                                    TableroWidget(mapa: widget.mapa),
                                    const Text(
                                      'Las casillas con la misma etiqueta forman una sola zona.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    const SizedBox(height: 8),
                                    PuntuacionesDisponiblesWidget(
                                      mapa: widget.mapa,
                                      horizontal: true,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Registro de partida'),
                                    const HistorialPartidaWidget(
                                      height: 180,
                                      showEmptyMessage: true,
                                    ),
                                    const InstruccionesJuegoWidget(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.45,
                          ),
                          child: SingleChildScrollView(
                            child: _PanelPartida(
                              tablero: tablero,
                              compacto: true,
                              mobile: true,
                              mapa: widget.mapa,
                              multiplayer: _isMultiplayer,
                              room: _room,
                              currentUserId: widget.multiplayerUser?.id,
                              isBusy: _isBusy || _pendingMoveRetry != null,
                              onStart: _submitInitialBoard,
                              onConfirmMove: _submitMove,
                              onSkipTurn: _skipTurn,
                              errorMessage: _remoteError,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_connectionLost) _connectionNotice(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const InstruccionZonaInicial(),
                                        const SizedBox(height: 16),
                                        _TableroConPuntuaciones(
                                          mapa: widget.mapa,
                                          altoDisponible:
                                              constraints.maxHeight -
                                              (_connectionLost ? 100 : 0),
                                        ),
                                        const Text(
                                          'Las casillas con la misma etiqueta forman una sola zona.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _PanelPartida(
                                  tablero: tablero,
                                  multiplayer: _isMultiplayer,
                                  room: _room,
                                  currentUserId: widget.multiplayerUser?.id,
                                  isBusy: _isBusy || _pendingMoveRetry != null,
                                  onStart: _submitInitialBoard,
                                  onConfirmMove: _submitMove,
                                  onSkipTurn: _skipTurn,
                                  errorMessage: _remoteError,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableroConPuntuaciones extends StatelessWidget {
  const _TableroConPuntuaciones({
    required this.mapa,
    required this.altoDisponible,
  });

  final MapaTablero mapa;
  final double altoDisponible;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const espacioEntre = 8.0;
        final anchoPanel = (constraints.maxWidth * 0.4)
            .clamp(120.0, 220.0)
            .toDouble();
        final anchoTablero = constraints.maxWidth - anchoPanel - espacioEntre;
        final maximoPorAlto = (altoDisponible * 0.9).clamp(120.0, 720.0);
        final ladoTablero = anchoTablero.clamp(1.0, maximoPorAlto);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: ladoTablero,
              child: TableroWidget(mapa: mapa),
            ),
            const SizedBox(width: espacioEntre),
            SizedBox(
              width: anchoPanel,
              child: PuntuacionesDisponiblesWidget(mapa: mapa),
            ),
          ],
        );
      },
    );
  }
}

class _PanelPartida extends StatelessWidget {
  const _PanelPartida({
    required this.tablero,
    this.compacto = false,
    this.multiplayer = false,
    this.room,
    this.currentUserId,
    this.isBusy = false,
    this.onStart,
    this.onConfirmMove,
    this.onSkipTurn,
    this.errorMessage,
    this.mobile = false,
    this.mapa = MapaTablero.mapa1,
  });

  final TableroJuego tablero;
  final bool compacto;
  final bool multiplayer;
  final RoomSnapshot? room;
  final String? currentUserId;
  final bool isBusy;
  final Future<void> Function(Map<Posicion, int>)? onStart;
  final VoidCallback? onConfirmMove;
  final VoidCallback? onSkipTurn;
  final String? errorMessage;
  final bool mobile;
  final MapaTablero mapa;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: mobile ? const Key('mobile-game-controls') : null,
      padding: EdgeInsets.all(mobile ? 8 : 16),
      decoration: BoxDecoration(
        color: TemaMesa.papelClaro,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaMesa.nogal.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (multiplayer && room != null) ...[
            if (!mobile) ...[
              Text(
                'Sala ${room!.code}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TemaMesa.nogal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              key: const Key('multiplayer-game-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          if (!mobile) ...[
            const Text(
              'Registro de Partida',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TemaMesa.nogal,
              ),
            ),
            const SizedBox(height: 8),
            if (compacto)
              const HistorialPartidaWidget()
            else
              const Expanded(child: HistorialPartidaWidget()),
            const SizedBox(height: 16),
            const Divider(color: Color(0x5568452D)),
            const SizedBox(height: 16),
          ],
          BlocBuilder<JuegoBloc, JuegoState>(
            builder: (context, juegoState) {
              if (multiplayer && room == null) {
                return const Text(
                  'Conectando con la sala…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TemaMesa.nogal),
                );
              }

              if (juegoState.fase == FaseTurno.inicio) {
                RoomPlayer? myPlayer;
                for (final player in room?.players ?? const <RoomPlayer>[]) {
                  if (player.id == currentUserId) myPlayer = player;
                }
                if (multiplayer && myPlayer?.ready == true) {
                  return const Text(
                    'Configuración enviada. Esperando a los demás jugadores…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TemaMesa.nogal),
                  );
                }
                return Column(
                  children: [
                    const SelectorNumerosZonaInicial(),
                    const SizedBox(height: 20),
                    BotonInicio(
                      tablero: tablero,
                      onStart: multiplayer ? onStart : null,
                    ),
                  ],
                );
              }
              if (multiplayer && room?.phase == 'finished') {
                final winners = room!.winners
                    .map((id) => room!.playerName(id) ?? id)
                    .join(', ');
                return Text(
                  winners.isEmpty ? 'Partida finalizada.' : 'Ganador: $winners',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TemaMesa.nogal,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              RoomPlayer? myPlayer;
              for (final player in room?.players ?? const <RoomPlayer>[]) {
                if (player.id == currentUserId) myPlayer = player;
              }
              final canPlayThisRound =
                  !multiplayer || myPlayer?.playedThisRound == false;
              final hasCompletedRound =
                  multiplayer && myPlayer?.playedThisRound == true;
              final activePlayers =
                  room?.players.where((player) => !player.forfeited).length ??
                  0;
              final completedPlayers =
                  room?.players
                      .where(
                        (player) => !player.forfeited && player.playedThisRound,
                      )
                      .length ??
                  0;
              return PanelDados(
                isEnabled: canPlayThisRound && !isBusy,
                onSkipTurn: multiplayer ? onSkipTurn : null,
                onConfirmMove: multiplayer ? onConfirmMove : null,
                waitingForRound: hasCompletedRound,
                turnMessage: multiplayer
                    ? (hasCompletedRound
                          ? 'Ronda completada ($completedPlayers/$activePlayers). Esperando a los demás jugadores…'
                          : 'Ronda ${room!.round}: dados compartidos por todos')
                    : null,
                skipTurnLabel: multiplayer ? 'Terminar mi ronda' : null,
                compact: mobile,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PartidaFinalizadaDialog extends StatelessWidget {
  const _PartidaFinalizadaDialog({
    required this.room,
    required this.mapa,
    required this.onReturnToLobby,
  });

  final RoomSnapshot room;
  final MapaTablero mapa;
  final VoidCallback onReturnToLobby;

  @override
  Widget build(BuildContext context) {
    final winners = room.winners
        .map((id) => room.playerName(id))
        .whereType<String>()
        .toList(growable: false);
    final ranking = [...room.players]
      ..sort((first, second) => second.score.compareTo(first.score));

    return AlertDialog(
      key: const Key('multiplayer-results-dialog'),
      icon: const Icon(
        Icons.emoji_events_rounded,
        color: TemaMesa.dorado,
        size: 42,
      ),
      title: Text(
        winners.isEmpty
            ? 'Partida finalizada'
            : winners.length == 1
            ? '¡Ganó ${winners.single}!'
            : '¡Empate!',
        textAlign: TextAlign.center,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (winners.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    winners.join(', '),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              Text(
                _finishMessage(room.finishReason),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Puntuaciones finales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < ranking.length; index++)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: room.winners.contains(ranking[index].id)
                      ? const Color(0xFFFFF3D6)
                      : null,
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: room.winners.contains(ranking[index].id)
                          ? TemaMesa.dorado
                          : TemaMesa.papel,
                      foregroundColor: TemaMesa.nogalOscuro,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      ranking[index].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: ranking[index].forfeited
                        ? const Text('Abandonó la partida')
                        : null,
                    trailing: Text(
                      '${ranking[index].score} pts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Tableros finales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _TablerosJugadores(room: room, mapa: mapa),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton.icon(
          key: const Key('finished-return-to-lobby'),
          onPressed: onReturnToLobby,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Regresar al lobby'),
        ),
      ],
    );
  }

  String _finishMessage(String? reason) => switch (reason) {
    'score' => 'Se alcanzó la puntuación objetivo.',
    'host_forfeit' ||
    'host_disconnected' => 'El anfitrión abandonó o perdió la conexión.',
    'player_forfeit' || 'player_disconnected' =>
      'La partida terminó tras la salida o desconexión de un jugador.',
    'no_moves' => 'No hubo más jugadas válidas; ganó la puntuación más alta.',
    _ => 'Gracias por jugar.',
  };
}

class _TablerosJugadores extends StatelessWidget {
  const _TablerosJugadores({
    required this.room,
    required this.mapa,
    this.excludePlayerId,
  });

  final RoomSnapshot room;
  final MapaTablero mapa;
  final String? excludePlayerId;

  @override
  Widget build(BuildContext context) {
    final players = room.players.where(
      (player) => player.id != excludePlayerId,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final player in players)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  player.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                if (player.board == null)
                  const Text('El tablero aún no está disponible.')
                else
                  SizedBox(
                    width: 240,
                    child: VistaPreviaMapa(mapa: mapa, valores: player.board),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

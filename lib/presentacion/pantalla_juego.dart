import 'dart:async';

import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/datos/multijugador/multiplayer_client.dart';
import 'package:brilliant/dominio/casilla.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/presentacion/widgets/historial_partida_widget.dart';
import 'package:brilliant/presentacion/widgets/panel_datos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/zona_inicial_cubit.dart';
import '../dominio/tablero.dart';
import '../dominio/zona_inicial.dart';
import 'mensajes/mensajes_zona_inicial_listener.dart';
import 'teclado/atajos_teclado_zona_inicial.dart';
import 'widgets/boton_inicio.dart';
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
  RoomSnapshot? _room;
  String? _remoteError;
  bool _isPolling = false;
  bool _isBusy = false;
  bool _allowPop = false;
  bool _returningToLobby = false;
  bool _connectionLost = false;
  bool _waitingForConnection = false;
  bool _resultsDialogShown = false;
  int? _lastSynchronizedRevision;
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
    super.dispose();
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
      _synchronizeRoom(room);
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
          tablero: [
            for (var row = 0; row < TableroJuego.filas; row++)
              [
                for (var column = 0; column < TableroJuego.columnas; column++)
                  Casilla(
                    fila: row,
                    columna: column,
                    valorActual: room.board[row][column],
                  ),
              ],
          ],
          fase: phase,
          dado1: room.dice == null ? null : room.dice![0],
          dado2: room.dice == null ? null : room.dice![1],
          turnoSaltadoAutomaticamente: false,
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
      _synchronizeRoom(room);
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
    if (room.phase != 'finished' || _resultsDialogShown || !mounted) return;
    _resultsDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _PartidaFinalizadaDialog(
            room: room,
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
            return PopScope<Object?>(
              canPop: !_isMultiplayer || _allowPop,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && _isMultiplayer) _leaveMultiplayerGame();
              },
              child: MensajesZonaInicialListener(
                child: _buildScaffold(context),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_connectionLost) _connectionNotice(compact: true),
                  Expanded(
                    child: constraints.maxWidth > constraints.maxHeight
                        ? Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _TableroMovil(mapa: widget.mapa),
                              ),
                              Expanded(
                                flex: 4,
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
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _TableroMovil(mapa: widget.mapa),
                              ),
                              Expanded(
                                flex: 7,
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
                            ],
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
    );
  }
}

class _TableroMovil extends StatelessWidget {
  const _TableroMovil({required this.mapa});

  final MapaTablero mapa;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              const InstruccionZonaInicial(),
              Expanded(
                child: Center(
                  child: SizedBox.square(
                    dimension: constraints.maxWidth
                        .clamp(1.0, constraints.maxHeight)
                        .toDouble(),
                    child: TableroWidget(mapa: mapa),
                  ),
                ),
              ),
            ],
          );
        },
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
          if (mobile)
            Row(
              children: [
                Expanded(
                  child: Text(
                    multiplayer && room != null
                        ? 'Sala ${room!.code}'
                        : 'Partida',
                    style: const TextStyle(
                      color: TemaMesa.nogal,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: const Key('show-game-history'),
                  tooltip: 'Ver seguimiento de la partida',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final gameBloc = context.read<JuegoBloc>();
                    showDialog<void>(
                      context: context,
                      builder: (context) => BlocProvider.value(
                        value: gameBloc,
                        child: AlertDialog(
                          title: const Text('Registro de Partida'),
                          content: SizedBox(
                            width: 360,
                            height: 260,
                            child: const HistorialPartidaWidget(
                              height: 260,
                              showEmptyMessage: true,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                ),
                IconButton(
                  key: const Key('show-game-scores'),
                  tooltip: 'Ver puntuaciones disponibles',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final gameBloc = context.read<JuegoBloc>();
                    showDialog<void>(
                      context: context,
                      builder: (context) => BlocProvider.value(
                        value: gameBloc,
                        child: AlertDialog(
                          title: const Text('Puntuaciones disponibles'),
                          content: SingleChildScrollView(
                            child: SizedBox(
                              width: 360,
                              child: PuntuacionesDisponiblesWidget(
                                mapa: mapa,
                                horizontal: true,
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
                      ),
                    );
                  },
                  icon: const Icon(Icons.leaderboard_outlined),
                ),
              ],
            ),
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
                    BotonInicio(tablero: tablero, onStart: onStart),
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
    required this.onReturnToLobby,
  });

  final RoomSnapshot room;
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

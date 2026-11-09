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
  });

  final MapaTablero mapa;
  final MultiplayerClient? multiplayerClient;
  final AuthUser? multiplayerUser;
  final String? roomCode;
  final ValueChanged<String>? onRoomLeft;

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
  int? _lastSynchronizedRevision;

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
    try {
      final room = await _multiplayerClient.getRoom(widget.roomCode!);
      if (!mounted) return;
      _synchronizeRoom(room);
      setState(() {
        _room = room;
        _remoteError = null;
      });
    } on MultiplayerApiException catch (error) {
      if (!mounted) return;
      setState(() => _remoteError = error.userMessage);
    } finally {
      _isPolling = false;
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
    await _runRoomAction(
      () => _multiplayerClient.playMove(
        code: room.code,
        anchorDieIndex: anchorDieIndex - 1,
        round: room.round,
        anchorRow: anchorRow,
        anchorColumn: anchorColumn,
        destinationRow: destinationRow,
        destinationColumn: destinationColumn,
      ),
    );
  }

  Future<void> _skipTurn() async {
    final room = _room;
    if (room == null) return;
    await _runRoomAction(
      () => _multiplayerClient.skipRound(code: room.code, round: room.round),
    );
  }

  Future<void> _runRoomAction(Future<RoomSnapshot> Function() action) async {
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
      });
    } on MultiplayerApiException catch (error) {
      if (!mounted) return;
      setState(() => _remoteError = error.userMessage);
      if (error.code == 'STALE_STATE' || error.code == 'STALE_ROUND') {
        await _refreshMultiplayer(force: true);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _leaveMultiplayerGame() async {
    final room = _room;
    if (room == null || _isBusy) return;
    setState(() {
      _isBusy = true;
      _remoteError = null;
    });
    try {
      final result = await _multiplayerClient.leaveRoom(room.code);
      if (!mounted) return;
      _allowPop = true;
      widget.onRoomLeft?.call(
        result.message ??
            (result.dissolved ? 'La sala se cerró.' : 'Saliste de la sala.'),
      );
      Navigator.of(context).maybePop();
    } on MultiplayerApiException catch (error) {
      if (!mounted) return;
      setState(() => _remoteError = error.userMessage);
      if (error.code == 'ROOM_DISSOLVED' || error.code == 'ROOM_NOT_FOUND') {
        _allowPop = true;
        widget.onRoomLeft?.call(error.message);
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        const InstruccionZonaInicial(),
                        const SizedBox(height: 16),
                        _TableroConPuntuaciones(
                          mapa: widget.mapa,
                          altoDisponible: constraints.maxHeight - 100,
                          enVertical: constraints.maxWidth < 600,
                        ),
                        const SizedBox(height: 24),
                        _PanelPartida(
                          tablero: tablero,
                          compacto: true,
                          multiplayer: _isMultiplayer,
                          room: _room,
                          currentUserId: widget.multiplayerUser?.id,
                          isBusy: _isBusy,
                          onStart: _submitInitialBoard,
                          onConfirmMove: _submitMove,
                          onSkipTurn: _skipTurn,
                          errorMessage: _remoteError,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
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
                              altoDisponible: constraints.maxHeight,
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
                      isBusy: _isBusy,
                      onStart: _submitInitialBoard,
                      onConfirmMove: _submitMove,
                      onSkipTurn: _skipTurn,
                      errorMessage: _remoteError,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TableroConPuntuaciones extends StatelessWidget {
  const _TableroConPuntuaciones({
    required this.mapa,
    required this.altoDisponible,
    this.enVertical = false,
  });

  final MapaTablero mapa;
  final double altoDisponible;
  final bool enVertical;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (enVertical) {
          final ladoTablero = constraints.maxWidth
              .clamp(1.0, (altoDisponible * 0.72).clamp(120.0, 560.0))
              .toDouble();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: ladoTablero,
                child: TableroWidget(mapa: mapa),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: constraints.maxWidth,
                child: PuntuacionesDisponiblesWidget(
                  mapa: mapa,
                  horizontal: true,
                ),
              ),
            ],
          );
        }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaMesa.papelClaro,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaMesa.nogal.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (multiplayer && room != null) ...[
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
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              key: const Key('multiplayer-game-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
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
              );
            },
          ),
        ],
      ),
    );
  }
}

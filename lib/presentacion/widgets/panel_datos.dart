import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_event.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../tema_mesa.dart';

class PanelDados extends StatelessWidget {
  const PanelDados({
    super.key,
    this.isEnabled = true,
    this.onSkipTurn,
    this.onConfirmMove,
    this.onNextTurn,
    this.turnMessage,
    this.waitingForRound = false,
    this.skipTurnLabel,
    this.compact = false,
  });

  final bool isEnabled;
  final VoidCallback? onSkipTurn;
  final VoidCallback? onConfirmMove;
  final VoidCallback? onNextTurn;
  final String? turnMessage;
  final bool waitingForRound;
  final String? skipTurnLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, state) {
        final esperandoOtroTurno =
            waitingForRound && state.fase == FaseTurno.turnoTerminado;
        if (state.tableroCompleto) {
          return const Text(
            '¡Tablero completo! La partida ha terminado.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          );
        }

        if (state.dado1 == null || state.dado2 == null) {
          return const SizedBox.shrink();
        }

        String mensaje = '';
        if (state.fase == FaseTurno.seleccionandoAncla) {
          mensaje = 'Elige qué dado será tu ancla:';
        } else if (state.fase == FaseTurno.seleccionandoCasilla) {
          mensaje = 'Toca una casilla amarilla o cambia de dado.';
        } else if (state.fase == FaseTurno.colocandoNumero) {
          mensaje = 'Coloca el número verde.';
        } else if (state.fase == FaseTurno.confirmandoJugada) {
          mensaje = '¿Confirmas colocar el ${state.numeroColocar}?';
        } else if (state.fase == FaseTurno.turnoTerminado) {
          mensaje = state.turnoSaltadoAutomaticamente
              ? 'No hay jugadas válidas con esta tirada. Turno saltado automáticamente.'
              : esperandoOtroTurno
              ? ''
              : '¡Turno terminado!';
        }

        bool permitirCambioDado =
            state.fase == FaseTurno.seleccionandoAncla ||
            state.fase == FaseTurno.seleccionandoCasilla ||
            state.fase == FaseTurno.colocandoNumero;

        return Column(
          children: [
            if (turnMessage != null) ...[
              Text(
                turnMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 13 : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
            ],
            if (mensaje.isNotEmpty) ...[
              Text(
                mensaje,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: compact ? 6 : 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BotonDado(
                  key: const ValueKey('dado-1'),
                  valor: state.dado1!,
                  rollId: state.historial.length,
                  esAncla: state.indiceDadoAncla == 1,
                  esColocar: state.indiceDadoAncla == 2,
                  compacto: compact,
                  onTap: permitirCambioDado && isEnabled
                      ? () => context.read<JuegoBloc>().add(
                          SeleccionarNumeroAncla(
                            numeroElegido: state.dado1!,
                            numeroParaColocar: state.dado2!,
                            indiceDado: 1,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: compact ? 20 : 32),
                _BotonDado(
                  key: const ValueKey('dado-2'),
                  valor: state.dado2!,
                  rollId: state.historial.length,
                  esAncla: state.indiceDadoAncla == 2,
                  esColocar: state.indiceDadoAncla == 1,
                  compacto: compact,
                  onTap: permitirCambioDado && isEnabled
                      ? () => context.read<JuegoBloc>().add(
                          SeleccionarNumeroAncla(
                            numeroElegido: state.dado2!,
                            numeroParaColocar: state.dado1!,
                            indiceDado: 2,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 12),
            // Opción de Saltar Turno durante la fase activa
            if (permitirCambioDado)
              TextButton.icon(
                onPressed: isEnabled
                    ? onSkipTurn ??
                          () => context.read<JuegoBloc>().add(SaltarTurno())
                    : null,
                icon: const Icon(Icons.skip_next, size: 18),
                label: Text(skipTurnLabel ?? 'Saltar Turno'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                  visualDensity: compact
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  padding: compact
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                      : null,
                ),
              ),
            if (state.fase == FaseTurno.confirmandoJugada) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  OutlinedButton(
                    onPressed: isEnabled
                        ? () => context.read<JuegoBloc>().add(
                            CancelarConfirmacion(),
                          )
                        : null,
                    style: compact
                        ? OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: isEnabled
                        ? onConfirmMove ??
                              () => context.read<JuegoBloc>().add(
                                ConfirmarJugada(),
                              )
                        : null,
                    style: compact
                        ? FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                    child: const Text('Confirmar Jugada'),
                  ),
                ],
              ),
            ],
            if (state.fase == FaseTurno.turnoTerminado &&
                !esperandoOtroTurno) ...[
              FilledButton(
                onPressed: isEnabled
                    ? onNextTurn ??
                          () => context.read<JuegoBloc>().add(
                            IniciarTurno(const {}),
                          )
                    : null,
                style: compact
                    ? FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                child: const Text('Siguiente Turno'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BotonDado extends StatefulWidget {
  const _BotonDado({
    super.key,
    required this.valor,
    required this.rollId,
    this.esAncla = false,
    this.esColocar = false,
    this.onTap,
    this.compacto = false,
  });

  final int valor;
  final bool esAncla;
  final bool esColocar;
  final int rollId;
  final VoidCallback? onTap;
  final bool compacto;

  @override
  State<_BotonDado> createState() => _BotonDadoState();
}

class _BotonDadoState extends State<_BotonDado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotacion;
  late final Animation<double> _rebote;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _rotacion = Tween<double>(
      begin: -0.22,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _rebote = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.65,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.18,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _BotonDado oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rollId != oldWidget.rollId) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color colorFondo = TemaMesa.papelClaro;
    Color colorBorde = TemaMesa.nogal;
    Color colorTexto = TemaMesa.nogalOscuro;

    if (widget.esAncla) {
      colorFondo = Colors.yellow.shade100;
      colorBorde = TemaMesa.dorado;
      colorTexto = TemaMesa.nogalOscuro;
    } else if (widget.esColocar) {
      colorFondo = Colors.green.shade100;
      colorBorde = TemaMesa.verde;
      colorTexto = TemaMesa.verde;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: widget.compacto ? 52 : 64,
          height: widget.compacto ? 52 : 64,
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorBorde,
              width: (widget.esAncla || widget.esColocar) ? 4 : 2,
            ),
            boxShadow: [
              if (widget.esAncla || widget.esColocar)
                BoxShadow(
                  color: colorBorde.withAlpha(100),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.valor.toString(),
            style: TextStyle(
              fontSize: widget.compacto ? 26 : 32,
              fontWeight: FontWeight.bold,
              color: colorTexto,
            ),
          ),
        ),
      ),
      builder: (context, child) => RotationTransition(
        turns: _rotacion,
        child: ScaleTransition(scale: _rebote, child: child),
      ),
    );
  }
}

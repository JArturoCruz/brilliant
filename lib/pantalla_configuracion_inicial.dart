import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/zona_inicial_cubit.dart';
import 'tablero.dart';
import 'tablero_widget.dart';
import 'zona_inicial.dart';

/// Pantalla de configuración inicial: el ZonaInicialCubit vive solo aquí
/// (estado local) y se descarta al salir de esta pantalla.
class PantallaConfiguracionInicial extends StatefulWidget {
  const PantallaConfiguracionInicial({super.key});

  @override
  State<PantallaConfiguracionInicial> createState() =>
      _PantallaConfiguracionInicialState();
}

class _PantallaConfiguracionInicialState
    extends State<PantallaConfiguracionInicial> {
  final TableroJuego tablero = TableroJuego();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ZonaInicialCubit(),
      child: _AtajosTeclado(
        child: _MensajesAlUsuario(
          child: Scaffold(
          appBar: AppBar(title: const Text('Brilliant')),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Instruccion(),
                      const SizedBox(height: 16),
                      const TableroWidget(),
                      const SizedBox(height: 20),
                      const _SelectorNumeros(),
                      const SizedBox(height: 20),
                      _BotonInicio(tablero: tablero),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Muestra en un SnackBar los avisos que emite el cubit (p. ej. al intentar
/// repetir un número). Funciona igual con mouse, botones y teclado.
class _MensajesAlUsuario extends StatelessWidget {
  final Widget child;

  const _MensajesAlUsuario({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ZonaInicialCubit, ZonaInicialState>(
      listenWhen: (previo, actual) =>
          actual.mensajeId != previo.mensajeId && actual.mensaje != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.mensaje!),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
      },
      child: child,
    );
  }
}

/// Traduce el teclado a llamadas al cubit:
///  - 1 a 6 (fila superior o teclado numérico): coloca el número.
///  - Backspace / Delete: borra la casilla seleccionada.
///  - Flechas: mueven la selección entre las 6 casillas señaladas.
class _AtajosTeclado extends StatelessWidget {
  final Widget child;

  const _AtajosTeclado({required this.child});

  static const _digitos = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];

  static const _numpad = [
    LogicalKeyboardKey.numpad1,
    LogicalKeyboardKey.numpad2,
    LogicalKeyboardKey.numpad3,
    LogicalKeyboardKey.numpad4,
    LogicalKeyboardKey.numpad5,
    LogicalKeyboardKey.numpad6,
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ZonaInicialCubit>();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        for (var i = 0; i < 6; i++) ...{
          SingleActivator(_digitos[i]): () => cubit.asignarASeleccionada(i + 1),
          SingleActivator(_numpad[i]): () => cubit.asignarASeleccionada(i + 1),
        },
        const SingleActivator(LogicalKeyboardKey.backspace):
            cubit.borrarSeleccionada,
        const SingleActivator(LogicalKeyboardKey.delete):
            cubit.borrarSeleccionada,
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            cubit.moverSeleccion(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            cubit.moverSeleccion(1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            cubit.moverSeleccion(-1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            cubit.moverSeleccion(-1),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

class _Instruccion extends StatelessWidget {
  const _Instruccion();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
      builder: (context, state) {
        final texto = state.iniciada
            ? '¡Configuración lista!'
            : 'Toca una casilla señalada y coloca los números del 1 al 6 '
                'sin repetir (${state.cantidadLlenas}/'
                '${ZonaInicial.cantidadCeldas})';
        return Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        );
      },
    );
  }
}

class _SelectorNumeros extends StatelessWidget {
  const _SelectorNumeros();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
      builder: (context, state) {
        final cubit = context.read<ZonaInicialCubit>();
        final sel = state.seleccionada;
        final hayCelda = sel != null && !state.iniciada;
        final valorSel = sel == null ? null : state.valores[sel];
        final numeros = ZonaInicial.valoresRequeridos.toList()..sort();

        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in numeros)
              _BotonNumero(
                numero: n,
                marcado: valorSel == n,
                habilitado: hayCelda,
                usadoEnOtra: state.usados.contains(n) && valorSel != n,
                onPressed: () => cubit.asignarASeleccionada(n),
              ),
            IconButton.outlined(
              tooltip: 'Borrar casilla',
              onPressed: hayCelda && valorSel != null
                  ? cubit.borrarSeleccionada
                  : null,
              icon: const Icon(Icons.backspace_outlined),
            ),
          ],
        );
      },
    );
  }
}

class _BotonNumero extends StatelessWidget {
  final int numero;
  final bool marcado;
  final bool habilitado;
  final bool usadoEnOtra;
  final VoidCallback onPressed;

  const _BotonNumero({
    required this.numero,
    required this.marcado,
    required this.habilitado,
    required this.usadoEnOtra,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final estilo = ButtonStyle(
      padding: WidgetStateProperty.all(EdgeInsets.zero),
      minimumSize: WidgetStateProperty.all(const Size(52, 52)),
      // Atenuado si ya está en otra casilla, pero sigue tocable (avisa).
      foregroundColor: usadoEnOtra
          ? WidgetStateProperty.all(Theme.of(context).disabledColor)
          : null,
    );
    final hijo = Text('$numero', style: const TextStyle(fontSize: 20));
    final callback = habilitado ? onPressed : null;

    return SizedBox(
      width: 52,
      height: 52,
      child: marcado
          ? FilledButton(onPressed: callback, style: estilo, child: hijo)
          : OutlinedButton(onPressed: callback, style: estilo, child: hijo),
    );
  }
}

class _BotonInicio extends StatelessWidget {
  final TableroJuego tablero;

  const _BotonInicio({required this.tablero});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            // Deshabilitado hasta que las 6 celdas sean válidas.
            onPressed: state.esValida && !state.iniciada
                ? () => context.read<ZonaInicialCubit>().aplicarATablero(tablero)
                : null,
            child: const Text('Inicio', style: TextStyle(fontSize: 18)),
          ),
        );
      },
    );
  }
}
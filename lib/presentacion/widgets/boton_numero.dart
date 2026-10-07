import 'package:flutter/material.dart';

/// Botón reutilizable para un solo dígito (1-6) del selector. No conoce el
/// Cubit ni las reglas del juego: solo recibe su estado visual y notifica
/// toques.
class BotonNumero extends StatelessWidget {
  const BotonNumero({
    super.key,
    required this.numero,
    required this.marcado,
    required this.habilitado,
    required this.usadoEnOtraCelda,
    required this.onPressed,
  });

  final int numero;
  final bool marcado;
  final bool habilitado;
  final bool usadoEnOtraCelda;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final estilo = ButtonStyle(
      padding: WidgetStateProperty.all(EdgeInsets.zero),
      minimumSize: WidgetStateProperty.all(const Size(52, 52)),
      // Atenuado si ya está en otra casilla, pero sigue tocable (avisa).
      foregroundColor: usadoEnOtraCelda
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

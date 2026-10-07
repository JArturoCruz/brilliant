import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/zona_inicial_cubit.dart';
import '../../dominio/zona_inicial.dart';
import 'boton_numero.dart';

/// Fila de botones del 1 al 6 más el borrador. Su única responsabilidad es
/// traducir los toques del usuario en llamadas al Cubit para la celda
/// seleccionada; no decide si un número se repite (eso lo resuelve el
/// Cubit y se refleja en el estado).
class SelectorNumerosZonaInicial extends StatelessWidget {
  const SelectorNumerosZonaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
      builder: (context, state) {
        final cubit = context.read<ZonaInicialCubit>();
        final sel = state.seleccionada;
        final hayCeldaEditable = sel != null && !state.iniciada;
        final valorSel = sel == null ? null : state.valores[sel];
        final numeros = ZonaInicial.valoresRequeridos.toList()..sort();

        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in numeros)
              BotonNumero(
                numero: n,
                marcado: valorSel == n,
                habilitado: hayCeldaEditable,
                usadoEnOtraCelda: state.usados.contains(n) && valorSel != n,
                onPressed: () => cubit.asignarASeleccionada(n),
              ),
            IconButton.outlined(
              tooltip: 'Borrar casilla',
              onPressed: hayCeldaEditable && valorSel != null
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

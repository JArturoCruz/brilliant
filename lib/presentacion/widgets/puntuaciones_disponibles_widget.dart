import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PuntuacionesDisponiblesWidget extends StatelessWidget {
  const PuntuacionesDisponiblesWidget({super.key, required this.mapa});

  final MapaTablero mapa;

  @override
  Widget build(BuildContext context) {
    final grupos = _gruposDePuntuacion();

    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Puntuaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 12,
                children: [
                  for (final grupo in grupos)
                    _PuntuacionGrupo(
                      grupo: grupo,
                      posicionesConsumidas:
                          state.contadorCompletadasPorRegion[mapa
                              .claveGrupoPuntuacion(grupo.region)] ??
                          0,
                      mapa: mapa,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<_GrupoPuntuacion> _gruposDePuntuacion() {
    final gruposPorTipo = <String, _GrupoPuntuacion>{};
    for (final entrada in mapa.coordenadasPorRegion.entries) {
      if (entrada.value.isEmpty ||
          !mapa.puntuacionesPorRegion.containsKey(entrada.key)) {
        continue;
      }

      final tipo = mapa.tipoDe(entrada.key);
      final clave = tipo.runtimeType.toString();
      gruposPorTipo.putIfAbsent(
        clave,
        () => _GrupoPuntuacion(region: entrada.key, color: tipo.color),
      );
    }
    return gruposPorTipo.values.toList();
  }
}

class _PuntuacionGrupo extends StatelessWidget {
  const _PuntuacionGrupo({
    required this.grupo,
    required this.posicionesConsumidas,
    required this.mapa,
  });

  final _GrupoPuntuacion grupo;
  final int posicionesConsumidas;
  final MapaTablero mapa;

  @override
  Widget build(BuildContext context) {
    final colorTexto = grupo.color == Colors.white
        ? Colors.black
        : Colors.white;
    final puntuaciones = List.generate(
      3,
      (index) => mapa.puntosPorPosicion(grupo.region, index + 1),
    );

    return SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: grupo.region.name,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: grupo.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30),
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (var index = 0; index < puntuaciones.length; index++)
            Text(
              '${puntuaciones[index]}',
              key: ValueKey('puntuacion-${grupo.region.name}-${index + 1}'),
              style: TextStyle(
                color: index < posicionesConsumidas
                    ? Colors.grey.shade700
                    : Colors.amberAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: index < posicionesConsumidas
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: colorTexto.withAlpha(100),
                shadows: index < posicionesConsumidas
                    ? null
                    : [const Shadow(color: Colors.amber, blurRadius: 8)],
              ),
            ),
        ],
      ),
    );
  }
}

class _GrupoPuntuacion {
  const _GrupoPuntuacion({required this.region, required this.color});

  final RegionTablero region;
  final Color color;
}

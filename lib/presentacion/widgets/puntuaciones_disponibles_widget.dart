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
          padding: const EdgeInsets.all(8),
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
              const SizedBox(height: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final grupo in grupos)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: _PuntuacionGrupo(
                        grupo: grupo,
                        posicionesConsumidas:
                            state.contadorCompletadasPorRegion[mapa
                                .claveGrupoPuntuacion(grupo.region)] ??
                            0,
                        mapa: mapa,
                      ),
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
    final grupos = <_GrupoPuntuacion>[];
    for (final entrada in mapa.coordenadasPorRegion.entries) {
      if (entrada.value.isEmpty ||
          !mapa.puntuacionesPorRegion.containsKey(entrada.key)) {
        continue;
      }

      final tipo = mapa.tipoDe(entrada.key);
      grupos.add(
        _GrupoPuntuacion(
          region: entrada.key,
          color: tipo.color,
          etiqueta: _etiquetaZona(entrada.key),
        ),
      );
    }
    return grupos;
  }

  String _etiquetaZona(RegionTablero region) {
    return switch ((mapa.id, region)) {
      (1, RegionTablero.amarilla) => 'Amarillo',
      (1, RegionTablero.verde1) => 'Verde izq.',
      (1, RegionTablero.verde2) => 'Verde der.',
      (1, RegionTablero.azul1) => 'Azul arriba',
      (1, RegionTablero.azul2) => 'Azul abajo',
      (1, RegionTablero.morada1) => 'Morado arriba',
      (1, RegionTablero.morada2) => 'Morado izq.',
      (1, RegionTablero.roja1) => 'Rojo izq.',
      (1, RegionTablero.roja2) => 'Rojo der.',
      (2, RegionTablero.amarilla) => 'Amarillo',
      (2, RegionTablero.verde1) => 'Verde der.',
      (2, RegionTablero.verde2) => 'Verde izq.',
      (2, RegionTablero.azul1) => 'Azul arriba',
      (2, RegionTablero.azul2) => 'Azul abajo',
      (2, RegionTablero.morada1) => 'Morado izq.',
      (2, RegionTablero.morada2) => 'Morado der.',
      (2, RegionTablero.roja1) => 'Rojo izq.',
      (2, RegionTablero.roja2) => 'Rojo der.',
      (2, RegionTablero.blanca) => 'Blanco',
      (3, RegionTablero.amarilla) => 'Amarillo',
      (3, RegionTablero.verde1) => 'Verde abajo',
      (3, RegionTablero.azul1) => 'Azul centro',
      (3, RegionTablero.morada1) => 'Morado arriba',
      (3, RegionTablero.morada2) => 'Morado abajo',
      (3, RegionTablero.roja1) => 'Rojo izq.',
      (3, RegionTablero.roja2) => 'Rojo der.',
      (3, RegionTablero.blanca) => 'Blanco',
      (4, RegionTablero.amarilla) => 'Amarillo',
      (4, RegionTablero.verde1) => 'Verde',
      (4, RegionTablero.azul1) => 'Azul izq.',
      (4, RegionTablero.azul2) => 'Azul der.',
      (4, RegionTablero.morada1) => 'Morado centro',
      (4, RegionTablero.roja1) => 'Rojo izq.',
      (4, RegionTablero.roja2) => 'Rojo der.',
      (4, RegionTablero.naranjaSuperior) => 'Naranja arriba',
      (4, RegionTablero.naranjaInferior) => 'Naranja abajo',
      _ => region.name,
    };
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

    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: grupo.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white30),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Tooltip(
            message: grupo.etiqueta,
            child: Text(
              grupo.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 3),
        for (var index = 0; index < puntuaciones.length; index++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '${puntuaciones[index]}',
              key: ValueKey('puntuacion-${grupo.region.name}-${index + 1}'),
              style: TextStyle(
                color: index < posicionesConsumidas
                    ? Colors.grey.shade700
                    : Colors.amberAccent,
                fontSize: 11,
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
          ),
      ],
    );
  }
}

class _GrupoPuntuacion {
  const _GrupoPuntuacion({
    required this.region,
    required this.color,
    required this.etiqueta,
  });

  final RegionTablero region;
  final Color color;
  final String etiqueta;
}

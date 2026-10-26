import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/region.dart';
import 'package:brilliant/dominio/tipos/tipo_amarillo.dart';
import 'package:brilliant/dominio/tipos/tipo_azul.dart';
import 'package:brilliant/dominio/tipos/tipo_blanco.dart';
import 'package:brilliant/dominio/tipos/tipo_morado.dart';
import 'package:brilliant/dominio/tipos/tipo_naranja.dart';
import 'package:brilliant/dominio/tipos/tipo_rojo.dart';
import 'package:brilliant/dominio/tipos/tipo_verde.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PuntuacionesDisponiblesWidget extends StatelessWidget {
  const PuntuacionesDisponiblesWidget({
    super.key,
    required this.mapa,
    this.horizontal = false,
  });

  final MapaTablero mapa;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final grupos = _gruposDePuntuacion();

    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final escala = (constraints.maxWidth / 150)
                .clamp(0.7, 1.0)
                .toDouble();
            final compacto = horizontal || constraints.maxWidth < 145;

            return Container(
              padding: EdgeInsets.all(8 * escala),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Puntuaciones',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14 * escala,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8 * escala),
                  if (horizontal)
                    LayoutBuilder(
                      builder: (context, rowConstraints) {
                        const spacing = 4.0;
                        final itemWidth =
                            (rowConstraints.maxWidth - spacing * 2) / 3;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: 4 * escala,
                          children: [
                            for (final grupo in grupos)
                              SizedBox(
                                width: itemWidth,
                                child: _PuntuacionGrupo(
                                  grupo: grupo,
                                  posicionesConsumidas:
                                      state.contadorCompletadasPorRegion[mapa
                                          .claveGrupoPuntuacion(
                                            grupo.region,
                                          )] ??
                                      0,
                                  mapa: mapa,
                                  compacto: true,
                                  escala: escala,
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  else
                    for (final grupo in grupos)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 3 * escala),
                        child: _PuntuacionGrupo(
                          grupo: grupo,
                          posicionesConsumidas:
                              state.contadorCompletadasPorRegion[mapa
                                  .claveGrupoPuntuacion(grupo.region)] ??
                              0,
                          mapa: mapa,
                          compacto: compacto,
                          escala: escala,
                        ),
                      ),
                ],
              ),
            );
          },
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
    required this.compacto,
    required this.escala,
  });

  final _GrupoPuntuacion grupo;
  final int posicionesConsumidas;
  final MapaTablero mapa;
  final bool compacto;
  final double escala;

  String get simboloRegla {
    final tipo = mapa.tipoDe(grupo.region);
    if (tipo is TipoBlanco) return '=';
    if (tipo is TipoNaranja) {
      return '${tipo.numeroMinimo}-${tipo.numeroMaximo}';
    }
    if (tipo is TipoAzul) return '=';
    if (tipo is TipoVerde) return '?';
    if (tipo is TipoRojo || tipo is TipoAmarillo) return '≠';
    if (tipo is TipoMorado) return 'XO';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colorTexto = grupo.color == Colors.white
        ? Colors.black
        : Colors.white;
    final puntuaciones = List.generate(
      3,
      (index) => mapa.puntosPorPosicion(grupo.region, index + 1),
    );

    final identificadorZona = Row(
      children: [
        Container(
          key: ValueKey('regla-${grupo.region.name}'),
          width: (compacto ? 24 : 20) * escala,
          height: (compacto ? 19 : 20) * escala,
          decoration: BoxDecoration(
            color: grupo.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white30),
          ),
          alignment: Alignment.center,
          child: Text(
            simboloRegla,
            key: ValueKey('regla-simbolo-${grupo.region.name}'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: grupo.color.computeLuminance() > 0.5
                  ? Colors.black.withAlpha(170)
                  : Colors.white.withAlpha(190),
              fontSize: (simboloRegla.length > 1 ? 7 : 10) * escala,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 4 * escala),
        Expanded(
          child: Tooltip(
            message: grupo.etiqueta,
            child: Text(
              grupo.etiqueta,
              maxLines: 1,
              overflow: compacto ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9 * escala,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
    final puntos = Row(
      mainAxisAlignment: compacto
          ? MainAxisAlignment.center
          : MainAxisAlignment.end,
      mainAxisSize: compacto ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var index = 0; index < puntuaciones.length; index++)
          Padding(
            padding: EdgeInsets.only(left: 3 * escala),
            child: Text(
              '${puntuaciones[index]}',
              key: ValueKey('puntuacion-${grupo.region.name}-${index + 1}'),
              style: TextStyle(
                color: index < posicionesConsumidas
                    ? Colors.grey.shade700
                    : Colors.amberAccent,
                fontSize: 11 * escala,
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

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          identificadorZona,
          SizedBox(height: 1 * escala),
          puntos,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: identificadorZona),
        SizedBox(width: 3 * escala),
        puntos,
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

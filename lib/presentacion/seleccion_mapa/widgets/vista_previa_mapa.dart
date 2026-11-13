import 'package:flutter/material.dart';

import '../../../dominio/mapa_tablero.dart';
import '../../../dominio/posicion.dart';
import '../../../dominio/region.dart';
import '../../../dominio/topologia_tablero.dart';
import '../../../dominio/zona_inicial.dart';
import '../../tema_mesa.dart';

class VistaPreviaMapa extends StatelessWidget {
  const VistaPreviaMapa({required this.mapa, this.valores, super.key});

  final MapaTablero mapa;
  final List<List<int?>>? valores;

  @override
  Widget build(BuildContext context) {
    final posicionesIniciales = ZonaInicial.posicionesParaMapa(mapa).toSet();

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: TemaMesa.nogal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TemaMesa.nogalOscuro, width: 2),
        ),
        child: Column(
          children: [
            for (var fila = 0; fila < TopologiaTablero.filas; fila++)
              Expanded(
                child: Row(
                  children: [
                    for (
                      var columna = 0;
                      columna < TopologiaTablero.columnas;
                      columna++
                    )
                      Expanded(
                        child: _CeldaPrevia(
                          mapa: mapa,
                          posicion: Posicion(fila, columna),
                          esInicial: posicionesIniciales.contains(
                            Posicion(fila, columna),
                          ),
                          valor: valores?[fila][columna],
                          mostrarInicial: valores == null,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CeldaPrevia extends StatelessWidget {
  const _CeldaPrevia({
    required this.mapa,
    required this.posicion,
    required this.esInicial,
    required this.valor,
    required this.mostrarInicial,
  });

  final MapaTablero mapa;
  final Posicion posicion;
  final bool esInicial;
  final int? valor;
  final bool mostrarInicial;

  @override
  Widget build(BuildContext context) {
    final region = TopologiaTablero.regionDeCelda(
      posicion.fila,
      posicion.columna,
      mapa: mapa,
    );
    final color = region == null
        ? TemaMesa.papel.withAlpha(120)
        : Color.lerp(mapa.tipoDe(region).color, TemaMesa.papel, 0.16)!;
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: region == RegionTablero.blanca
            ? Border.all(color: TemaMesa.nogal.withAlpha(90), width: 0.5)
            : null,
      ),
      child: valor != null
          ? FittedBox(
              child: Text(
                '$valor',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            )
          : esInicial && mostrarInicial
          ? Center(
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: TemaMesa.papelClaro,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: TemaMesa.nogal, blurRadius: 1)],
                ),
              ),
            )
          : null,
    );
  }
}

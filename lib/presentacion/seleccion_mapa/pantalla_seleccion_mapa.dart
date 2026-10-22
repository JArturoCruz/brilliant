import 'package:flutter/material.dart';

import '../../dominio/mapa_tablero.dart';
import '../pantalla_juego.dart';
import 'widgets/tarjeta_mapa.dart';

class PantallaSeleccionMapa extends StatelessWidget {
  const PantallaSeleccionMapa({super.key});

  @override
  Widget build(BuildContext context) {
    final mapas = [
      _MapaDisponible.disponible(
        mapa: MapaTablero.mapa1,
        descripcion: 'Disponible',
      ),
      _MapaDisponible.disponible(
        mapa: MapaTablero.mapa2,
        descripcion: 'Disponible',
      ),
      _MapaDisponible.disponible(
        mapa: MapaTablero.mapa3,
        descripcion: 'Disponible',
      ),
      _MapaDisponible.disponible(
        mapa: MapaTablero.mapa4,
        descripcion: 'Disponible',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un mapa')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 2 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.4,
              children: [
                for (final mapa in mapas)
                  TarjetaMapa(
                    nombre: mapa.nombre,
                    descripcion: mapa.descripcion,
                    disponible: mapa.disponible,
                    onTap: mapa.disponible
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PantallaJuego(mapa: mapa.mapa!),
                              ),
                            );
                          }
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapaDisponible {
  const _MapaDisponible({
    required this.nombre,
    required this.descripcion,
  }) : mapa = null,
       disponible = false;

  _MapaDisponible.disponible({
    required MapaTablero mapa,
    required this.descripcion,
  }) : mapa = mapa,
       nombre = mapa.nombre,
       disponible = true;

  final MapaTablero? mapa;
  final String nombre;
  final String descripcion;
  final bool disponible;
}

import 'package:flutter/material.dart';

import '../pantalla_juego.dart';
import 'widgets/tarjeta_mapa.dart';

class PantallaSeleccionMapa extends StatelessWidget {
  const PantallaSeleccionMapa({super.key});

  @override
  Widget build(BuildContext context) {
    final mapas = [
      _MapaDisponible(
        nombre: 'Mapa 1',
        descripcion: 'Disponible',
        disponible: true,
      ),
      _MapaDisponible(nombre: 'Mapa 2', descripcion: 'Próximamente'),
      _MapaDisponible(nombre: 'Mapa 3', descripcion: 'Próximamente'),
      _MapaDisponible(nombre: 'Mapa 4', descripcion: 'Próximamente'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un mapa')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount:
                  MediaQuery.sizeOf(context).width >= 600 ? 2 : 1,
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
                                builder: (_) => const PantallaJuego(),
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
    this.disponible = false,
  });

  final String nombre;
  final String descripcion;
  final bool disponible;
}

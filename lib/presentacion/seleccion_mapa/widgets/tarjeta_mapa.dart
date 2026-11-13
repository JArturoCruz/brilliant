import 'package:flutter/material.dart';

import '../../../dominio/mapa_tablero.dart';
import '../../tema_mesa.dart';
import 'vista_previa_mapa.dart';

class TarjetaMapa extends StatelessWidget {
  const TarjetaMapa({
    super.key,
    required this.mapa,
    required this.nombre,
    required this.descripcion,
    required this.disponible,
    required this.onTap,
  });

  final MapaTablero mapa;
  final String nombre;
  final String descripcion;
  final bool disponible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = disponible ? TemaMesa.verde : Colors.grey;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 104, child: VistaPreviaMapa(mapa: mapa)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map_outlined, color: color, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: disponible ? null : Colors.grey,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (descripcion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: color),
                      ),
                    ],
                  ],
                ),
              ),
              if (disponible)
                const Icon(Icons.chevron_right, color: TemaMesa.nogal),
            ],
          ),
        ),
      ),
    );
  }
}

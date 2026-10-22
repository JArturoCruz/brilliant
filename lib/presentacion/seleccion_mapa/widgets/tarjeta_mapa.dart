import 'package:flutter/material.dart';

class TarjetaMapa extends StatelessWidget {
  const TarjetaMapa({
    super.key,
    required this.nombre,
    required this.descripcion,
    required this.disponible,
    required this.onTap,
  });

  final String nombre;
  final String descripcion;
  final bool disponible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = disponible ? Colors.amber : Colors.grey;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                disponible ? Icons.map_outlined : Icons.lock_outline,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: disponible ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              if (disponible)
                const Icon(Icons.chevron_right, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

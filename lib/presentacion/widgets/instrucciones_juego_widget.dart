import 'package:flutter/material.dart';

class InstruccionesJuegoWidget extends StatelessWidget {
  const InstruccionesJuegoWidget({super.key});

  static const _puntuacionesPorMapa = <String, List<String>>{
    'Mapa 1': [
      'Azules: 7, 5, 3 puntos por zona.',
      'Verdes: 4, 3, 2 puntos por zona.',
      'Rojas: 6, 4, 2 puntos por zona.',
      'Moradas: 6, 4, 2 puntos por zona.',
      'Amarilla: 8, 6, 4 puntos.',
    ],
    'Mapa 2': [
      'Azules: 7, 5, 3 puntos por zona.',
      'Verdes: 4, 3, 2 puntos por zona.',
      'Rojas y moradas: 6, 4, 2 puntos por zona.',
      'Amarilla: 6, 4, 2 puntos.',
      'Blancas (una sola zona): 3, 2, 1 punto.',
    ],
    'Mapa 3': [
      'Azul: 7, 5, 3 puntos.',
      'Moradas (cuentan como una zona): 7, 5, 3 puntos.',
      'Rojas: 6, 4, 2 puntos por zona.',
      'Amarilla: 7, 5, 3 puntos.',
      'Verde: 6, 5, 4 puntos.',
      'Blancas (una sola zona): 8, 6, 4 puntos.',
    ],
    'Mapa 4': [
      'Morada: 7, 5, 3 puntos.',
      'Azules: 8, 6, 4 puntos por zona.',
      'Rojas: 6, 4, 2 puntos por zona.',
      'Naranjas: 6, 4, 3 puntos por zona.',
      'Amarilla: 8, 6, 4 puntos.',
      'Verde: 3, 2, 1 punto.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cómo jugar', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const _Instruccion(
              icon: Icons.looks_one_outlined,
              texto:
                  'Cada mapa tiene 6 casillas iniciales señaladas. Llénalas '
                  'con los números del 1 al 6, sin repetir y respetando la '
                  'regla de cada zona. Luego pulsa Inicio.',
            ),
            const _Instruccion(
              icon: Icons.casino_outlined,
              texto:
                  'En cada turno se lanzan dos dados. Elige un dado como '
                  'ancla y selecciona una casilla ocupada con ese número. '
                  'Coloca el valor del otro dado en una casilla vacía '
                  'adyacente (arriba, abajo, izquierda o derecha), respetando '
                  'la regla de su zona.',
            ),
            const _Instruccion(
              icon: Icons.check_circle_outline,
              texto:
                  'Confirma la jugada para colocar el número. Puedes cambiar '
                  'el dado elegido durante la selección o saltar el turno.',
            ),
            const SizedBox(height: 16),
            Text('Reglas de las zonas', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            const _ReglaZona(
              color: Color(0xFF2196F3),
              nombre: 'Azul',
              regla: 'Todos los números deben ser iguales.',
            ),
            const _ReglaZona(
              color: Color(0xFF4CAF50),
              nombre: 'Verde',
              regla: 'Se permite cualquier número.',
            ),
            const _ReglaZona(
              color: Color(0xFFF44336),
              nombre: 'Roja',
              regla: 'Todos los números deben ser distintos.',
            ),
            const _ReglaZona(
              color: Color(0xFF9C27B0),
              nombre: 'Morada',
              regla:
                  'Puede tener como máximo dos valores distintos y, al '
                  'completarse, debe tener al menos dos.',
            ),
            const _ReglaZona(
              color: Color(0xFFFFC107),
              nombre: 'Amarilla',
              regla: 'Todos los números deben ser distintos.',
            ),
            const _ReglaZona(
              color: Colors.white,
              nombre: 'Blanca',
              regla:
                  'Todos los números deben ser iguales. Las casillas blancas '
                  'separadas cuentan como una sola zona.',
            ),
            const _ReglaZona(
              color: Color(0xFFFF9800),
              nombre: 'Naranja (Mapa 4)',
              regla:
                  'La zona superior admite 4–6 y la inferior 1–3; se pueden '
                  'repetir.',
            ),
            const SizedBox(height: 16),
            Text('Cómo se puntúa', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Instruccion(
              icon: Icons.emoji_events_outlined,
              texto:
                  'Los tres primeros jugadores que completen una zona reciben '
                  'los puntos del 1.º, 2.º y 3.º lugar. Desde el cuarto '
                  'jugador no se obtienen puntos por esa zona. Cada zona '
                  'puntúa independientemente, incluso si comparte color con '
                  'otra. Las excepciones son las zonas amarillas o blancas '
                  'separadas que el mapa considera una sola zona.',
            ),
            for (final entrada in _puntuacionesPorMapa.entries)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(entrada.key),
                subtitle: const Text('Puntos para el 1.º, 2.º y 3.º lugar'),
                children: [
                  for (final linea in entrada.value)
                    ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.only(left: 16),
                      title: Text(linea),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Instruccion extends StatelessWidget {
  const _Instruccion({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _ReglaZona extends StatelessWidget {
  const _ReglaZona({
    required this.color,
    required this.nombre,
    required this.regla,
  });

  final Color color;
  final String nombre;
  final String regla;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$nombre: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: regla),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

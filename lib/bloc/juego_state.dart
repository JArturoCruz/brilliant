import 'package:brilliant/dominio/casilla.dart';

// Agregamos turnoTerminado
enum FaseTurno { inicio, seleccionandoAncla, seleccionandoCasilla, colocandoNumero, turnoTerminado }

class JuegoState {
  final List<List<Casilla>> tablero; 
  final FaseTurno fase;
  final int? dado1;
  final int? dado2;
  final int? numeroAncla;
  final int? numeroColocar;
  final int? indiceDadoAncla; // NUEVO: Para saber qué dado se eligió como ancla

  JuegoState({
    required this.tablero,
    this.fase = FaseTurno.inicio,
    this.dado1,
    this.dado2,
    this.numeroAncla,
    this.numeroColocar,
    this.indiceDadoAncla,
  });

  JuegoState copyWith({
    List<List<Casilla>>? tablero,
    FaseTurno? fase,
    int? dado1,
    int? dado2,
    int? numeroAncla,
    int? numeroColocar,
    int? indiceDadoAncla,
  }) {
    return JuegoState(
      tablero: tablero ?? this.tablero,
      fase: fase ?? this.fase,
      dado1: dado1 ?? this.dado1,
      dado2: dado2 ?? this.dado2,
      numeroAncla: numeroAncla ?? this.numeroAncla,
      numeroColocar: numeroColocar ?? this.numeroColocar,
      indiceDadoAncla: indiceDadoAncla ?? this.indiceDadoAncla,
    );
  }
}
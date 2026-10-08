import 'package:brilliant/dominio/casilla.dart';

enum FaseTurno { 
  inicio, 
  seleccionandoAncla, 
  seleccionandoCasilla, 
  colocandoNumero, 
  confirmandoJugada, 
  turnoTerminado 
}

class JuegoState {
  final List<List<Casilla>> tablero; 
  final FaseTurno fase;
  final int? dado1;
  final int? dado2;
  final int? numeroAncla;
  final int? numeroColocar;
  final int? indiceDadoAncla;
  final int? filaProvisional;
  final int? columnaProvisional;
  final int? filaAncla;
  final int? columnaAncla;
  
  final int puntuacionTotal;
  final Set<dynamic> regionesCompletadas;
  final Map<String, int> contadorCompletadasPorTipo;
  
  final List<String> historial; // NUEVO: Registro de eventos de la partida

  JuegoState({
    required this.tablero,
    this.fase = FaseTurno.inicio,
    this.dado1,
    this.dado2,
    this.numeroAncla,
    this.numeroColocar,
    this.indiceDadoAncla,
    this.filaProvisional,
    this.columnaProvisional,
    this.filaAncla,
    this.columnaAncla,
    this.puntuacionTotal = 0,
    this.regionesCompletadas = const {},
    this.contadorCompletadasPorTipo = const {},
    this.historial = const [],
  });

  JuegoState copyWith({
    List<List<Casilla>>? tablero,
    FaseTurno? fase,
    int? dado1,
    int? dado2,
    int? numeroAncla,
    int? numeroColocar,
    int? indiceDadoAncla,
    int? filaProvisional,
    int? columnaProvisional,
    int? filaAncla,
    int? columnaAncla,
    int? puntuacionTotal,
    Set<dynamic>? regionesCompletadas,
    Map<String, int>? contadorCompletadasPorTipo,
    List<String>? historial,
  }) {
    return JuegoState(
      tablero: tablero ?? this.tablero,
      fase: fase ?? this.fase,
      dado1: dado1 ?? this.dado1,
      dado2: dado2 ?? this.dado2,
      numeroAncla: numeroAncla ?? this.numeroAncla,
      numeroColocar: numeroColocar ?? this.numeroColocar,
      indiceDadoAncla: indiceDadoAncla ?? this.indiceDadoAncla,
      filaProvisional: filaProvisional ?? this.filaProvisional,
      columnaProvisional: columnaProvisional ?? this.columnaProvisional,
      filaAncla: filaAncla ?? this.filaAncla,
      columnaAncla: columnaAncla ?? this.columnaAncla,
      puntuacionTotal: puntuacionTotal ?? this.puntuacionTotal,
      regionesCompletadas: regionesCompletadas ?? this.regionesCompletadas,
      contadorCompletadasPorTipo: contadorCompletadasPorTipo ?? this.contadorCompletadasPorTipo,
      historial: historial ?? this.historial,
    );
  }
}
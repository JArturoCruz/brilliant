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
  static const Object _sentinel = Object();

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
  final Map<String, int> contadorCompletadasPorRegion;
  
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
    this.contadorCompletadasPorRegion = const {},
    this.historial = const [],
  });

  JuegoState copyWith({
    Object? tablero = _sentinel,
    Object? fase = _sentinel,
    Object? dado1 = _sentinel,
    Object? dado2 = _sentinel,
    Object? numeroAncla = _sentinel,
    Object? numeroColocar = _sentinel,
    Object? indiceDadoAncla = _sentinel,
    Object? filaProvisional = _sentinel,
    Object? columnaProvisional = _sentinel,
    Object? filaAncla = _sentinel,
    Object? columnaAncla = _sentinel,
    Object? puntuacionTotal = _sentinel,
    Object? regionesCompletadas = _sentinel,
    Object? contadorCompletadasPorRegion = _sentinel,
    Object? historial = _sentinel,
  }) {
    return JuegoState(
      tablero: tablero == _sentinel ? this.tablero : tablero as List<List<Casilla>>,
      fase: fase == _sentinel ? this.fase : fase as FaseTurno,
      dado1: dado1 == _sentinel ? this.dado1 : dado1 as int?,
      dado2: dado2 == _sentinel ? this.dado2 : dado2 as int?,
      numeroAncla: numeroAncla == _sentinel ? this.numeroAncla : numeroAncla as int?,
      numeroColocar: numeroColocar == _sentinel ? this.numeroColocar : numeroColocar as int?,
      indiceDadoAncla: indiceDadoAncla == _sentinel ? this.indiceDadoAncla : indiceDadoAncla as int?,
      filaProvisional: filaProvisional == _sentinel ? this.filaProvisional : filaProvisional as int?,
      columnaProvisional: columnaProvisional == _sentinel ? this.columnaProvisional : columnaProvisional as int?,
      filaAncla: filaAncla == _sentinel ? this.filaAncla : filaAncla as int?,
      columnaAncla: columnaAncla == _sentinel ? this.columnaAncla : columnaAncla as int?,
      puntuacionTotal: puntuacionTotal == _sentinel ? this.puntuacionTotal : puntuacionTotal as int,
      regionesCompletadas: regionesCompletadas == _sentinel ? this.regionesCompletadas : regionesCompletadas as Set<dynamic>,
      contadorCompletadasPorRegion: contadorCompletadasPorRegion == _sentinel ? this.contadorCompletadasPorRegion : contadorCompletadasPorRegion as Map<String, int>,
      historial: historial == _sentinel ? this.historial : historial as List<String>,
    );
  }
}
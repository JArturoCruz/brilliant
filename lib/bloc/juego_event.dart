import '../../dominio/posicion.dart';

abstract class JuegoEvent {}

class IniciarTurno extends JuegoEvent {
  final Map<Posicion, int> valoresIniciales;
  IniciarTurno(this.valoresIniciales);
}

class SeleccionarNumeroAncla extends JuegoEvent {
  final int numeroElegido;
  final int numeroParaColocar;
  final int indiceDado; // NUEVO: Para diferenciar si tocó el dado 1 o el 2
  
  SeleccionarNumeroAncla({
    required this.numeroElegido, 
    required this.numeroParaColocar,
    required this.indiceDado,
  });
}

class SeleccionarCasillaAncla extends JuegoEvent {
  final int fila;
  final int columna;
  SeleccionarCasillaAncla(this.fila, this.columna);
}

// NUEVO: Evento para colocar el segundo número en el tablero
class ColocarNumero extends JuegoEvent {
  final int fila;
  final int columna;
  ColocarNumero(this.fila, this.columna);
}
import '../../dominio/posicion.dart';

abstract class JuegoEvent {}

class IniciarTurno extends JuegoEvent {
  final Map<Posicion, int> valoresIniciales;
  IniciarTurno(this.valoresIniciales);
}

class SeleccionarNumeroAncla extends JuegoEvent {
  final int numeroElegido;
  final int numeroParaColocar;
  SeleccionarNumeroAncla({required this.numeroElegido, required this.numeroParaColocar});
}

class SeleccionarCasillaAncla extends JuegoEvent {
  final int fila;
  final int columna;
  SeleccionarCasillaAncla(this.fila, this.columna);
}
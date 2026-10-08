import 'dart:math';

class Dado {
  static final _random = Random();
  
  // Devuelve un número del 1 al 6
  static int tirar() => _random.nextInt(6) + 1;
}
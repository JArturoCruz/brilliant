import 'dart:ui';

import 'tipo_azul.dart';

class TipoBlanco extends TipoAzul {
  const TipoBlanco();

  @override
  Color get color => const Color(0xFFD0D0D0);

  @override
  String get descripcion => 'Todos los números de la sección deben ser iguales';
}

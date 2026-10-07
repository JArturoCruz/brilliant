import '../region.dart';
import 'tipo.dart';
import 'tipo_amarillo.dart';
import 'tipo_azul.dart';
import 'tipo_morado.dart';
import 'tipo_rojo.dart';
import 'tipo_verde.dart';

/// Une cada región específica del tablero (identificador: verde1, verde2,
/// azul1...) con su Tipo (color/regla real). Única responsabilidad: ese
/// registro; nada sabe aquí sobre coordenadas ni sobre el estado de la
/// partida.
class TiposDeRegion {
  static const Map<RegionTablero, Tipo> porRegion = {
    RegionTablero.amarilla: TipoAmarillo(),
    RegionTablero.verde1: TipoVerde(),
    RegionTablero.verde2: TipoVerde(),
    RegionTablero.azul1: TipoAzul(),
    RegionTablero.azul2: TipoAzul(),
    RegionTablero.morada1: TipoMorado(),
    RegionTablero.morada2: TipoMorado(),
    RegionTablero.roja1: TipoRojo(),
    RegionTablero.roja2: TipoRojo(),
  };

  static Tipo obtenerTipo(RegionTablero region) {
    final tipo = porRegion[region];
    if (tipo == null) {
      throw ArgumentError('No hay Tipo definido para la región: $region');
    }
    return tipo;
  }
}

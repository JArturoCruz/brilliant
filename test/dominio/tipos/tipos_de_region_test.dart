import 'package:brilliant/dominio/region.dart';
import 'package:brilliant/dominio/tipos/tipo_amarillo.dart';
import 'package:brilliant/dominio/tipos/tipo_azul.dart';
import 'package:brilliant/dominio/tipos/tipo_morado.dart';
import 'package:brilliant/dominio/tipos/tipo_rojo.dart';
import 'package:brilliant/dominio/tipos/tipo_verde.dart';
import 'package:brilliant/dominio/tipos/tipos_de_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TiposDeRegion', () {
    test('cada región del tablero tiene un Tipo asociado', () {
      for (final region in RegionTablero.values) {
        expect(() => TiposDeRegion.obtenerTipo(region), returnsNormally);
      }
    });

    test('asigna el Tipo correcto a cada región', () {
      expect(TiposDeRegion.obtenerTipo(RegionTablero.amarilla), isA<TipoAmarillo>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.verde1), isA<TipoVerde>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.verde2), isA<TipoVerde>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.azul1), isA<TipoAzul>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.azul2), isA<TipoAzul>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.morada1), isA<TipoMorado>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.morada2), isA<TipoMorado>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.roja1), isA<TipoRojo>());
      expect(TiposDeRegion.obtenerTipo(RegionTablero.roja2), isA<TipoRojo>());
    });
  });
}

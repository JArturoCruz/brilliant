import 'posicion.dart';
import 'region.dart';
import 'tipos/tipo.dart';
import 'tipos/tipo_amarillo.dart';
import 'tipos/tipo_azul.dart';
import 'tipos/tipo_blanco.dart';
import 'tipos/tipo_morado.dart';
import 'tipos/tipo_naranja.dart';
import 'tipos/tipo_rojo.dart';
import 'tipos/tipo_verde.dart';

class MapaTablero {
  const MapaTablero({
    required this.id,
    required this.nombre,
    required this.coordenadasPorRegion,
    required this.tiposPorRegion,
  });

  final int id;
  final String nombre;
  final Map<RegionTablero, List<Posicion>> coordenadasPorRegion;
  final Map<RegionTablero, Tipo> tiposPorRegion;

  Tipo tipoDe(RegionTablero region) {
    final tipo = tiposPorRegion[region];
    if (tipo == null) {
      throw ArgumentError('No hay Tipo definido para la región: $region');
    }
    return tipo;
  }

  static const MapaTablero mapa1 = MapaTablero(
    id: 1,
    nombre: 'Mapa 1',
    coordenadasPorRegion: {
      RegionTablero.amarilla: [
        Posicion(0, 0),
        Posicion(0, 6),
        Posicion(3, 3),
        Posicion(6, 0),
        Posicion(6, 6),
      ],
      RegionTablero.verde1: [
        Posicion(0, 1),
        Posicion(1, 0),
        Posicion(1, 1),
        Posicion(2, 0),
        Posicion(3, 0),
        Posicion(4, 0),
      ],
      RegionTablero.verde2: [
        Posicion(3, 4),
        Posicion(1, 6),
        Posicion(2, 5),
        Posicion(2, 6),
        Posicion(3, 5),
        Posicion(3, 6),
      ],
      RegionTablero.azul1: [
        Posicion(0, 2),
        Posicion(1, 2),
        Posicion(1, 3),
        Posicion(2, 3),
      ],
      RegionTablero.azul2: [
        Posicion(4, 6),
        Posicion(5, 5),
        Posicion(5, 6),
        Posicion(6, 5),
      ],
      RegionTablero.morada1: [
        Posicion(0, 3),
        Posicion(0, 4),
        Posicion(0, 5),
        Posicion(1, 4),
        Posicion(1, 5),
        Posicion(2, 4),
      ],
      RegionTablero.morada2: [
        Posicion(3, 2),
        Posicion(4, 2),
        Posicion(4, 3),
        Posicion(5, 2),
        Posicion(6, 1),
        Posicion(6, 2),
      ],
      RegionTablero.roja1: [
        Posicion(2, 1),
        Posicion(2, 2),
        Posicion(3, 1),
        Posicion(4, 1),
        Posicion(5, 0),
        Posicion(5, 1),
      ],
      RegionTablero.roja2: [
        Posicion(4, 4),
        Posicion(4, 5),
        Posicion(5, 3),
        Posicion(5, 4),
        Posicion(6, 3),
        Posicion(6, 4),
      ],
      RegionTablero.blanca: [],
      RegionTablero.naranjaSuperior: [],
      RegionTablero.naranjaInferior: [],
      RegionTablero.verde3: [],
      RegionTablero.verde4: [],
    },
    tiposPorRegion: {
      RegionTablero.amarilla: TipoAmarillo(),
      RegionTablero.verde1: TipoVerde(),
      RegionTablero.verde2: TipoVerde(),
      RegionTablero.azul1: TipoAzul(),
      RegionTablero.azul2: TipoAzul(),
      RegionTablero.morada1: TipoMorado(),
      RegionTablero.morada2: TipoMorado(),
      RegionTablero.roja1: TipoRojo(),
      RegionTablero.roja2: TipoRojo(),
      RegionTablero.blanca: TipoBlanco(),
    },
  );

  static const MapaTablero mapa2 = MapaTablero(
    id: 2,
    nombre: 'Mapa 2',
    coordenadasPorRegion: {
      RegionTablero.amarilla: [
        Posicion(1, 1),
        Posicion(1, 5),
        Posicion(3, 3),
        Posicion(5, 1),
        Posicion(5, 5),
      ],
      RegionTablero.verde1: [
        Posicion(0, 4),
        Posicion(0, 5),
        Posicion(0, 6),
        Posicion(1, 6),
        Posicion(2, 6),
      ],
      RegionTablero.verde2: [
        Posicion(4, 0),
        Posicion(5, 0),
        Posicion(6, 0),
        Posicion(6, 1),
        Posicion(6, 2),
      ],
      RegionTablero.azul1: [
        Posicion(1, 2),
        Posicion(1, 3),
        Posicion(1, 4),
        Posicion(2, 3),
        Posicion(2, 4),
      ],
      RegionTablero.azul2: [
        Posicion(4, 2),
        Posicion(4, 3),
        Posicion(5, 2),
        Posicion(5, 3),
        Posicion(5, 4),
      ],
      RegionTablero.morada1: [
        Posicion(0, 0),
        Posicion(0, 1),
        Posicion(0, 2),
        Posicion(1, 0),
        Posicion(2, 0),
      ],
      RegionTablero.morada2: [
        Posicion(4, 6),
        Posicion(5, 6),
        Posicion(6, 4),
        Posicion(6, 5),
        Posicion(6, 6),
      ],
      RegionTablero.roja1: [
        Posicion(2, 1),
        Posicion(2, 2),
        Posicion(3, 0),
        Posicion(3, 1),
        Posicion(3, 2),
        Posicion(4, 1),
      ],
      RegionTablero.roja2: [
        Posicion(2, 5),
        Posicion(3, 4),
        Posicion(3, 5),
        Posicion(3, 6),
        Posicion(4, 4),
        Posicion(4, 5),
      ],
      RegionTablero.blanca: [Posicion(0, 3), Posicion(6, 3)],
      RegionTablero.naranjaSuperior: [],
      RegionTablero.naranjaInferior: [],
      RegionTablero.verde3: [],
      RegionTablero.verde4: [],
    },
    tiposPorRegion: {
      RegionTablero.amarilla: TipoAmarillo(),
      RegionTablero.verde1: TipoVerde(),
      RegionTablero.verde2: TipoVerde(),
      RegionTablero.azul1: TipoAzul(),
      RegionTablero.azul2: TipoAzul(),
      RegionTablero.morada1: TipoMorado(),
      RegionTablero.morada2: TipoMorado(),
      RegionTablero.roja1: TipoRojo(),
      RegionTablero.roja2: TipoRojo(),
      RegionTablero.blanca: TipoBlanco(),
    },
  );

  static const MapaTablero mapa3 = MapaTablero(
    id: 3,
    nombre: 'Mapa 3',
    coordenadasPorRegion: {
      RegionTablero.amarilla: [
        Posicion(0, 0),
        Posicion(0, 1),
        Posicion(0, 5),
        Posicion(0, 6),
        Posicion(1, 1),
        Posicion(1, 5),
      ],
      RegionTablero.verde1: [
        Posicion(4, 0),
        Posicion(5, 0),
        Posicion(5, 1),
        Posicion(5, 2),
        Posicion(5, 3),
        Posicion(5, 4),
        Posicion(5, 5),
        Posicion(5, 6),
        Posicion(4, 6),
      ],
      RegionTablero.verde2: [],
      RegionTablero.azul1: [
        Posicion(4, 1),
        Posicion(4, 2),
        Posicion(4, 3),
        Posicion(4, 4),
        Posicion(4, 5),
      ],
      RegionTablero.azul2: [],
      RegionTablero.morada1: [
        Posicion(0, 2),
        Posicion(1, 2),
        Posicion(1, 3),
        Posicion(1, 4),
        Posicion(0, 4),
        Posicion(2, 3),
      ],
      RegionTablero.morada2: [
        Posicion(6, 0),
        Posicion(6, 1),
        Posicion(6, 2),
        Posicion(6, 4),
        Posicion(6, 5),
        Posicion(6, 6),
      ],
      RegionTablero.roja1: [
        Posicion(2, 0),
        Posicion(2, 1),
        Posicion(2, 2),
        Posicion(3, 0),
        Posicion(3, 1),
        Posicion(3, 2),
      ],
      RegionTablero.roja2: [
        Posicion(2, 4),
        Posicion(2, 5),
        Posicion(2, 6),
        Posicion(3, 4),
        Posicion(3, 5),
        Posicion(3, 6),
      ],
      RegionTablero.blanca: [
        Posicion(0, 3),
        Posicion(1, 0),
        Posicion(1, 6),
        Posicion(3, 3),
        Posicion(6, 3),
      ],
      RegionTablero.naranjaSuperior: [],
      RegionTablero.naranjaInferior: [],
      RegionTablero.verde3: [],
      RegionTablero.verde4: [],
    },
    tiposPorRegion: {
      RegionTablero.amarilla: TipoAmarillo(),
      RegionTablero.verde1: TipoVerde(),
      RegionTablero.verde2: TipoVerde(),
      RegionTablero.azul1: TipoAzul(),
      RegionTablero.azul2: TipoAzul(),
      RegionTablero.morada1: TipoMorado(),
      RegionTablero.morada2: TipoMorado(),
      RegionTablero.roja1: TipoRojo(),
      RegionTablero.roja2: TipoRojo(),
      RegionTablero.blanca: TipoBlanco(),
    },
  );

  static const MapaTablero mapa4 = MapaTablero(
    id: 4,
    nombre: 'Mapa 4',
    coordenadasPorRegion: {
      RegionTablero.amarilla: [
        Posicion(1, 0),
        Posicion(1, 6),
        Posicion(3, 0),
        Posicion(3, 6),
        Posicion(5, 0),
        Posicion(5, 6),
      ],
      RegionTablero.verde1: [Posicion(1, 3)],
      RegionTablero.verde2: [Posicion(3, 1)],
      RegionTablero.verde3: [Posicion(3, 5)],
      RegionTablero.verde4: [Posicion(5, 3)],
      RegionTablero.azul1: [
        Posicion(1, 2),
        Posicion(3, 2),
        Posicion(5, 2),
      ],
      RegionTablero.azul2: [
        Posicion(1, 4),
        Posicion(3, 4),
        Posicion(5, 4),
      ],
      RegionTablero.morada1: [
        Posicion(2, 2),
        Posicion(2, 3),
        Posicion(2, 4),
        Posicion(3, 3),
        Posicion(4, 2),
        Posicion(4, 3),
        Posicion(4, 4),
      ],
      RegionTablero.morada2: [],
      RegionTablero.roja1: [
        Posicion(1, 1),
        Posicion(2, 0),
        Posicion(2, 1),
        Posicion(4, 0),
        Posicion(4, 1),
        Posicion(5, 1),
      ],
      RegionTablero.roja2: [
        Posicion(1, 5),
        Posicion(2, 5),
        Posicion(2, 6),
        Posicion(4, 5),
        Posicion(4, 6),
        Posicion(5, 5),
      ],
      RegionTablero.blanca: [],
      RegionTablero.naranjaSuperior: [
        Posicion(0, 0),
        Posicion(0, 1),
        Posicion(0, 2),
        Posicion(0, 3),
        Posicion(0, 4),
        Posicion(0, 5),
        Posicion(0, 6),
      ],
      RegionTablero.naranjaInferior: [
        Posicion(6, 0),
        Posicion(6, 1),
        Posicion(6, 2),
        Posicion(6, 3),
        Posicion(6, 4),
        Posicion(6, 5),
        Posicion(6, 6),
      ],
    },
    tiposPorRegion: {
      RegionTablero.amarilla: TipoAmarillo(),
      RegionTablero.verde1: TipoVerde(),
      RegionTablero.verde2: TipoVerde(),
      RegionTablero.verde3: TipoVerde(),
      RegionTablero.verde4: TipoVerde(),
      RegionTablero.azul1: TipoAzul(),
      RegionTablero.azul2: TipoAzul(),
      RegionTablero.morada1: TipoMorado(),
      RegionTablero.morada2: TipoMorado(),
      RegionTablero.roja1: TipoRojo(),
      RegionTablero.roja2: TipoRojo(),
      RegionTablero.blanca: TipoBlanco(),
      RegionTablero.naranjaSuperior: TipoNaranja(
        numeroMinimo: 4,
        numeroMaximo: 6,
      ),
      RegionTablero.naranjaInferior: TipoNaranja(
        numeroMinimo: 1,
        numeroMaximo: 3,
      ),
    },
  );
}

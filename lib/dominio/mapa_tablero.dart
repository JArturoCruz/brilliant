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

const _puntos864 = {1: 8, 2: 6, 3: 4};
const _puntos753 = {1: 7, 2: 5, 3: 3};
const _puntos642 = {1: 6, 2: 4, 3: 2};
const _puntos432 = {1: 4, 2: 3, 3: 2};
const _puntos321 = {1: 3, 2: 2, 3: 1};
const _puntos654 = {1: 6, 2: 5, 3: 4};
const _puntos643 = {1: 6, 2: 4, 3: 3};

class MapaTablero {
  const MapaTablero({
    required this.id,
    required this.nombre,
    required this.coordenadasPorRegion,
    required this.tiposPorRegion,
    this.puntuacionesPorRegion = const {},
  });

  final int id;
  final String nombre;
  final Map<RegionTablero, List<Posicion>> coordenadasPorRegion;
  final Map<RegionTablero, Tipo> tiposPorRegion;
  final Map<RegionTablero, Map<int, int>> puntuacionesPorRegion;

  Tipo tipoDe(RegionTablero region) {
    final tipo = tiposPorRegion[region];
    if (tipo == null) {
      throw ArgumentError('No hay Tipo definido para la región: $region');
    }
    return tipo;
  }

  int puntosPorPosicion(RegionTablero region, int posicion) =>
      puntuacionesPorRegion[region]?[posicion] ?? 0;

  String claveGrupoPuntuacion(RegionTablero region) => region.name;

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
    puntuacionesPorRegion: {
      RegionTablero.amarilla: _puntos864,
      RegionTablero.verde1: _puntos432,
      RegionTablero.verde2: _puntos432,
      RegionTablero.azul1: _puntos753,
      RegionTablero.azul2: _puntos753,
      RegionTablero.morada1: _puntos642,
      RegionTablero.morada2: _puntos642,
      RegionTablero.roja1: _puntos642,
      RegionTablero.roja2: _puntos642,
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
    puntuacionesPorRegion: {
      RegionTablero.amarilla: _puntos642,
      RegionTablero.verde1: _puntos432,
      RegionTablero.verde2: _puntos432,
      RegionTablero.azul1: _puntos753,
      RegionTablero.azul2: _puntos753,
      RegionTablero.morada1: _puntos642,
      RegionTablero.morada2: _puntos642,
      RegionTablero.roja1: _puntos642,
      RegionTablero.roja2: _puntos642,
      RegionTablero.blanca: _puntos321,
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
    puntuacionesPorRegion: {
      RegionTablero.amarilla: _puntos753,
      RegionTablero.verde1: _puntos654,
      RegionTablero.azul1: _puntos753,
      RegionTablero.morada1: _puntos753,
      RegionTablero.morada2: _puntos753,
      RegionTablero.roja1: _puntos642,
      RegionTablero.roja2: _puntos642,
      RegionTablero.blanca: _puntos864,
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
      RegionTablero.verde1: [
        Posicion(1, 3),
        Posicion(3, 1),
        Posicion(3, 5),
        Posicion(5, 3),
      ],
      RegionTablero.verde2: [],
      RegionTablero.verde3: [],
      RegionTablero.verde4: [],
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
    puntuacionesPorRegion: {
      RegionTablero.amarilla: _puntos864,
      RegionTablero.verde1: _puntos321,
      RegionTablero.azul1: _puntos864,
      RegionTablero.azul2: _puntos864,
      RegionTablero.morada1: _puntos753,
      RegionTablero.roja1: _puntos642,
      RegionTablero.roja2: _puntos642,
      RegionTablero.naranjaSuperior: _puntos643,
      RegionTablero.naranjaInferior: _puntos643,
    },
  );
}

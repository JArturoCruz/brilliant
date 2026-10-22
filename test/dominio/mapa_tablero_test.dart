import 'package:brilliant/dominio/mapa_tablero.dart';
import 'package:brilliant/dominio/posicion.dart';
import 'package:brilliant/dominio/region.dart';
import 'package:brilliant/dominio/tablero.dart';
import 'package:brilliant/dominio/tipos/estado_region.dart';
import 'package:brilliant/dominio/tipos/tipo_blanco.dart';
import 'package:brilliant/dominio/topologia_tablero.dart';
import 'package:brilliant/dominio/validador_de_jugadas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapaTablero.mapa2', () {
    test('asigna exactamente una región a cada una de las 49 casillas', () {
      final posiciones = <Posicion>[];

      for (var fila = 0; fila < TopologiaTablero.filas; fila++) {
        for (var columna = 0; columna < TopologiaTablero.columnas; columna++) {
          final region = TopologiaTablero.regionDeCelda(
            fila,
            columna,
            mapa: MapaTablero.mapa2,
          );
          expect(region, isNotNull, reason: 'Casilla ($fila, $columna)');
          posiciones.add(Posicion(fila, columna));
        }
      }

      final posicionesDefinidas = MapaTablero.mapa2.coordenadasPorRegion.values
          .expand((region) => region)
          .toList();
      expect(posicionesDefinidas, hasLength(49));
      expect(posicionesDefinidas.toSet(), hasLength(49));
      expect(posiciones.toSet(), hasLength(49));
    });

    test('las zonas corresponden al patrón de colores solicitado', () {
      RegionTablero? region(int fila, int columna) =>
          TopologiaTablero.regionDeCelda(
            fila,
            columna,
            mapa: MapaTablero.mapa2,
          );

      const esperado = [
        [
          RegionTablero.morada1,
          RegionTablero.morada1,
          RegionTablero.morada1,
          RegionTablero.blanca,
          RegionTablero.verde1,
          RegionTablero.verde1,
          RegionTablero.verde1,
        ],
        [
          RegionTablero.morada1,
          RegionTablero.amarilla,
          RegionTablero.azul1,
          RegionTablero.azul1,
          RegionTablero.azul1,
          RegionTablero.amarilla,
          RegionTablero.verde1,
        ],
        [
          RegionTablero.morada1,
          RegionTablero.roja1,
          RegionTablero.roja1,
          RegionTablero.azul1,
          RegionTablero.azul1,
          RegionTablero.roja2,
          RegionTablero.verde1,
        ],
        [
          RegionTablero.roja1,
          RegionTablero.roja1,
          RegionTablero.roja1,
          RegionTablero.amarilla,
          RegionTablero.roja2,
          RegionTablero.roja2,
          RegionTablero.roja2,
        ],
        [
          RegionTablero.verde2,
          RegionTablero.roja1,
          RegionTablero.azul2,
          RegionTablero.azul2,
          RegionTablero.roja2,
          RegionTablero.roja2,
          RegionTablero.morada2,
        ],
        [
          RegionTablero.verde2,
          RegionTablero.amarilla,
          RegionTablero.azul2,
          RegionTablero.azul2,
          RegionTablero.azul2,
          RegionTablero.amarilla,
          RegionTablero.morada2,
        ],
        [
          RegionTablero.verde2,
          RegionTablero.verde2,
          RegionTablero.verde2,
          RegionTablero.blanca,
          RegionTablero.morada2,
          RegionTablero.morada2,
          RegionTablero.morada2,
        ],
      ];

      for (var fila = 0; fila < esperado.length; fila++) {
        for (var columna = 0; columna < esperado[fila].length; columna++) {
          expect(
            region(fila, columna),
            esperado[fila][columna],
            reason: 'Casilla ($fila, $columna)',
          );
        }
      }

      expect(
        TopologiaTablero.posicionesDe(
          RegionTablero.blanca,
          mapa: MapaTablero.mapa2,
        ),
        [const Posicion(0, 3), const Posicion(6, 3)],
      );
    });

    test('el tipo blanco aplica la regla de igualdad', () {
      final tablero = TableroJuego();
      const validador = ValidadorDeJugadas(mapa: MapaTablero.mapa2);
      final blancos = TopologiaTablero.posicionesDe(
        RegionTablero.blanca,
        mapa: MapaTablero.mapa2,
      );

      expect(MapaTablero.mapa2.tipoDe(RegionTablero.blanca), isA<TipoBlanco>());
      tablero.asignarValor(blancos.first.fila, blancos.first.columna, 4);
      expect(
        validador.puedeAsignar(
          tablero,
          blancos.last.fila,
          blancos.last.columna,
          4,
        ),
        isTrue,
      );
      expect(
        validador.puedeAsignar(
          tablero,
          blancos.last.fila,
          blancos.last.columna,
          5,
        ),
        isFalse,
      );
    });

    test('la región morada aplica la regla a sus quince casillas', () {
      final tablero = TableroJuego();
      const validador = ValidadorDeJugadas(mapa: MapaTablero.mapa2);
      final moradas = TopologiaTablero.posicionesDe(
        RegionTablero.morada1,
        mapa: MapaTablero.mapa2,
      );

      for (final pos in moradas.take(moradas.length - 1)) {
        tablero.asignarValor(pos.fila, pos.columna, 2);
      }

      expect(
        validador.puedeAsignar(
          tablero,
          moradas.last.fila,
          moradas.last.columna,
          2,
        ),
        isFalse,
      );
      expect(
        validador.puedeAsignar(
          tablero,
          moradas.last.fila,
          moradas.last.columna,
          3,
        ),
        isTrue,
      );
    });

    test('la regla blanca se evalúa como zona azul al completarse', () {
      const tipo = TipoBlanco();
      expect(tipo.esPosibleAgregar([3, 3], 3), isTrue);
      expect(tipo.esPosibleAgregar([3, 3], 4), isFalse);
      expect(tipo.calcularEstado([3]), EstadoRegion.completa);
    });

    test('mantiene el mapa 1 como mapa predeterminado', () {
      expect(TopologiaTablero.regionDeCelda(0, 0), RegionTablero.amarilla);
      expect(
        TopologiaTablero.regionDeCelda(0, 0, mapa: MapaTablero.mapa2),
        RegionTablero.morada1,
      );
    });
  });

  group('MapaTablero.mapa3', () {
    test('coincide con la matriz y cubre las 49 casillas una sola vez', () {
      const esperado = [
        [
          RegionTablero.amarilla,
          RegionTablero.amarilla,
          RegionTablero.morada1,
          RegionTablero.blanca,
          RegionTablero.morada1,
          RegionTablero.amarilla,
          RegionTablero.amarilla,
        ],
        [
          RegionTablero.blanca,
          RegionTablero.amarilla,
          RegionTablero.morada1,
          RegionTablero.morada1,
          RegionTablero.morada1,
          RegionTablero.amarilla,
          RegionTablero.blanca,
        ],
        [
          RegionTablero.roja1,
          RegionTablero.roja1,
          RegionTablero.roja1,
          RegionTablero.morada1,
          RegionTablero.roja2,
          RegionTablero.roja2,
          RegionTablero.roja2,
        ],
        [
          RegionTablero.roja1,
          RegionTablero.roja1,
          RegionTablero.roja1,
          RegionTablero.blanca,
          RegionTablero.roja2,
          RegionTablero.roja2,
          RegionTablero.roja2,
        ],
        [
          RegionTablero.verde1,
          RegionTablero.azul1,
          RegionTablero.azul1,
          RegionTablero.azul1,
          RegionTablero.azul1,
          RegionTablero.azul1,
          RegionTablero.verde1,
        ],
        [
          RegionTablero.verde1,
          RegionTablero.verde1,
          RegionTablero.verde1,
          RegionTablero.verde1,
          RegionTablero.verde1,
          RegionTablero.verde1,
          RegionTablero.verde1,
        ],
        [
          RegionTablero.morada2,
          RegionTablero.morada2,
          RegionTablero.morada2,
          RegionTablero.blanca,
          RegionTablero.morada2,
          RegionTablero.morada2,
          RegionTablero.morada2,
        ],
      ];
      final posiciones = <Posicion>[];

      for (var fila = 0; fila < esperado.length; fila++) {
        for (var columna = 0; columna < esperado[fila].length; columna++) {
          expect(
            TopologiaTablero.regionDeCelda(
              fila,
              columna,
              mapa: MapaTablero.mapa3,
            ),
            esperado[fila][columna],
            reason: 'Casilla ($fila, $columna)',
          );
          posiciones.add(Posicion(fila, columna));
        }
      }

      final regiones = MapaTablero.mapa3.coordenadasPorRegion.values
          .expand((region) => region)
          .toList();
      expect(regiones, hasLength(49));
      expect(regiones.toSet(), hasLength(49));
      expect(posiciones.toSet(), hasLength(49));
    });

    test('las casillas blancas del mapa 3 deben llevar el mismo número', () {
      final tablero = TableroJuego();
      const validador = ValidadorDeJugadas(mapa: MapaTablero.mapa3);
      final blancas = TopologiaTablero.posicionesDe(
        RegionTablero.blanca,
        mapa: MapaTablero.mapa3,
      );

      expect(blancas, hasLength(5));
      for (final posicion in blancas.take(blancas.length - 1)) {
        tablero.asignarValor(posicion.fila, posicion.columna, 2);
      }

      expect(
        validador.puedeAsignar(
          tablero,
          blancas.last.fila,
          blancas.last.columna,
          2,
        ),
        isTrue,
      );
      expect(
        validador.puedeAsignar(
          tablero,
          blancas.last.fila,
          blancas.last.columna,
          3,
        ),
        isFalse,
      );
    });
  });
}

import 'package:brilliant/main.dart' as app;
import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/presentacion/pantalla_configuracion_inicial.dart';
import 'package:brilliant/presentacion/pantalla_juego.dart';
import 'package:brilliant/presentacion/seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'package:brilliant/presentacion/widgets/boton_inicio.dart';
import 'package:brilliant/presentacion/widgets/puntuaciones_disponibles_widget.dart';
import 'package:brilliant/presentacion/widgets/selector_numeros_zona_inicial.dart';
import 'package:brilliant/presentacion/widgets/tablero_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthenticatedGateway implements AuthGateway {
  const _AuthenticatedGateway();

  static const _user = AuthUser(
    id: 'user-1',
    name: 'Player One',
    email: 'player@example.com',
  );

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount(String password) async {}
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(1200, 1600);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('navega desde inicio al mapa disponible en móvil', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(320, 740);
    binding.window.devicePixelRatioTestValue = 1;

    await tester.pumpWidget(
      const app.BrilliantApp(authGateway: _AuthenticatedGateway()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.byType(TableroWidget), findsNothing);

    final botonInicio = find.text('Jugar');
    await tester.ensureVisible(botonInicio);
    await tester.tap(botonInicio);
    await tester.pumpAndSettle();

    expect(find.byType(PantallaSeleccionMapa), findsOneWidget);
    expect(find.text('Mapa 1'), findsOneWidget);
    expect(find.text('Mapa 2'), findsOneWidget);
    expect(find.text('Mapa 3'), findsOneWidget);
    expect(find.text('Mapa 4'), findsOneWidget);

    await tester.tap(find.text('Mapa 1'));
    await tester.pumpAndSettle();

    expect(tester.widget<PantallaJuego>(find.byType(PantallaJuego)).mapa.id, 1);
    expect(find.byType(PantallaJuego), findsOneWidget);
    expect(find.byType(TableroWidget), findsOneWidget);
    expect(find.byType(BotonInicio), findsOneWidget);
    expect(find.byKey(const Key('mobile-game-controls')), findsOneWidget);
    expect(find.byKey(const Key('show-game-scores')), findsOneWidget);
    final tableroRect = tester.getRect(find.byType(TableroWidget));
    final controlesRect = tester.getRect(
      find.byKey(const Key('mobile-game-controls')),
    );
    expect(tableroRect.width, tableroRect.height);
    expect(tableroRect.width, greaterThan(150));
    expect(tableroRect.bottom, lessThan(controlesRect.top));
    expect(controlesRect.right, lessThanOrEqualTo(320));
    await tester.tap(find.byKey(const Key('show-game-scores')));
    await tester.pumpAndSettle();
    expect(find.byType(PuntuacionesDisponiblesWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arma la pantalla con título, tablero, selector y botón', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaConfiguracionInicial()),
    );

    expect(find.text('Brilliant'), findsOneWidget);
    expect(find.byType(TableroWidget), findsOneWidget);
    expect(find.byType(SelectorNumerosZonaInicial), findsOneWidget);
    expect(find.byType(BotonInicio), findsOneWidget);
  });

  testWidgets('el tablero aprovecha el espacio disponible en computadora', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaJuego()));

    final tableroRect = tester.getRect(find.byType(TableroWidget));
    final puntuacionesRect = tester.getRect(
      find.byType(PuntuacionesDisponiblesWidget),
    );

    expect(tableroRect.width, greaterThan(500));
    expect(tableroRect.width, tableroRect.height);
    expect(tableroRect.right, lessThan(puntuacionesRect.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('inicia la partida individual desde el diseño móvil', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(320, 740);
    binding.window.devicePixelRatioTestValue = 1;

    await tester.pumpWidget(
      const app.BrilliantApp(authGateway: _AuthenticatedGateway()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa 1'));
    await tester.pumpAndSettle();

    for (var n = 1; n <= 6; n++) {
      final numero = find.widgetWithText(OutlinedButton, '$n');
      await tester.ensureVisible(numero);
      await tester.tap(numero);
      await tester.pump();
    }

    final inicio = find.widgetWithText(FilledButton, 'Inicio');
    expect(tester.widget<FilledButton>(inicio).onPressed, isNotNull);

    await tester.tap(inicio);
    await tester.pumpAndSettle();

    expect(find.byType(BotonInicio), findsNothing);
    expect(find.byKey(const ValueKey('dado-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inicia la partida individual desde el diseño de escritorio', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(1200, 900);
    binding.window.devicePixelRatioTestValue = 1;

    await tester.pumpWidget(
      const app.BrilliantApp(authGateway: _AuthenticatedGateway()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa 1'));
    await tester.pumpAndSettle();

    for (var n = 1; n <= 6; n++) {
      final numero = find.widgetWithText(OutlinedButton, '$n');
      await tester.ensureVisible(numero);
      await tester.tap(numero);
      await tester.pump();
    }

    final inicio = find.widgetWithText(FilledButton, 'Inicio');
    expect(tester.widget<FilledButton>(inicio).onPressed, isNotNull);

    await tester.tap(inicio);
    await tester.pumpAndSettle();

    expect(find.byType(BotonInicio), findsNothing);
    expect(find.byKey(const ValueKey('dado-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el botón Inicio empieza deshabilitado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaConfiguracionInicial()),
    );

    final inicio = find.widgetWithText(FilledButton, 'Inicio');
    final boton = tester.widget<FilledButton>(inicio);
    expect(boton.onPressed, isNull);
  });

  testWidgets(
    'flujo completo: llenar los 6 números distintos habilita Inicio y tocarlo activa la configuración',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PantallaConfiguracionInicial()),
      );

      for (var n = 1; n <= 6; n++) {
        final finder = find.widgetWithText(OutlinedButton, '$n');
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();
      }

      expect(find.textContaining('¡Configuración lista!'), findsNothing);
      final inicio = find.widgetWithText(FilledButton, 'Inicio');
      final boton = tester.widget<FilledButton>(inicio);
      expect(boton.onPressed, isNotNull);

      await tester.tap(inicio);
      await tester.pumpAndSettle();

      expect(find.text('¡Configuración lista!'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Inicio'), findsNothing);
    },
  );

  testWidgets('tocar un número repetido muestra el aviso de número repetido', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PantallaConfiguracionInicial()),
    );

    final primerNumero = find.widgetWithText(OutlinedButton, '1');
    await tester.ensureVisible(primerNumero);
    await tester.tap(primerNumero);
    await tester.pump();

    await tester.ensureVisible(primerNumero);
    await tester.tap(primerNumero);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('ya está en la casilla'), findsOneWidget);
  });
}

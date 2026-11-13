import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/presentacion/pantalla_inicio.dart';
import 'package:brilliant/presentacion/pantalla_instrucciones.dart';
import 'package:brilliant/presentacion/seleccion_mapa/pantalla_seleccion_mapa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TokenStore implements AuthTokenStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
  @override
  Future<void> delete() async => token = null;
}

class _ServerStore implements AuthServerStore {
  String? url;
  @override
  Future<String?> read() async => url;
  @override
  Future<void> write(String value) async => url = value;
}

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.user, this.sessionError});

  AuthUser? user;
  AuthApiException? sessionError;
  int currentUserCalls = 0;

  static const account = AuthUser(
    id: 'user-1',
    name: 'Player One',
    email: 'player@example.com',
  );

  @override
  Future<AuthUser> register({
    required String name,
    required String password,
  }) async {
    user = account;
    return account;
  }

  @override
  Future<AuthUser> signIn({
    required String name,
    required String password,
  }) async {
    user = account;
    return account;
  }

  @override
  Future<AuthUser?> currentUser() async {
    currentUserCalls++;
    final error = sessionError;
    if (error != null) {
      sessionError = null;
      throw error;
    }
    return user;
  }

  @override
  Future<void> signOut() async => user = null;

  @override
  Future<void> deleteAccount(String password) async => user = null;
}

void main() {
  testWidgets('exige conectar antes de acceder a la cuenta', (tester) async {
    final client = AuthClient(
      baseUrl: '',
      tokenStore: _TokenStore(),
      serverStore: _ServerStore(),
      httpClient: MockClient(
        (_) async =>
            http.Response('{"status":"ok","service":"brilliant"}', 200),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(authGateway: client, descubrir: () async => []),
      ),
    );
    await tester.pumpAndSettle();
    final accountButton = find.widgetWithText(
      OutlinedButton,
      'Crear cuenta o iniciar sesión',
    );
    expect(tester.widget<OutlinedButton>(accountButton).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('server-address')),
      '192.168.10.8',
    );
    await tester.ensureVisible(find.byKey(const Key('connect-server')));
    await tester.tap(find.byKey(const Key('connect-server')));
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(accountButton).onPressed, isNotNull);
  });

  testWidgets('permite elegir un servidor detectado y conectar', (
    tester,
  ) async {
    final client = AuthClient(
      baseUrl: 'http://old.example:3000',
      tokenStore: _TokenStore(),
      serverStore: _ServerStore(),
      httpClient: MockClient(
        (request) async =>
            http.Response('{"status":"ok","service":"brilliant"}', 200),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(
          authGateway: client,
          descubrir: () async => ['http://192.168.10.8:3000'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('server-list')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('http://192.168.10.8:3000').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('connect-server')));
    await tester.tap(find.byKey(const Key('connect-server')));
    await tester.pumpAndSettle();
    expect(client.baseUrl, 'http://192.168.10.8:3000');
    expect(find.text('Servidor seleccionado.'), findsOneWidget);
  });

  testWidgets('muestra errores al introducir una dirección manual', (
    tester,
  ) async {
    final client = AuthClient(
      baseUrl: 'http://old.example:3000',
      tokenStore: _TokenStore(),
      serverStore: _ServerStore(),
      httpClient: MockClient((request) async => http.Response('{}', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(authGateway: client, descubrir: () async => []),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('server-address')),
      '192.168.20.3',
    );
    await tester.ensureVisible(find.byKey(const Key('connect-server')));
    await tester.tap(find.byKey(const Key('connect-server')));
    await tester.pumpAndSettle();
    expect(
      find.text('La dirección no respondió como un servidor Brilliant.'),
      findsOneWidget,
    );
    expect(client.baseUrl, 'http://old.example:3000');
  });

  testWidgets('actualiza la lista cuando cambia la IP detectada', (
    tester,
  ) async {
    var servers = ['http://192.168.10.8:3000'];
    final client = AuthClient(
      baseUrl: 'http://old.example:3000',
      tokenStore: _TokenStore(),
      serverStore: _ServerStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(
          authGateway: client,
          descubrir: () async => servers,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('server-list')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('http://192.168.10.8:3000').last);
    await tester.pumpAndSettle();
    servers = ['http://192.168.10.9:3000'];
    await tester.ensureVisible(find.byKey(const Key('search-servers')));
    await tester.tap(find.byKey(const Key('search-servers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('server-list')));
    await tester.pumpAndSettle();
    expect(find.text('http://192.168.10.9:3000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no permite jugar sin una sesión iniciada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PantallaInicio(authGateway: FakeAuthGateway())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Brilliant'), findsOneWidget);
    expect(
      find.text('Crea una cuenta o inicia sesión para jugar.'),
      findsOneWidget,
    );
    expect(find.text('Crear cuenta o iniciar sesión'), findsOneWidget);
    expect(find.text('Instrucciones'), findsNothing);
    expect(find.text('Cómo jugar'), findsNothing);
    expect(find.text('Jugar'), findsNothing);
    expect(find.byType(PantallaSeleccionMapa), findsNothing);
  });

  testWidgets('ofrece reintentar sesión y recupera el nombre al reconectar', (
    tester,
  ) async {
    final gateway = FakeAuthGateway(
      user: FakeAuthGateway.account,
      sessionError: const AuthApiException(
        'No se pudo conectar con el servidor.',
        requestId: 'ref-session',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: PantallaInicio(authGateway: gateway)),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Código de referencia: ref-session'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry-session')), findsOneWidget);
    expect(find.text('Jugar'), findsNothing);

    await tester.tap(find.byKey(const Key('retry-session')));
    await tester.pumpAndSettle();

    expect(gateway.currentUserCalls, 2);
    expect(find.text('¡Hola, Player One!'), findsOneWidget);
    expect(find.text('Jugar'), findsOneWidget);
  });

  testWidgets('muestra el nombre y habilita el juego con sesión activa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(
          authGateway: FakeAuthGateway(user: FakeAuthGateway.account),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Player One!'), findsOneWidget);
    expect(find.text('Instrucciones'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Jugar'), findsOneWidget);
  });

  testWidgets('al registrarse vuelve al inicio con el nombre de usuario', (
    tester,
  ) async {
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(
      MaterialApp(home: PantallaInicio(authGateway: gateway)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear cuenta o iniciar sesión'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name')), 'Player One');
    await tester.enterText(find.byKey(const Key('account-password')), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Player One!'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Jugar'), findsOneWidget);
  });

  testWidgets('el botón Instrucciones abre la información del juego', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(
          authGateway: FakeAuthGateway(user: FakeAuthGateway.account),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Instrucciones'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaInstrucciones), findsOneWidget);
    expect(find.text('Cómo jugar'), findsOneWidget);
    expect(find.text('Reglas de las zonas'), findsOneWidget);
    expect(find.text('Cómo se puntúa'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PantallaInicio), findsOneWidget);
  });

  testWidgets('el botón Inicio navega al selector de mapas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(
          authGateway: FakeAuthGateway(user: FakeAuthGateway.account),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Jugar'));
    await tester.pumpAndSettle();

    expect(find.byType(PantallaSeleccionMapa), findsOneWidget);
    expect(find.text('Selecciona un mapa'), findsOneWidget);
  });

  testWidgets('muestra instrucciones y puntuaciones específicas por mapa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(
          authGateway: FakeAuthGateway(user: FakeAuthGateway.account),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Instrucciones'));
    await tester.pumpAndSettle();

    expect(find.textContaining('casillas iniciales señaladas'), findsOneWidget);
    expect(find.textContaining('casilla vacía adyacente'), findsOneWidget);

    final mapaTres = find.text('Mapa 3');
    await tester.ensureVisible(mapaTres);
    await tester.tap(mapaTres);
    await tester.pumpAndSettle();

    expect(
      find.text('Moradas (cuentan como una zona): 7, 5, 3 puntos.'),
      findsOneWidget,
    );
    expect(
      find.text('Blancas (una sola zona): 8, 6, 4 puntos.'),
      findsOneWidget,
    );
  });
}

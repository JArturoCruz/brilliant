import 'dart:convert';

import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryTokenStore implements AuthTokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> delete() async => token = null;
}

class MemoryServerStore implements AuthServerStore {
  String? url;

  @override
  Future<String?> read() async => url;

  @override
  Future<void> write(String value) async => url = value;
}

void main() {
  const user = {
    'id': 'user-1',
    'name': 'Player One',
    'email': 'player@example.com',
  };

  test(
    'selecciona y recuerda un servidor sin enviarle el token anterior',
    () async {
      final tokens = MemoryTokenStore()..token = 'old-token';
      final servers = MemoryServerStore();
      final client = AuthClient(
        baseUrl: 'http://old.example:3000',
        tokenStore: tokens,
        serverStore: servers,
        httpClient: MockClient((request) async {
          expect(request.url.toString(), 'http://192.168.10.8:3000/health');
          expect(request.headers['authorization'], isNull);
          return http.Response('{"status":"ok","service":"brilliant"}', 200);
        }),
      );

      await client.selectServer('192.168.10.8');
      expect(tokens.token, isNull);
      expect(client.baseUrl, 'http://192.168.10.8:3000');
      expect(servers.url, client.baseUrl);

      final restarted = AuthClient(
        baseUrl: 'http://old.example:3000',
        tokenStore: tokens,
        serverStore: servers,
      );
      await restarted.restoreServer();
      expect(restarted.baseUrl, client.baseUrl);
    },
  );

  test(
    'recuerda la dirección inicial al conectarse al mismo servidor',
    () async {
      final tokens = MemoryTokenStore()..token = 'session-token';
      final servers = MemoryServerStore();
      final client = AuthClient(
        baseUrl: 'http://localhost:3000',
        tokenStore: tokens,
        serverStore: servers,
        httpClient: MockClient(
          (_) async =>
              http.Response('{"status":"ok","service":"brilliant"}', 200),
        ),
      );

      await client.selectServer('http://localhost:3000');

      expect(servers.url, 'http://localhost:3000');
      expect(tokens.token, 'session-token');
    },
  );

  test(
    'inicia sesión y usa el servidor seleccionado para multijugador',
    () async {
      final tokens = MemoryTokenStore()..token = 'old-token';
      final client = AuthClient(
        baseUrl: 'http://old.example:3000',
        tokenStore: tokens,
        serverStore: MemoryServerStore(),
        httpClient: MockClient((request) async {
          expect(request.url.host, '192.168.10.8');
          if (request.url.path == '/health') {
            expect(request.headers['authorization'], isNull);
            return http.Response('{"status":"ok","service":"brilliant"}', 200);
          }
          if (request.url.path == '/api/auth/sign-in/email') {
            expect(request.headers['authorization'], isNull);
            return http.Response(
              jsonEncode({'user': user, 'token': 'new-token'}),
              200,
            );
          }
          expect(request.url.path, '/api/multiplayer/lobby');
          expect(request.headers['authorization'], 'Bearer new-token');
          return http.Response('{}', 200);
        }),
      );
      await client.selectServer('192.168.10.8:3000');
      await client.signIn(
        email: 'player@example.com',
        password: 'a-strong-password',
      );
      await client.authenticatedRequest('GET', '/api/multiplayer/lobby');
    },
  );

  test('rechaza servidores inválidos sin alterar la sesión anterior', () async {
    final tokens = MemoryTokenStore()..token = 'old-token';
    final client = AuthClient(
      baseUrl: 'http://old.example:3000',
      tokenStore: tokens,
      serverStore: MemoryServerStore(),
      httpClient: MockClient(
        (request) async => http.Response('{"status":"ok"}', 200),
      ),
    );

    await expectLater(
      client.selectServer('http://evil.example/path'),
      throwsA(isA<AuthApiException>()),
    );
    await expectLater(
      client.selectServer('192.168.10.8:3000'),
      throwsA(isA<AuthApiException>()),
    );
    expect(tokens.token, 'old-token');
    expect(client.baseUrl, 'http://old.example:3000');
  });

  test('uses the host gateway for localhost on the Android emulator', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final client = AuthClient.fromEnvironment(
      tokenStore: MemoryTokenStore()..token = 'session-token',
      httpClient: MockClient((request) async {
        expect(request.url.host, '10.0.2.2');
        expect(request.url.port, 3000);
        return http.Response('{}', 200);
      }),
    );

    await client.authenticatedRequest('GET', '/api/multiplayer/lobby');
  });

  test('keeps localhost for desktop development', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final client = AuthClient.fromEnvironment(
      tokenStore: MemoryTokenStore()..token = 'session-token',
      httpClient: MockClient((request) async {
        expect(request.url.host, 'localhost');
        expect(request.url.port, 3000);
        return http.Response('{}', 200);
      }),
    );

    await client.authenticatedRequest('GET', '/api/multiplayer/lobby');
  });

  test('registers through Better Auth and stores its bearer token', () async {
    final tokenStore = MemoryTokenStore();
    final diagnostics = <AuthRequestDiagnostic>[];
    final client = AuthClient(
      baseUrl: 'http://localhost:3000/',
      tokenStore: tokenStore,
      onDiagnostic: diagnostics.add,
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/api/auth/sign-up/email',
        );
        expect(request.method, 'POST');
        expect(
          request.headers['x-request-id'],
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(jsonDecode(request.body), {
          'name': 'Player One',
          'email': 'player@example.com',
          'password': 'a-strong-password',
        });
        return http.Response(
          jsonEncode({'token': 'session-token', 'user': user}),
          200,
          headers: {'set-auth-token': 'session-token'},
        );
      }),
    );

    final account = await client.register(
      name: 'Player One',
      email: 'player@example.com',
      password: 'a-strong-password',
    );

    expect(account.email, 'player@example.com');
    expect(tokenStore.token, 'session-token');
    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.path, '/api/auth/sign-up/email');
    expect(diagnostics.single.succeeded, isTrue);
    expect(diagnostics.single.statusCode, 200);
    expect(
      diagnostics.single.toString(),
      isNot(contains('player@example.com')),
    );
  });

  test(
    'gets current user with bearer token and clears expired session',
    () async {
      final tokenStore = MemoryTokenStore()..token = 'expired-token';
      final client = AuthClient(
        baseUrl: 'http://localhost:3000',
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/auth/get-session');
          expect(request.headers['authorization'], 'Bearer expired-token');
          return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
        }),
      );

      expect(await client.currentUser(), isNull);
      expect(tokenStore.token, isNull);
    },
  );

  test('sends the stored bearer token on authenticated requests', () async {
    final client = AuthClient(
      baseUrl: 'http://localhost:3000',
      tokenStore: MemoryTokenStore()..token = 'session-token',
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/multiplayer/lobby');
        expect(request.headers['authorization'], 'Bearer session-token');
        return http.Response(
          jsonEncode({'activePlayers': [], 'rooms': []}),
          200,
        );
      }),
    );

    final response = await client.authenticatedRequest(
      'GET',
      '/api/multiplayer/lobby',
    );

    expect(response.statusCode, 200);
  });

  test(
    'deletes the account after reauthentication and clears local token',
    () async {
      final tokenStore = MemoryTokenStore()..token = 'session-token';
      final client = AuthClient(
        baseUrl: 'http://localhost:3000',
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/auth/delete-user');
          expect(request.headers['authorization'], 'Bearer session-token');
          expect(jsonDecode(request.body), {'password': 'a-strong-password'});
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );

      await client.deleteAccount('a-strong-password');

      expect(tokenStore.token, isNull);
    },
  );

  test(
    'clears local session and returns a trace code if sign-out fails',
    () async {
      final tokenStore = MemoryTokenStore()..token = 'session-token';
      final client = AuthClient(
        baseUrl: 'http://localhost:3000',
        tokenStore: tokenStore,
        httpClient: MockClient((_) async {
          throw http.ClientException('network failure');
        }),
      );

      await expectLater(
        client.signOut(),
        throwsA(
          isA<AuthApiException>()
              .having((error) => error.requestId, 'request ID', isNotNull)
              .having(
                (error) => error.userMessage,
                'user-facing error',
                contains('Código de referencia:'),
              ),
        ),
      );
      expect(tokenStore.token, isNull);
    },
  );

  test('explains rate limiting without displaying server internals', () async {
    final client = AuthClient(
      baseUrl: 'http://localhost:3000',
      tokenStore: MemoryTokenStore(),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'internal rate-limit detail'}),
          429,
          headers: {'x-retry-after': '72'},
        );
      }),
    );

    await expectLater(
      client.signIn(email: 'player@example.com', password: 'a-strong-password'),
      throwsA(
        isA<AuthApiException>()
            .having((error) => error.statusCode, 'status code', 429)
            .having(
              (error) => error.message,
              'message',
              contains('72 segundos'),
            )
            .having(
              (error) => error.message,
              'message',
              isNot(contains('internal rate-limit detail')),
            ),
      ),
    );
  });
}

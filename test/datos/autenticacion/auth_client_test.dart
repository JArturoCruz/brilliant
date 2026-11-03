import 'dart:convert';

import 'package:brilliant/datos/autenticacion/auth_client.dart';
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

void main() {
  const user = {
    'id': 'user-1',
    'name': 'Player One',
    'email': 'player@example.com',
  };

  test('registers through Better Auth and stores its bearer token', () async {
    final tokenStore = MemoryTokenStore();
    final client = AuthClient(
      baseUrl: 'http://localhost:3000/',
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:3000/api/auth/sign-up/email');
        expect(request.method, 'POST');
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
  });

  test('gets current user with bearer token and clears expired session', () async {
    final tokenStore = MemoryTokenStore()..token = 'expired-token';
    final client = AuthClient(
      baseUrl: 'http://localhost:3000',
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/auth/get-session');
        expect(request.headers['authorization'], 'Bearer expired-token');
        return http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
        );
      }),
    );

    expect(await client.currentUser(), isNull);
    expect(tokenStore.token, isNull);
  });

  test('deletes the account after reauthentication and clears local token', () async {
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
  });
}

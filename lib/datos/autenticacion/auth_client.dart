import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

abstract interface class AuthGateway {
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser?> currentUser();
  Future<void> signOut();
  Future<void> deleteAccount(String password);
}

abstract interface class AuthTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'brilliant_auth_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _tokenKey);
}

class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    if (id is! String || email is! String) {
      throw const AuthApiException(
        'El servidor devolvió datos de cuenta no válidos.',
      );
    }
    return AuthUser(id: id, name: name is String ? name : '', email: email);
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthClient implements AuthGateway {
  AuthClient({
    required String baseUrl,
    http.Client? httpClient,
    AuthTokenStore? tokenStore,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _httpClient = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? SecureAuthTokenStore();

  factory AuthClient.fromEnvironment() {
    const configuredUrl = String.fromEnvironment('BRILLIANT_API_URL');
    final baseUrl = configuredUrl.isNotEmpty
        ? configuredUrl
        : kReleaseMode
        ? null
        : 'http://localhost:3000';
    if (baseUrl == null) {
      throw StateError(
        'Configura BRILLIANT_API_URL con la URL HTTPS del servidor antes '
        'de compilar la versión de producción.',
      );
    }

    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError(
        'BRILLIANT_API_URL debe ser una URL HTTP o HTTPS válida.',
      );
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError(
        'BRILLIANT_API_URL debe usar HTTPS en la versión de producción.',
      );
    }

    return AuthClient(baseUrl: baseUrl);
  }

  static final AuthClient shared = AuthClient.fromEnvironment();

  final String _baseUrl;
  final http.Client _httpClient;
  final AuthTokenStore _tokenStore;

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/sign-up/email',
      body: {'name': name, 'email': email, 'password': password},
    );
    final user = _userFromAuthResponse(response.body);
    final token = _tokenFromResponse(response);

    if (token != null) {
      await _tokenStore.write(token);
      return user;
    }

    return signIn(email: email, password: password);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/sign-in/email',
      body: {'email': email, 'password': password},
    );
    final user = _userFromAuthResponse(response.body);
    final token = _tokenFromResponse(response);
    if (token == null) {
      throw const AuthApiException(
        'El servidor no devolvió el token de sesión.',
      );
    }
    await _tokenStore.write(token);
    return user;
  }

  @override
  Future<AuthUser?> currentUser() async {
    final token = await _tokenStore.read();
    if (token == null) return null;

    try {
      final response = await _request(
        'GET',
        '/api/auth/get-session',
        token: token,
      );
      if (response.body.trim() == 'null') {
        await _tokenStore.delete();
        return null;
      }
      final sessionData = _decodeObject(response.body);
      final user = sessionData['user'];
      if (user == null) {
        await _tokenStore.delete();
        return null;
      }
      return AuthUser.fromJson(_asObject(user));
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStore.delete();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    final token = await _tokenStore.read();
    if (token != null) {
      await _request('POST', '/api/auth/sign-out', token: token);
    }
    await _tokenStore.delete();
  }

  @override
  Future<void> deleteAccount(String password) async {
    final token = await _tokenStore.read();
    if (token == null) {
      throw const AuthApiException(
        'Inicia sesión nuevamente para continuar.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    }
    await _request(
      'POST',
      '/api/auth/delete-user',
      token: token,
      body: {'password': password},
    );
    await _tokenStore.delete();
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? body,
    String? token,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['accept'] = 'application/json';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null) {
      request.headers['authorization'] = 'Bearer $token';
    }

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request).timeout(const Duration(seconds: 15)),
      );
    } on SocketException {
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo '
        'de nuevo.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Inténtalo de nuevo.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = _tryDecodeObject(response.body);
      final message =
          errorBody?['message'] as String? ??
          'No se pudo completar la solicitud. Inténtalo de nuevo.';
      throw AuthApiException(
        message,
        code: errorBody?['code'] as String?,
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  String? _tokenFromResponse(http.Response response) {
    final header = response.headers['set-auth-token'];
    if (header != null && header.trim().isNotEmpty) {
      return header.replaceFirst(
        RegExp(r'^Bearer\s+', caseSensitive: false),
        '',
      );
    }
    final body = _tryDecodeObject(response.body);
    final token = body?['token'];
    return token is String && token.isNotEmpty ? token : null;
  }

  AuthUser _userFromAuthResponse(String body) {
    final response = _decodeObject(body);
    return AuthUser.fromJson(_asObject(response['user']));
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      return _asObject(jsonDecode(body));
    } on FormatException {
      throw const AuthApiException(
        'El servidor devolvió una respuesta no válida. Inténtalo más tarde.',
      );
    }
  }

  Map<String, dynamic>? _tryDecodeObject(String body) {
    try {
      return _asObject(jsonDecode(body));
    } on FormatException {
      return null;
    } on AuthApiException {
      return null;
    }
  }

  Map<String, dynamic> _asObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const AuthApiException(
      'El servidor devolvió una respuesta no válida. Inténtalo más tarde.',
    );
  }
}

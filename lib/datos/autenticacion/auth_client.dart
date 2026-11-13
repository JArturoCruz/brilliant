import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

abstract interface class AuthServerStore {
  Future<String?> read();
  Future<void> write(String url);
}

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'brilliant_auth_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _guardStorage(() => _storage.read(key: _tokenKey));

  @override
  Future<void> write(String token) =>
      _guardStorage(() => _storage.write(key: _tokenKey, value: token));

  @override
  Future<void> delete() => _guardStorage(() => _storage.delete(key: _tokenKey));

  Future<T> _guardStorage<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException {
      throw const AuthApiException(
        'No se pudo acceder al almacenamiento seguro de la sesión.',
        code: 'SECURE_STORAGE_ERROR',
      );
    } on MissingPluginException {
      throw const AuthApiException(
        'El almacenamiento seguro no está disponible en esta plataforma.',
        code: 'SECURE_STORAGE_UNAVAILABLE',
      );
    }
  }
}

class SecureAuthServerStore implements AuthServerStore {
  SecureAuthServerStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _serverKey = 'brilliant_server_url';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _guard(() => _storage.read(key: _serverKey));

  @override
  Future<void> write(String url) =>
      _guard(() => _storage.write(key: _serverKey, value: url));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException {
      throw const AuthApiException(
        'No se pudo guardar la dirección del servidor.',
      );
    } on MissingPluginException {
      throw const AuthApiException(
        'El almacenamiento de la dirección no está disponible en esta plataforma.',
      );
    }
  }
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
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        email is! String ||
        !email.contains('@')) {
      throw const AuthApiException(
        'El servidor devolvió datos de cuenta no válidos.',
      );
    }
    return AuthUser(id: id, name: name, email: email);
  }
}

class AuthApiException implements Exception {
  const AuthApiException(
    this.message, {
    this.code,
    this.statusCode,
    this.requestId,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final String? requestId;

  String get userMessage => requestId == null
      ? message
      : '$message\nCódigo de referencia: $requestId';

  @override
  String toString() => message;
}

class AuthRequestDiagnostic {
  const AuthRequestDiagnostic({
    required this.requestId,
    required this.method,
    required this.path,
    required this.duration,
    required this.succeeded,
    this.statusCode,
  });

  final String requestId;
  final String method;
  final String path;
  final Duration duration;
  final bool succeeded;
  final int? statusCode;
}

class AuthClient implements AuthGateway {
  AuthClient({
    required String baseUrl,
    http.Client? httpClient,
    AuthTokenStore? tokenStore,
    AuthServerStore? serverStore,
    this.onDiagnostic,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _httpClient = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? SecureAuthTokenStore(),
       _serverStore = serverStore ?? SecureAuthServerStore();

  factory AuthClient.fromEnvironment({
    http.Client? httpClient,
    AuthTokenStore? tokenStore,
  }) {
    const configuredUrl = String.fromEnvironment('BRILLIANT_API_URL');
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final selectedUrl = configuredUrl.isNotEmpty
        ? configuredUrl
        : kReleaseMode || kIsWeb
        ? null
        : isAndroid
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    if (selectedUrl == null) {
      return AuthClient(
        baseUrl: '',
        httpClient: httpClient,
        tokenStore: tokenStore,
      );
    }

    final uri = Uri.tryParse(selectedUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
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

    final baseUrl = isAndroid && _isLoopbackHost(uri.host)
        ? uri.replace(host: '10.0.2.2').toString()
        : selectedUrl;
    return AuthClient(
      baseUrl: baseUrl,
      httpClient: httpClient,
      tokenStore: tokenStore,
    );
  }

  static final AuthClient shared = AuthClient.fromEnvironment();

  String _baseUrl;
  final http.Client _httpClient;
  final AuthTokenStore _tokenStore;
  final AuthServerStore _serverStore;
  final void Function(AuthRequestDiagnostic diagnostic)? onDiagnostic;
  static final Random _requestIdRandom = Random.secure();

  static bool _isLoopbackHost(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';

  String get baseUrl => _baseUrl;

  Future<void> restoreServer() async {
    final stored = await _serverStore.read();
    if (stored != null) {
      try {
        _baseUrl = _normalizeServerUrl(stored);
      } on AuthApiException {
        _baseUrl = '';
        rethrow;
      }
    }
  }

  static String _normalizeServerUrl(String input) {
    final value = input.trim();
    final withScheme = value.contains('://')
        ? value
        : '${kReleaseMode ? 'https' : 'http'}://$value';
    final uri = Uri.tryParse(withScheme);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        (uri.hasPort && (uri.port < 1 || uri.port > 65535))) {
      throw const AuthApiException(
        'Ingresa una dirección válida, por ejemplo 192.168.1.10:3000.',
      );
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw const AuthApiException(
        'En producción el servidor debe usar HTTPS.',
      );
    }
    return uri
        .replace(
          path: '',
          port: uri.hasPort || value.contains('://') ? null : 3000,
        )
        .toString();
  }

  Future<void> selectServer(String address) async {
    final url = _normalizeServerUrl(address);
    try {
      final request = http.Request('GET', Uri.parse('$url/health'))
        ..followRedirects = false;
      final response = await http.Response.fromStream(
        await _httpClient.send(request).timeout(const Duration(seconds: 5)),
      ).timeout(const Duration(seconds: 5));
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 ||
          body is! Map ||
          body['status'] != 'ok' ||
          body['service'] != 'brilliant') {
        throw const AuthApiException(
          'La dirección no respondió como un servidor Brilliant.',
        );
      }
    } on FormatException {
      throw const AuthApiException(
        'La dirección no respondió como un servidor Brilliant.',
      );
    } on SocketException {
      throw const AuthApiException('No se pudo conectar con ese servidor.');
    } on http.ClientException {
      throw const AuthApiException('No se pudo conectar con ese servidor.');
    } on TimeoutException {
      throw const AuthApiException('El servidor tardó demasiado en responder.');
    }
    if (url != _baseUrl) await _tokenStore.delete();
    await _serverStore.write(url);
    _baseUrl = url;
  }

  Future<http.Response> authenticatedRequest(
    String method,
    String path, {
    Object? body,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.trim().isEmpty) {
      throw const AuthApiException(
        'Inicia sesión para acceder al modo multijugador.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    }
    return _request(method, path, token: token, body: body);
  }

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
    try {
      if (token != null) {
        await _request('POST', '/api/auth/sign-out', token: token);
      }
    } finally {
      await _tokenStore.delete();
    }
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
    Object? body,
    String? token,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const AuthApiException('Selecciona un servidor para continuar.');
    }
    final requestId = _newRequestId();
    final stopwatch = Stopwatch()..start();
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..followRedirects = false
      ..headers['accept'] = 'application/json'
      ..headers['x-request-id'] = requestId;
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
      _recordDiagnostic(
        requestId: requestId,
        method: method,
        path: path,
        duration: stopwatch.elapsed,
        succeeded: false,
      );
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo '
        'de nuevo.',
      ).withRequestId(requestId);
    } on TimeoutException {
      _recordDiagnostic(
        requestId: requestId,
        method: method,
        path: path,
        duration: stopwatch.elapsed,
        succeeded: false,
      );
      throw const AuthApiException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      ).withRequestId(requestId);
    } on http.ClientException {
      _recordDiagnostic(
        requestId: requestId,
        method: method,
        path: path,
        duration: stopwatch.elapsed,
        succeeded: false,
      );
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Inténtalo de nuevo.',
      ).withRequestId(requestId);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = _tryDecodeObject(response.body);
      final retryAfter = int.tryParse(response.headers['x-retry-after'] ?? '');
      final message = response.statusCode == 429
          ? retryAfter == null
                ? 'Se hicieron demasiados intentos. Espera un momento e '
                      'inténtalo de nuevo.'
                : 'Se hicieron demasiados intentos. Vuelve a intentarlo en '
                      '$retryAfter segundos.'
          : errorBody?['message'] as String? ??
                'No se pudo completar la solicitud. Inténtalo de nuevo.';
      _recordDiagnostic(
        requestId: requestId,
        method: method,
        path: path,
        duration: stopwatch.elapsed,
        succeeded: false,
        statusCode: response.statusCode,
      );
      throw AuthApiException(
        message,
        code: errorBody?['code'] as String?,
        statusCode: response.statusCode,
        requestId: requestId,
      );
    }
    _recordDiagnostic(
      requestId: requestId,
      method: method,
      path: path,
      duration: stopwatch.elapsed,
      succeeded: true,
      statusCode: response.statusCode,
    );
    return response;
  }

  void _recordDiagnostic({
    required String requestId,
    required String method,
    required String path,
    required Duration duration,
    required bool succeeded,
    int? statusCode,
  }) {
    final diagnostic = AuthRequestDiagnostic(
      requestId: requestId,
      method: method,
      path: path,
      duration: duration,
      succeeded: succeeded,
      statusCode: statusCode,
    );
    onDiagnostic?.call(diagnostic);
    if (kDebugMode) {
      debugPrint(
        'Auth request ${diagnostic.succeeded ? 'succeeded' : 'failed'} '
        'id=${diagnostic.requestId} method=${diagnostic.method} '
        'path=${diagnostic.path} status=${diagnostic.statusCode ?? '-'} '
        'durationMs=${diagnostic.duration.inMilliseconds}',
      );
    }
  }

  String _newRequestId() {
    final bytes = List<int>.generate(16, (_) => _requestIdRandom.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
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

extension on AuthApiException {
  AuthApiException withRequestId(String id) => AuthApiException(
    message,
    code: code,
    statusCode: statusCode,
    requestId: id,
  );
}

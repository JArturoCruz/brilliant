import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/presentacion/pantalla_cuenta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthGateway implements AuthGateway {
  AuthUser? user;
  String? deletedPassword;
  bool loginCalled = false;
  AuthApiException? registrationError;
  AuthApiException? signOutError;

  static final account = AuthUser(
    id: 'user-1',
    name: 'Player One',
    email: 'player@example.com',
  );

  @override
  Future<AuthUser> register({
    required String name,
    required String password,
  }) async {
    final error = registrationError;
    if (error != null) throw error;
    user = account;
    return account;
  }

  @override
  Future<AuthUser> signIn({
    required String name,
    required String password,
  }) async {
    loginCalled = true;
    user = account;
    return account;
  }

  @override
  Future<AuthUser?> currentUser() async => user;

  @override
  Future<void> signOut() async {
    user = null;
    final error = signOutError;
    if (error != null) throw error;
  }

  @override
  Future<void> deleteAccount(String password) async {
    deletedPassword = password;
    user = null;
  }
}

void main() {
  testWidgets('rechaza contraseñas nuevas cortas o no numéricas', (
    tester,
  ) async {
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name')), 'Jugador');
    for (final password in ['12345', '12345a']) {
      await tester.enterText(
        find.byKey(const Key('account-password')),
        password,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Usa entre 6 y 128 dígitos.'), findsOneWidget);
      expect(gateway.user, isNull);
    }
  });

  testWidgets('registers, signs out, and signs back in', (tester) async {
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('account-name')), 'Player One');
    await tester.enterText(find.byKey(const Key('account-password')), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Sesión iniciada'), findsOneWidget);
    expect(find.text('Player One'), findsOneWidget);
    expect(find.text('player@example.com'), findsNothing);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¿Ya tienes cuenta? Inicia sesión'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('account-name')), 'Player One');
    await tester.enterText(find.byKey(const Key('account-password')), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(gateway.loginCalled, isTrue);
    expect(find.text('Sesión iniciada'), findsOneWidget);
  });

  testWidgets('rejects special characters in username before registration', (
    tester,
  ) async {
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('account-name')),
      "Alex'; DROP TABLE user;--",
    );
    await tester.enterText(find.byKey(const Key('account-password')), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(
      find.text('Usa solo letras, números, espacios, guiones o apóstrofes.'),
      findsOneWidget,
    );
    expect(gateway.user, isNull);
  });

  testWidgets('allows accented names and numeric passwords', (tester) async {
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name')), "O'Connor");
    await tester.enterText(find.byKey(const Key('account-password')), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(gateway.user, isNotNull);
    expect(find.text('Sesión iniciada'), findsOneWidget);
  });

  testWidgets('requires password confirmation to delete account', (
    tester,
  ) async {
    final gateway = FakeAuthGateway()..user = FakeAuthGateway.account;
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Borrar cuenta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Esta acción es permanente.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a-strong-password');
    await tester.tap(find.text('Borrar definitivamente'));
    await tester.pumpAndSettle();

    expect(gateway.deletedPassword, 'a-strong-password');
    expect(find.widgetWithText(FilledButton, 'Crear cuenta'), findsOneWidget);
  });

  testWidgets('shows a support reference when registration is rejected', (
    tester,
  ) async {
    final gateway = FakeAuthGateway()
      ..registrationError = const AuthApiException(
        'Ese nombre de usuario ya está en uso.',
        statusCode: 409,
        requestId: 'ref-123',
      );
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('account-name')), 'Player One');
    await tester.enterText(find.byKey(const Key('account-password')), '123456');

    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ese nombre de usuario ya está en uso.\nCódigo de referencia: ref-123',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('account-name')), findsOneWidget);
  });

  testWidgets('clears local account view when remote sign-out fails', (
    tester,
  ) async {
    final gateway = FakeAuthGateway()
      ..user = FakeAuthGateway.account
      ..signOutError = const AuthApiException(
        'No se pudo conectar con el servidor.',
        requestId: 'ref-logout',
      );
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Crear cuenta'), findsOneWidget);
    expect(
      find.textContaining('Código de referencia: ref-logout'),
      findsOneWidget,
    );
  });
}

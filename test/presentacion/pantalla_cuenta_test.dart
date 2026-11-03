import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/presentacion/pantalla_cuenta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthGateway implements AuthGateway {
  AuthUser? user;
  String? deletedPassword;
  bool loginCalled = false;

  static final account = AuthUser(
    id: 'user-1',
    name: 'Player One',
    email: 'player@example.com',
  );

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    user = account;
    return account;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    loginCalled = true;
    user = account;
    return account;
  }

  @override
  Future<AuthUser?> currentUser() async => user;

  @override
  Future<void> signOut() async => user = null;

  @override
  Future<void> deleteAccount(String password) async {
    deletedPassword = password;
    user = null;
  }
}

void main() {
  testWidgets('registers, signs out, and signs back in', (tester) async {
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(
      MaterialApp(home: PantallaCuenta(authGateway: gateway)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('account-name')), 'Player One');
    await tester.enterText(
      find.byKey(const Key('account-email')),
      'player@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('account-password')),
      'a-strong-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Sesión iniciada'), findsOneWidget);
    expect(find.text('player@example.com'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¿Ya tienes cuenta? Inicia sesión'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('account-email')),
      'player@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('account-password')),
      'a-strong-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(gateway.loginCalled, isTrue);
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
}

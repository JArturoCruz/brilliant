import 'package:brilliant/presentacion/widgets/boton_numero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BotonNumero', () {
    testWidgets('muestra el número recibido', (tester) async {
      await tester.pumpWidget(_envolver(BotonNumero(
        numero: 4,
        marcado: false,
        habilitado: true,
        usadoEnOtraCelda: false,
        onPressed: () {},
      )));

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('se ve como FilledButton cuando está marcado', (tester) async {
      await tester.pumpWidget(_envolver(BotonNumero(
        numero: 4,
        marcado: true,
        habilitado: true,
        usadoEnOtraCelda: false,
        onPressed: () {},
      )));

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('se ve como OutlinedButton cuando no está marcado', (tester) async {
      await tester.pumpWidget(_envolver(BotonNumero(
        numero: 4,
        marcado: false,
        habilitado: true,
        usadoEnOtraCelda: false,
        onPressed: () {},
      )));

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('al tocarlo habilitado, dispara onPressed', (tester) async {
      var tocado = false;
      await tester.pumpWidget(_envolver(BotonNumero(
        numero: 4,
        marcado: false,
        habilitado: true,
        usadoEnOtraCelda: false,
        onPressed: () => tocado = true,
      )));

      await tester.tap(find.byType(OutlinedButton));
      expect(tocado, isTrue);
    });

    testWidgets('deshabilitado, no dispara onPressed al tocarlo', (tester) async {
      var tocado = false;
      await tester.pumpWidget(_envolver(BotonNumero(
        numero: 4,
        marcado: false,
        habilitado: false,
        usadoEnOtraCelda: false,
        onPressed: () => tocado = true,
      )));

      await tester.tap(find.byType(OutlinedButton));
      expect(tocado, isFalse);
    });
  });
}

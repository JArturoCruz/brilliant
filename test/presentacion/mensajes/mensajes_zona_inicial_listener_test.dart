import 'package:brilliant/bloc/mensajes_zona_inicial.dart';
import 'package:brilliant/bloc/zona_inicial_cubit.dart';
import 'package:brilliant/presentacion/mensajes/mensajes_zona_inicial_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra un SnackBar cuando el cubit emite un mensaje', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const MensajesZonaInicialListener(
          child: Scaffold(body: SizedBox()),
        ),
      ),
    ));

    cubit.rechazarEntrada('x');
    await tester.pump(); // procesa el listener
    await tester.pump(); // anima la entrada del SnackBar

    expect(find.text(MensajesZonaInicial.caracterInvalido('x')), findsOneWidget);
    cubit.close();
  });

  testWidgets('no muestra ningún SnackBar si no se ha emitido ningún mensaje', (tester) async {
    final cubit = ZonaInicialCubit();
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const MensajesZonaInicialListener(
          child: Scaffold(body: SizedBox()),
        ),
      ),
    ));

    expect(find.byType(SnackBar), findsNothing);
    cubit.close();
  });
}

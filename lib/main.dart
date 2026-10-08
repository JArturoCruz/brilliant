import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentacion/pantalla_configuracion_inicial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JuegoBloc(), // <-- Agregas esto
      child: MaterialApp(
        title: 'Brilliant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const PantallaConfiguracionInicial(), // Tu pantalla original se mantiene[cite: 1]
      ),
    );
  }
}
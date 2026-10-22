import 'package:brilliant/presentacion/pantalla_inicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/juego_bloc.dart';
import 'bloc/zona_inicial_cubit.dart';

void main() {
  runApp(const BrilliantApp());
}

class BrilliantApp extends StatelessWidget {
  const BrilliantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<JuegoBloc>(create: (context) => JuegoBloc()),
        BlocProvider<ZonaInicialCubit>(create: (context) => ZonaInicialCubit()),
      ],
      child: MaterialApp(
        title: 'Brilliant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: const PantallaInicio(),
      ),
    );
  }
}

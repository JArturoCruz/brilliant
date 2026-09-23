import 'package:brilliant/tablero.dart';
import 'package:brilliant/zona_inicial_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Agregado para usar Bloc
// Asegúrate de importar el archivo donde esté tu ZonaInicialCubit:
// import 'package:brilliant/zona_inicial.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 1. Instanciamos la variable 'tablero' que necesita tu botón
  final TableroJuego tablero = TableroJuego();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2. ESTE ES EXACTAMENTE TU CÓDIGO APLICADO
            BlocProvider(
              create: (_) => ZonaInicialCubit(),
              child: BlocBuilder<ZonaInicialCubit, ZonaInicialState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.esValida
                        ? () => context.read<ZonaInicialCubit>().aplicarATablero(tablero)
                        : null, // deshabilitado hasta que las 6 celdas sean válidas
                    child: const Text('Continuar'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:brilliant/datos/autenticacion/auth_client.dart';
import 'package:brilliant/presentacion/pantalla_inicio.dart';
import 'package:brilliant/presentacion/tema_mesa.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BrilliantApp());
}

class BrilliantApp extends StatelessWidget {
  const BrilliantApp({this.authGateway, super.key});

  final AuthGateway? authGateway;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brilliant',
      debugShowCheckedModeBanner: false,
      theme: TemaMesa.data,
      home: PantallaInicio(authGateway: authGateway ?? AuthClient.shared),
    );
  }
}

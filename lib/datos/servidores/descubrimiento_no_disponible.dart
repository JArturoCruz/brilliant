Future<List<String>> descubrirServidores({
  int puerto = 38971,
  String destino = '255.255.255.255',
  Duration espera = const Duration(seconds: 2),
}) async {
  throw UnsupportedError(
    'La búsqueda automática no está disponible en el navegador. '
    'Escribe la dirección del servidor.',
  );
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<List<String>> descubrirServidores({
  int puerto = 38971,
  String destino = '255.255.255.255',
  Duration espera = const Duration(seconds: 2),
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final random = Random.secure();
  final nonce = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  final servers = <String>{};
  final finished = Completer<void>();
  try {
    socket.broadcastEnabled = true;
    socket.listen(
      (event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        final message = utf8.decode(datagram.data, allowMalformed: true);
        final match = RegExp('^BRILLIANT_SERVER_V1:$nonce:([0-9]{1,5})\$')
            .firstMatch(message);
        final port = match == null ? null : int.tryParse(match.group(1)!);
        if (port == null || port < 1 || port > 65535) return;
        servers.add('http://${datagram.address.address}:$port');
      },
      onError: (Object error, StackTrace stack) {
        if (!finished.isCompleted) finished.completeError(error, stack);
      },
    );
    final request = utf8.encode('BRILLIANT_DISCOVER_V1:$nonce');
    if (socket.send(request, InternetAddress(destino), puerto) == 0) {
      throw const SocketException('No se pudo enviar la búsqueda.');
    }
    await Future.any([finished.future, Future<void>.delayed(espera)]);
  } finally {
    socket.close();
  }
  return servers.toList()..sort();
}

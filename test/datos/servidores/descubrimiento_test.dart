import 'dart:convert';
import 'dart:io';

import 'package:brilliant/datos/servidores/descubrimiento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('descubre respuestas válidas y descarta respuestas ajenas', () async {
    final server = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(server.close);
    server.listen((event) async {
      if (event != RawSocketEvent.read) return;
      final datagram = server.receive();
      if (datagram == null) return;
      final request = utf8.decode(datagram.data);
      final nonce = request.split(':').last;
      for (final response in [
        'BRILLIANT_SERVER_V1:incorrecto:3000',
        'BRILLIANT_SERVER_V1:$nonce:99999',
        'BRILLIANT_SERVER_V1:$nonce:3000',
        'BRILLIANT_SERVER_V1:$nonce:3000',
      ]) {
        // send devuelve 0 y descarta el datagrama si el socket no está listo.
        while (server.send(
              utf8.encode(response),
              datagram.address,
              datagram.port,
            ) ==
            0) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      }
    });

    final found = await descubrirServidores(
      puerto: server.port,
      destino: '127.0.0.1',
      espera: const Duration(seconds: 1),
    );
    expect(found, ['http://127.0.0.1:3000']);
  });
}

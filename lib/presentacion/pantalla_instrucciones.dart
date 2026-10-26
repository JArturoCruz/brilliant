import 'package:flutter/material.dart';

import 'widgets/instrucciones_juego_widget.dart';

class PantallaInstrucciones extends StatelessWidget {
  const PantallaInstrucciones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instrucciones')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth < 720 ? 560.0 : 800.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: const InstruccionesJuegoWidget(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

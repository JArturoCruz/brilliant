import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../tema_mesa.dart';

class HistorialPartidaWidget extends StatelessWidget {
  const HistorialPartidaWidget({
    super.key,
    this.height = 100,
    this.showEmptyMessage = false,
  });

  final double height;
  final bool showEmptyMessage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, state) {
        if (state.historial.isEmpty && !showEmptyMessage) {
          return const SizedBox.shrink();
        }

        return Container(
          height: height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TemaMesa.papel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TemaMesa.nogal.withAlpha(55)),
          ),
          child: state.historial.isEmpty
              ? const Center(child: Text('Aún no hay actividad registrada.'))
              : ListView.builder(
                  itemCount: state.historial.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        state.historial[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: index == 0
                              ? TemaMesa.verde
                              : TemaMesa.nogal.withAlpha(170),
                          fontWeight: index == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

import 'package:brilliant/bloc/juego_bloc.dart';
import 'package:brilliant/bloc/juego_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistorialPartidaWidget extends StatelessWidget {
  const HistorialPartidaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JuegoBloc, JuegoState>(
      builder: (context, state) {
        if (state.historial.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: ListView.builder(
            itemCount: state.historial.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  state.historial[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: index == 0 ? Colors.amberAccent : Colors.grey.shade400,
                    fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
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
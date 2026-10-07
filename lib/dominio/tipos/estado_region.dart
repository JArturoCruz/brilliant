import 'tipo.dart';

/// Estado de una región (según el diagrama original del proyecto).
enum EstadoRegion {
  incompleta,
  completa,
  completaConBonificacion,
}

/// Deriva el estado de una región reutilizando `esPosibleAgregar` como
/// única fuente de verdad de cada regla, sin que ningún Tipo necesite
/// saber nada sobre "estados" (principio Abierto/Cerrado).
extension TipoEstadoRegion on Tipo {
  bool regionEsValida(List<int> valores) {
    for (var i = 0; i < valores.length; i++) {
      final resto = List<int>.from(valores)..removeAt(i);
      if (!esPosibleAgregar(resto, valores[i])) return false;
    }
    return true;
  }

  EstadoRegion calcularEstado(List<int?> valoresCompletos) {
    if (valoresCompletos.contains(null)) return EstadoRegion.incompleta;
    final valores = valoresCompletos.whereType<int>().toList();
    return regionEsValida(valores)
        ? EstadoRegion.completa
        : EstadoRegion.incompleta;
  }
}

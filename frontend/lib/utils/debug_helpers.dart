import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/utils/loggers.dart';

/// Utilidades para debugging de pedidos
class DebugHelpers {
  /// Verifica duplicados en una lista de pedidos
  /// Solo logea si hay duplicados detectados
  static void checkDuplicates(List<Pedido> pedidos, String context) {
    final ids = pedidos.map((p) => p.id).toList();
    final uniqueIds = ids.toSet();

    if (ids.length != uniqueIds.length) {
      final duplicateIds = ids
          .fold<Map<String, int>>(<String, int>{}, (map, id) {
            map[id] = (map[id] ?? 0) + 1;
            return map;
          })
          .entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toList();

      logWarning(
          '[$context] ${ids.length - uniqueIds.length} duplicados encontrados - IDs: ${duplicateIds.join(', ')}');
    }
  }
}

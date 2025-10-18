import 'package:medrush/models/usuario.model.dart';

/// Modelo para las métricas de repartidores
class MetricasRepartidor {
  final int id;
  final String repartidorId;
  final String repartidorNombre;
  final DateTime fecha;

  // Métricas de entregas
  final int totalPedidos;
  final int pedidosEntregados;
  final int pedidosFallidos;
  final int pedidosCancelados;

  // Métricas de tiempo
  final double tiempoPromedioEntrega; // En minutos
  final double tiempoTotalEnRuta; // En minutos
  final int tiempoDescanso; // En minutos

  // Métricas de distancia
  final double distanciaTotalRecorrida; // En kilómetros
  final double distanciaPromedioPorPedido; // En kilómetros

  // Métricas de códigos postales
  final List<MetricaCodigoPostal> metricasPorCodigoPostal;

  // Métricas de pagos
  final double pagoPorPaquete;
  final double pagoTotal;
  final double pagoBase;
  final double pagoBonificacion;
  final String? notasPago;

  // Estados del repartidor
  final EstadoRepartidor estadoInicial;
  final EstadoRepartidor estadoFinal;
  final List<CambioEstado> cambiosEstado;

  // Timestamps
  final DateTime fechaCreacion;
  final DateTime fechaUltimaActualizacion;

  const MetricasRepartidor({
    required this.id,
    required this.repartidorId,
    required this.repartidorNombre,
    required this.fecha,
    required this.totalPedidos,
    required this.pedidosEntregados,
    required this.pedidosFallidos,
    required this.pedidosCancelados,
    required this.tiempoPromedioEntrega,
    required this.tiempoTotalEnRuta,
    required this.tiempoDescanso,
    required this.distanciaTotalRecorrida,
    required this.distanciaPromedioPorPedido,
    required this.metricasPorCodigoPostal,
    required this.pagoPorPaquete,
    required this.pagoTotal,
    required this.pagoBase,
    required this.pagoBonificacion,
    this.notasPago,
    required this.estadoInicial,
    required this.estadoFinal,
    required this.cambiosEstado,
    required this.fechaCreacion,
    required this.fechaUltimaActualizacion,
  });

  factory MetricasRepartidor.fromJson(Map<String, dynamic> json) {
    return MetricasRepartidor(
      id: json['id'] as int,
      repartidorId: json['repartidor_id'] as String,
      repartidorNombre: json['repartidor_nombre'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      totalPedidos: json['total_pedidos'] as int? ?? 0,
      pedidosEntregados: json['pedidos_entregados'] as int? ?? 0,
      pedidosFallidos: json['pedidos_fallidos'] as int? ?? 0,
      pedidosCancelados: json['pedidos_cancelados'] as int? ?? 0,
      tiempoPromedioEntrega:
          (json['tiempo_promedio_entrega'] as num?)?.toDouble() ?? 0.0,
      tiempoTotalEnRuta:
          (json['tiempo_total_en_ruta'] as num?)?.toDouble() ?? 0.0,
      tiempoDescanso: json['tiempo_descanso'] as int? ?? 0,
      distanciaTotalRecorrida:
          (json['distancia_total_recorrida'] as num?)?.toDouble() ?? 0.0,
      distanciaPromedioPorPedido:
          (json['distancia_promedio_por_pedido'] as num?)?.toDouble() ?? 0.0,
      metricasPorCodigoPostal:
          (json['metricas_por_codigo_postal'] as List<dynamic>?)
                  ?.map((m) =>
                      MetricaCodigoPostal.fromJson(m as Map<String, dynamic>))
                  .toList() ??
              [],
      pagoPorPaquete: (json['pago_por_paquete'] as num?)?.toDouble() ?? 0.0,
      pagoTotal: (json['pago_total'] as num?)?.toDouble() ?? 0.0,
      pagoBase: (json['pago_base'] as num?)?.toDouble() ?? 0.0,
      pagoBonificacion: (json['pago_bonificacion'] as num?)?.toDouble() ?? 0.0,
      notasPago: json['notas_pago'] as String?,
      estadoInicial: EstadoRepartidor.values.firstWhere(
        (e) => e.name == json['estado_inicial'],
        orElse: () => EstadoRepartidor.disponible,
      ),
      estadoFinal: EstadoRepartidor.values.firstWhere(
        (e) => e.name == json['estado_final'],
        orElse: () => EstadoRepartidor.disponible,
      ),
      cambiosEstado: (json['cambios_estado'] as List<dynamic>?)
              ?.map((c) => CambioEstado.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaUltimaActualizacion:
          DateTime.parse(json['fecha_ultima_actualizacion'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repartidor_id': repartidorId,
      'repartidor_nombre': repartidorNombre,
      'fecha': fecha.toIso8601String(),
      'total_pedidos': totalPedidos,
      'pedidos_entregados': pedidosEntregados,
      'pedidos_fallidos': pedidosFallidos,
      'pedidos_cancelados': pedidosCancelados,
      'tiempo_promedio_entrega': tiempoPromedioEntrega,
      'tiempo_total_en_ruta': tiempoTotalEnRuta,
      'tiempo_descanso': tiempoDescanso,
      'distancia_total_recorrida': distanciaTotalRecorrida,
      'distancia_promedio_por_pedido': distanciaPromedioPorPedido,
      'metricas_por_codigo_postal':
          metricasPorCodigoPostal.map((m) => m.toJson()).toList(),
      'pago_por_paquete': pagoPorPaquete,
      'pago_total': pagoTotal,
      'pago_base': pagoBase,
      'pago_bonificacion': pagoBonificacion,
      'notas_pago': notasPago,
      'estado_inicial': estadoInicial.name,
      'estado_final': estadoFinal.name,
      'cambios_estado': cambiosEstado.map((c) => c.toJson()).toList(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_ultima_actualizacion': fechaUltimaActualizacion.toIso8601String(),
    };
  }

  // Getters útiles
  double get tasaExito =>
      totalPedidos > 0 ? pedidosEntregados / totalPedidos : 0.0;
  double get tasaFallo =>
      totalPedidos > 0 ? pedidosFallidos / totalPedidos : 0.0;
  int get pedidosPendientes =>
      totalPedidos - pedidosEntregados - pedidosFallidos - pedidosCancelados;
  double get eficiencia => tiempoTotalEnRuta > 0
      ? pedidosEntregados / (tiempoTotalEnRuta / 60)
      : 0.0;

  // Obtener métricas por código postal
  MetricaCodigoPostal? getMetricaPorCodigoPostal(String codigoPostal) {
    try {
      return metricasPorCodigoPostal
          .firstWhere((m) => m.codigoPostal == codigoPostal);
    } catch (e) {
      return null;
    }
  }

  // Obtener códigos postales más frecuentes
  List<String> get codigosPostalesMasFrecuentes {
    final sorted = List<MetricaCodigoPostal>.from(metricasPorCodigoPostal)
      ..sort((a, b) => b.totalPedidos.compareTo(a.totalPedidos));
    return sorted.take(5).map((m) => m.codigoPostal).toList();
  }

  MetricasRepartidor copyWith({
    int? id,
    String? repartidorId,
    String? repartidorNombre,
    DateTime? fecha,
    int? totalPedidos,
    int? pedidosEntregados,
    int? pedidosFallidos,
    int? pedidosCancelados,
    double? tiempoPromedioEntrega,
    double? tiempoTotalEnRuta,
    int? tiempoDescanso,
    double? distanciaTotalRecorrida,
    double? distanciaPromedioPorPedido,
    List<MetricaCodigoPostal>? metricasPorCodigoPostal,
    double? pagoPorPaquete,
    double? pagoTotal,
    double? pagoBase,
    double? pagoBonificacion,
    String? notasPago,
    EstadoRepartidor? estadoInicial,
    EstadoRepartidor? estadoFinal,
    List<CambioEstado>? cambiosEstado,
    DateTime? fechaCreacion,
    DateTime? fechaUltimaActualizacion,
  }) {
    return MetricasRepartidor(
      id: id ?? this.id,
      repartidorId: repartidorId ?? this.repartidorId,
      repartidorNombre: repartidorNombre ?? this.repartidorNombre,
      fecha: fecha ?? this.fecha,
      totalPedidos: totalPedidos ?? this.totalPedidos,
      pedidosEntregados: pedidosEntregados ?? this.pedidosEntregados,
      pedidosFallidos: pedidosFallidos ?? this.pedidosFallidos,
      pedidosCancelados: pedidosCancelados ?? this.pedidosCancelados,
      tiempoPromedioEntrega:
          tiempoPromedioEntrega ?? this.tiempoPromedioEntrega,
      tiempoTotalEnRuta: tiempoTotalEnRuta ?? this.tiempoTotalEnRuta,
      tiempoDescanso: tiempoDescanso ?? this.tiempoDescanso,
      distanciaTotalRecorrida:
          distanciaTotalRecorrida ?? this.distanciaTotalRecorrida,
      distanciaPromedioPorPedido:
          distanciaPromedioPorPedido ?? this.distanciaPromedioPorPedido,
      metricasPorCodigoPostal:
          metricasPorCodigoPostal ?? this.metricasPorCodigoPostal,
      pagoPorPaquete: pagoPorPaquete ?? this.pagoPorPaquete,
      pagoTotal: pagoTotal ?? this.pagoTotal,
      pagoBase: pagoBase ?? this.pagoBase,
      pagoBonificacion: pagoBonificacion ?? this.pagoBonificacion,
      notasPago: notasPago ?? this.notasPago,
      estadoInicial: estadoInicial ?? this.estadoInicial,
      estadoFinal: estadoFinal ?? this.estadoFinal,
      cambiosEstado: cambiosEstado ?? this.cambiosEstado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaUltimaActualizacion:
          fechaUltimaActualizacion ?? this.fechaUltimaActualizacion,
    );
  }
}

/// Modelo para métricas por código postal
class MetricaCodigoPostal {
  final String codigoPostal;
  final String distrito;
  final int totalPedidos;
  final int pedidosEntregados;
  final int pedidosFallidos;
  final double tiempoPromedioEntrega;
  final double distanciaPromedio;
  final double pagoTotal;

  const MetricaCodigoPostal({
    required this.codigoPostal,
    required this.distrito,
    required this.totalPedidos,
    required this.pedidosEntregados,
    required this.pedidosFallidos,
    required this.tiempoPromedioEntrega,
    required this.distanciaPromedio,
    required this.pagoTotal,
  });

  factory MetricaCodigoPostal.fromJson(Map<String, dynamic> json) {
    return MetricaCodigoPostal(
      codigoPostal: json['codigo_postal'] as String,
      distrito: json['distrito'] as String,
      totalPedidos: json['total_pedidos'] as int? ?? 0,
      pedidosEntregados: json['pedidos_entregados'] as int? ?? 0,
      pedidosFallidos: json['pedidos_fallidos'] as int? ?? 0,
      tiempoPromedioEntrega:
          (json['tiempo_promedio_entrega'] as num?)?.toDouble() ?? 0.0,
      distanciaPromedio:
          (json['distancia_promedio'] as num?)?.toDouble() ?? 0.0,
      pagoTotal: (json['pago_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_postal': codigoPostal,
      'distrito': distrito,
      'total_pedidos': totalPedidos,
      'pedidos_entregados': pedidosEntregados,
      'pedidos_fallidos': pedidosFallidos,
      'tiempo_promedio_entrega': tiempoPromedioEntrega,
      'distancia_promedio': distanciaPromedio,
      'pago_total': pagoTotal,
    };
  }

  // Getters útiles
  double get tasaExito =>
      totalPedidos > 0 ? pedidosEntregados / totalPedidos : 0.0;
  double get tasaFallo =>
      totalPedidos > 0 ? pedidosFallidos / totalPedidos : 0.0;
  int get pedidosPendientes =>
      totalPedidos - pedidosEntregados - pedidosFallidos;
}

/// Modelo para cambios de estado del repartidor
class CambioEstado {
  final int id;
  final EstadoRepartidor estadoAnterior;
  final EstadoRepartidor estadoNuevo;
  final DateTime fechaCambio;
  final String? motivo;
  final String? ubicacion;

  const CambioEstado({
    required this.id,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.fechaCambio,
    this.motivo,
    this.ubicacion,
  });

  factory CambioEstado.fromJson(Map<String, dynamic> json) {
    return CambioEstado(
      id: json['id'] as int,
      estadoAnterior: EstadoRepartidor.values.firstWhere(
        (e) => e.name == json['estado_anterior'],
        orElse: () => EstadoRepartidor.disponible,
      ),
      estadoNuevo: EstadoRepartidor.values.firstWhere(
        (e) => e.name == json['estado_nuevo'],
        orElse: () => EstadoRepartidor.disponible,
      ),
      fechaCambio: DateTime.parse(json['fecha_cambio'] as String),
      motivo: json['motivo'] as String?,
      ubicacion: json['ubicacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estado_anterior': estadoAnterior.name,
      'estado_nuevo': estadoNuevo.name,
      'fecha_cambio': fechaCambio.toIso8601String(),
      'motivo': motivo,
      'ubicacion': ubicacion,
    };
  }

  // Getters útiles
  Duration get duracionEstado => DateTime.now().difference(fechaCambio);
  bool get esCambioReciente => duracionEstado.inMinutes < 30;
}

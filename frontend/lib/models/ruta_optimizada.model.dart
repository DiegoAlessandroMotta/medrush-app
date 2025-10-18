class RutaOptimizada {
  final String id;
  final String? repartidorId;
  final String? nombre;
  final Map<String, dynamic>? puntoInicio;
  final Map<String, dynamic>? puntoFinal;
  final String? polylineEncoded;
  final double? distanciaTotalEstimada;
  final int? tiempoTotalEstimado;
  final int? cantidadPedidos;
  final DateTime? fechaHoraCalculo;
  final DateTime? fechaInicio;
  final DateTime? fechaCompletado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? repartidor;
  final List<Map<String, dynamic>>? pedidos;

  const RutaOptimizada({
    required this.id,
    this.repartidorId,
    this.nombre,
    this.puntoInicio,
    this.puntoFinal,
    this.polylineEncoded,
    this.distanciaTotalEstimada,
    this.tiempoTotalEstimado,
    this.cantidadPedidos,
    this.fechaHoraCalculo,
    this.fechaInicio,
    this.fechaCompletado,
    this.createdAt,
    this.updatedAt,
    this.repartidor,
    this.pedidos,
  });

  factory RutaOptimizada.fromJson(Map<String, dynamic> json) {
    // FIX: Manejar estructura del backend Laravel
    return RutaOptimizada(
      id: json['id'] as String,
      repartidorId: json['repartidor_id'] as String?,
      nombre: json['nombre'] as String?,
      puntoInicio: json['punto_inicio'] as Map<String, dynamic>?,
      puntoFinal: json['punto_final'] as Map<String, dynamic>?,
      polylineEncoded: json['polyline_encoded'] as String?,
      distanciaTotalEstimada:
          (json['distancia_total_estimada'] as num?)?.toDouble(),
      tiempoTotalEstimado: json['tiempo_total_estimado'] as int?,
      cantidadPedidos: json['cantidad_pedidos'] as int?,
      fechaHoraCalculo: json['fecha_hora_calculo'] != null
          ? DateTime.parse(json['fecha_hora_calculo'] as String)
          : null,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      fechaCompletado: json['fecha_completado'] != null
          ? DateTime.parse(json['fecha_completado'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // FIX: Manejar estructura anidada del backend
      repartidor: json['repartidor'] != null
          ? json['repartidor'] as Map<String, dynamic>
          : null,
      pedidos: json['pedidos'] != null
          ? (json['pedidos'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repartidor_id': repartidorId,
      'nombre': nombre,
      'punto_inicio': puntoInicio,
      'punto_final': puntoFinal,
      'polyline_encoded': polylineEncoded,
      'distancia_total_estimada': distanciaTotalEstimada,
      'tiempo_total_estimado': tiempoTotalEstimado,
      'cantidad_pedidos': cantidadPedidos,
      'fecha_hora_calculo': fechaHoraCalculo?.toIso8601String(),
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_completado': fechaCompletado?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'repartidor': repartidor,
      'pedidos': pedidos,
    };
  }

  RutaOptimizada copyWith({
    String? id,
    String? repartidorId,
    String? nombre,
    Map<String, dynamic>? puntoInicio,
    Map<String, dynamic>? puntoFinal,
    String? polylineEncoded,
    double? distanciaTotalEstimada,
    int? tiempoTotalEstimado,
    int? cantidadPedidos,
    DateTime? fechaHoraCalculo,
    DateTime? fechaInicio,
    DateTime? fechaCompletado,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? repartidor,
    List<Map<String, dynamic>>? pedidos,
  }) {
    return RutaOptimizada(
      id: id ?? this.id,
      repartidorId: repartidorId ?? this.repartidorId,
      nombre: nombre ?? this.nombre,
      puntoInicio: puntoInicio ?? this.puntoInicio,
      puntoFinal: puntoFinal ?? this.puntoFinal,
      polylineEncoded: polylineEncoded ?? this.polylineEncoded,
      distanciaTotalEstimada:
          distanciaTotalEstimada ?? this.distanciaTotalEstimada,
      tiempoTotalEstimado: tiempoTotalEstimado ?? this.tiempoTotalEstimado,
      cantidadPedidos: cantidadPedidos ?? this.cantidadPedidos,
      fechaHoraCalculo: fechaHoraCalculo ?? this.fechaHoraCalculo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      repartidor: repartidor ?? this.repartidor,
      pedidos: pedidos ?? this.pedidos,
    );
  }

  @override
  String toString() {
    return 'RutaOptimizada(id: $id, repartidorId: $repartidorId, nombre: $nombre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RutaOptimizada && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

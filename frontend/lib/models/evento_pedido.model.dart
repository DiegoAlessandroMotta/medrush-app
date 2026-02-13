import 'package:medrush/l10n/app_localizations.dart';

// Tipos de eventos del sistema (alineados con EventosPedidoEnum del backend)
enum TipoEvento {
  // Eventos principales de pedidos
  creado,
  asignado,
  recogido,
  enRuta,
  entregado,
  fallido,
  cancelado,
  reagendado,

  // Eventos del sistema (para compatibilidad)
  pedidoCreado,
  pedidoAsignado,
  pedidoRecogido,
  pedidoEnRuta,
  pedidoEntregado,
  pedidoFallido,
  pedidoCancelado,
  rutaOptimizada,
  ubicacionActualizada,
  repartidorConectado,
  repartidorDesconectado,
  farmaciaConectada,
  farmaciaDesconectada,
  notificacionEnviada,
}

class EventoPedido {
  final int id;
  final int pedidoId;
  final TipoEvento tipo;
  final String descripcion;
  final DateTime fecha;
  final double? latitud;
  final double? longitud;
  final String? metadata;

  // Campos adicionales del backend
  final String? usuarioId;
  final String? usuarioNombre;
  final Map<String, dynamic>? datosAdicionales;

  const EventoPedido({
    required this.id,
    required this.pedidoId,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    this.latitud,
    this.longitud,
    this.metadata,
    this.usuarioId,
    this.usuarioNombre,
    this.datosAdicionales,
  });

  factory EventoPedido.fromJson(Map<String, dynamic> json) {
    return EventoPedido(
      id: json['id'] as int,
      pedidoId: json['pedido_id'] as int,
      tipo: _parseTipoEvento(json['tipo']),
      descripcion:
          json['descripcion'] as String? ?? json['mensaje'] as String? ?? '',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      latitud:
          json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
      longitud: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : null,
      metadata:
          json['metadata'] as String? ?? json['datos_adicionales'] as String?,
      usuarioId: json['usuario_id'] as String?,
      usuarioNombre: json['usuario_nombre'] as String?,
      datosAdicionales: json['datos_adicionales'] as Map<String, dynamic>?,
    );
  }

  static TipoEvento _parseTipoEvento(tipo) {
    if (tipo == null) {
      return TipoEvento.creado;
    }

    final tipoStr = tipo.toString().toLowerCase();
    switch (tipoStr) {
      case 'creado':
      case 'pedido_creado':
        return TipoEvento.creado;
      case 'asignado':
      case 'pedido_asignado':
        return TipoEvento.asignado;
      case 'recogido':
      case 'pedido_recogido':
        return TipoEvento.recogido;
      case 'en_ruta':
      case 'enruta':
      case 'pedido_en_ruta':
        return TipoEvento.enRuta;
      case 'entregado':
      case 'pedido_entregado':
        return TipoEvento.entregado;
      case 'fallido':
      case 'fallo':
      case 'pedido_fallido':
        return TipoEvento.fallido;
      case 'cancelado':
      case 'pedido_cancelado':
        return TipoEvento.cancelado;
      case 'reagendado':
        return TipoEvento.reagendado;
      case 'ruta_optimizada':
        return TipoEvento.rutaOptimizada;
      case 'ubicacion_actualizada':
        return TipoEvento.ubicacionActualizada;
      case 'repartidor_conectado':
        return TipoEvento.repartidorConectado;
      case 'repartidor_desconectado':
        return TipoEvento.repartidorDesconectado;
      case 'farmacia_conectada':
        return TipoEvento.farmaciaConectada;
      case 'farmacia_desconectada':
        return TipoEvento.farmaciaDesconectada;
      case 'notificacion_enviada':
        return TipoEvento.notificacionEnviada;
      default:
        return TipoEvento.creado;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pedido_id': pedidoId,
      'tipo': _tipoEventoToBackend(tipo),
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'latitud': latitud,
      'longitud': longitud,
      'metadata': metadata,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'datos_adicionales': datosAdicionales,
    };
  }

  static String _tipoEventoToBackend(TipoEvento tipo) {
    switch (tipo) {
      case TipoEvento.creado:
        return 'creado';
      case TipoEvento.asignado:
        return 'asignado';
      case TipoEvento.recogido:
        return 'recogido';
      case TipoEvento.enRuta:
        return 'en_ruta';
      case TipoEvento.entregado:
        return 'entregado';
      case TipoEvento.fallido:
        return 'fallido';
      case TipoEvento.cancelado:
        return 'cancelado';
      case TipoEvento.reagendado:
        return 'reagendado';
      case TipoEvento.rutaOptimizada:
        return 'ruta_optimizada';
      case TipoEvento.ubicacionActualizada:
        return 'ubicacion_actualizada';
      case TipoEvento.repartidorConectado:
        return 'repartidor_conectado';
      case TipoEvento.repartidorDesconectado:
        return 'repartidor_desconectado';
      case TipoEvento.farmaciaConectada:
        return 'farmacia_conectada';
      case TipoEvento.farmaciaDesconectada:
        return 'farmacia_desconectada';
      case TipoEvento.notificacionEnviada:
        return 'notificacion_enviada';
      default:
        return 'creado';
    }
  }

  String tipoTexto(AppLocalizations l10n) {
    switch (tipo) {
      case TipoEvento.creado:
        return l10n.eventTypeCreated;
      case TipoEvento.asignado:
        return l10n.eventTypeAssigned;
      case TipoEvento.recogido:
        return l10n.eventTypePickedUp;
      case TipoEvento.enRuta:
        return l10n.eventTypeInRoute;
      case TipoEvento.entregado:
        return l10n.eventTypeDelivered;
      case TipoEvento.fallido:
        return l10n.eventTypeFailed;
      case TipoEvento.cancelado:
        return l10n.eventTypeCancelled;
      case TipoEvento.reagendado:
        return l10n.eventTypeRescheduled;
      // Eventos del sistema
      case TipoEvento.pedidoCreado:
        return l10n.eventTypeOrderCreated;
      case TipoEvento.pedidoAsignado:
        return l10n.eventTypeOrderAssigned;
      case TipoEvento.pedidoRecogido:
        return l10n.eventTypePickedUp;
      case TipoEvento.pedidoEnRuta:
        return l10n.eventTypeInRoute;
      case TipoEvento.pedidoEntregado:
        return l10n.eventTypeDelivered;
      case TipoEvento.pedidoFallido:
        return l10n.eventTypeFailed;
      case TipoEvento.pedidoCancelado:
        return l10n.eventTypeCancelled;
      case TipoEvento.rutaOptimizada:
        return l10n.eventTypeRouteOptimized;
      case TipoEvento.ubicacionActualizada:
        return l10n.eventTypeLocationUpdated;
      case TipoEvento.repartidorConectado:
        return l10n.eventTypeDriverConnected;
      case TipoEvento.repartidorDesconectado:
        return l10n.eventTypeDriverDisconnected;
      case TipoEvento.farmaciaConectada:
        return l10n.eventTypePharmacyConnected;
      case TipoEvento.farmaciaDesconectada:
        return l10n.eventTypePharmacyDisconnected;
      case TipoEvento.notificacionEnviada:
        return l10n.eventTypeNotificationSent;
    }
  }

  // Getters útiles
  bool get esEventoPrincipal => [
        TipoEvento.creado,
        TipoEvento.asignado,
        TipoEvento.recogido,
        TipoEvento.enRuta,
        TipoEvento.entregado,
        TipoEvento.fallido,
        TipoEvento.cancelado,
      ].contains(tipo);

  bool get esEventoSistema => !esEventoPrincipal;

  bool get requiereAccion => [
        TipoEvento.fallido,
        TipoEvento.cancelado,
        TipoEvento.reagendado,
      ].contains(tipo);

  Duration get tiempoDesdeEvento => DateTime.now().difference(fecha);
  bool get esReciente => tiempoDesdeEvento.inMinutes < 30;
}

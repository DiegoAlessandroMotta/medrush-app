import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/utils/status_helpers.dart';

/// Modelo para las notificaciones del sistema
class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final TipoNotificacion tipo;
  final EstadoNotificacion estado;
  final String? destinatarioId;
  final TipoUsuario tipoDestinatario;
  final String? remitenteId;
  final TipoUsuario tipoRemitente;

  // Datos específicos de la notificación
  final Map<String, dynamic>? datosAdicionales;
  final String? urlAccion;
  final String? icono;

  // Configuración de entrega
  final bool requiereConfirmacion;
  final bool esUrgente;
  final int prioridad; // 1-5, donde 5 es la más alta

  // Timestamps
  final DateTime fechaCreacion;
  final DateTime? fechaEnvio;
  final DateTime? fechaLectura;
  final DateTime? fechaExpiracion;

  // Intentos de envío
  final int intentosEnvio;
  final String? errorUltimoIntento;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.estado,
    this.destinatarioId,
    required this.tipoDestinatario,
    this.remitenteId,
    required this.tipoRemitente,
    this.datosAdicionales,
    this.urlAccion,
    this.icono,
    this.requiereConfirmacion = false,
    this.esUrgente = false,
    this.prioridad = 3,
    required this.fechaCreacion,
    this.fechaEnvio,
    this.fechaLectura,
    this.fechaExpiracion,
    this.intentosEnvio = 0,
    this.errorUltimoIntento,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: TipoNotificacion.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoNotificacion.informacion,
      ),
      estado: EstadoNotificacion.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoNotificacion.pendiente,
      ),
      destinatarioId: json['destinatario_id'] as String?,
      tipoDestinatario: TipoUsuario.values.firstWhere(
        (e) => e.name == json['tipo_destinatario'],
        orElse: () => TipoUsuario.administrador,
      ),
      remitenteId: json['remitente_id'] as String?,
      tipoRemitente: TipoUsuario.values.firstWhere(
        (e) => e.name == json['tipo_remitente'],
        orElse: () => TipoUsuario.administrador,
      ),
      datosAdicionales: json['datos_adicionales'] as Map<String, dynamic>?,
      urlAccion: json['url_accion'] as String?,
      icono: json['icono'] as String?,
      requiereConfirmacion: json['requiere_confirmacion'] as bool? ?? false,
      esUrgente: json['es_urgente'] as bool? ?? false,
      prioridad: json['prioridad'] as int? ?? 3,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaEnvio: json['fecha_envio'] != null
          ? DateTime.parse(json['fecha_envio'] as String)
          : null,
      fechaLectura: json['fecha_lectura'] != null
          ? DateTime.parse(json['fecha_lectura'] as String)
          : null,
      fechaExpiracion: json['fecha_expiracion'] != null
          ? DateTime.parse(json['fecha_expiracion'] as String)
          : null,
      intentosEnvio: json['intentos_envio'] as int? ?? 0,
      errorUltimoIntento: json['error_ultimo_intento'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo.name,
      'estado': estado.name,
      'destinatario_id': destinatarioId,
      'tipo_destinatario': tipoDestinatario.name,
      'remitente_id': remitenteId,
      'tipo_remitente': tipoRemitente.name,
      'datos_adicionales': datosAdicionales,
      'url_accion': urlAccion,
      'icono': icono,
      'requiere_confirmacion': requiereConfirmacion,
      'es_urgente': esUrgente,
      'prioridad': prioridad,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_envio': fechaEnvio?.toIso8601String(),
      'fecha_lectura': fechaLectura?.toIso8601String(),
      'fecha_expiracion': fechaExpiracion?.toIso8601String(),
      'intentos_envio': intentosEnvio,
      'error_ultimo_intento': errorUltimoIntento,
    };
  }

  // Getters útiles
  bool get estaExpirada =>
      fechaExpiracion != null && DateTime.now().isAfter(fechaExpiracion!);
  bool get puedeReenviar =>
      estado == EstadoNotificacion.fallida &&
      intentosEnvio < 3 &&
      !estaExpirada;
  bool get requiereAccion =>
      requiereConfirmacion && estado == EstadoNotificacion.enviada;
  Duration get tiempoDesdeCreacion => DateTime.now().difference(fechaCreacion);
  Duration get tiempoDesdeEnvio => fechaEnvio != null
      ? DateTime.now().difference(fechaEnvio!)
      : Duration.zero;

  // Crear notificaciones específicas
  factory Notificacion.pedidoEstado({
    required String pedidoId,
    required String codigoBarra,
    required EstadoPedido estadoAnterior,
    required EstadoPedido estadoNuevo,
    required String destinatarioId,
    required TipoUsuario tipoDestinatario,
    required AppLocalizations l10n,
    String? repartidorId,
    String? repartidorNombre,
  }) {
    final titulo = l10n.notificationOrderStatusUpdated;
    final mensaje = _generarMensajeEstadoPedido(
        codigoBarra, estadoAnterior, estadoNuevo, repartidorNombre, l10n);

    return Notificacion(
      id: 0, // Se asignará al guardar
      titulo: titulo,
      mensaje: mensaje,
      tipo: TipoNotificacion.estadoPedido,
      estado: EstadoNotificacion.pendiente,
      destinatarioId: destinatarioId,
      tipoDestinatario: tipoDestinatario,
      remitenteId: repartidorId,
      tipoRemitente: TipoUsuario.repartidor,
      datosAdicionales: {
        'pedido_id': pedidoId,
        'codigo_barra': codigoBarra,
        'estado_anterior': estadoAnterior.name,
        'estado_nuevo': estadoNuevo.name,
        'repartidor_id': repartidorId,
        'repartidor_nombre': repartidorNombre,
      },
      icono: 'local_shipping',
      prioridad: _obtenerPrioridadEstado(estadoNuevo),
      esUrgente: estadoNuevo == EstadoPedido.fallido ||
          estadoNuevo == EstadoPedido.entregado,
      fechaCreacion: DateTime.now(),
    );
  }

  factory Notificacion.repartidorEstado({
    required String repartidorId,
    required String repartidorNombre,
    required EstadoRepartidor estadoAnterior,
    required EstadoRepartidor estadoNuevo,
    required String farmaciaId,
    required AppLocalizations l10n,
  }) {
    final titulo = l10n.notificationDriverStatusUpdated;
    final mensaje = l10n.notificationDriverStatusChanged(
      repartidorNombre,
      StatusHelpers.estadoRepartidorTexto(estadoNuevo, l10n),
      StatusHelpers.estadoRepartidorTexto(estadoAnterior, l10n),
    );

    return Notificacion(
      id: 0,
      titulo: titulo,
      mensaje: mensaje,
      tipo: TipoNotificacion.estadoRepartidor,
      estado: EstadoNotificacion.pendiente,
      destinatarioId: farmaciaId,
      tipoDestinatario: TipoUsuario.administrador,
      remitenteId: repartidorId,
      tipoRemitente: TipoUsuario.repartidor,
      datosAdicionales: {
        'repartidor_id': repartidorId,
        'repartidor_nombre': repartidorNombre,
        'estado_anterior': estadoAnterior.name,
        'estado_nuevo': estadoNuevo.name,
      },
      icono: 'person',
      prioridad: _obtenerPrioridadEstadoRepartidor(estadoNuevo),
      esUrgente: estadoNuevo == EstadoRepartidor.desconectado,
      fechaCreacion: DateTime.now(),
    );
  }

  factory Notificacion.farmaciaEstado({
    required String farmaciaId,
    required String farmaciaNombre,
    required EstadoFarmacia estadoAnterior,
    required EstadoFarmacia estadoNuevo,
    required String administradorId,
    required AppLocalizations l10n,
  }) {
    final titulo = l10n.notificationPharmacyStatusUpdated;
    final mensaje = l10n.notificationPharmacyStatusChanged(
      farmaciaNombre,
      StatusHelpers.estadoFarmaciaTexto(estadoNuevo, l10n),
      StatusHelpers.estadoFarmaciaTexto(estadoAnterior, l10n),
    );

    return Notificacion(
      id: 0,
      titulo: titulo,
      mensaje: mensaje,
      tipo: TipoNotificacion.estadoFarmacia,
      estado: EstadoNotificacion.pendiente,
      destinatarioId: administradorId,
      tipoDestinatario: TipoUsuario.administrador,
      remitenteId: farmaciaId,
      tipoRemitente: TipoUsuario.administrador,
      datosAdicionales: {
        'farmacia_id': farmaciaId,
        'farmacia_nombre': farmaciaNombre,
        'estado_anterior': estadoAnterior.name,
        'estado_nuevo': estadoNuevo.name,
      },
      icono: 'local_pharmacy',
      prioridad: _obtenerPrioridadEstadoFarmacia(estadoNuevo),
      esUrgente: estadoNuevo == EstadoFarmacia.suspendida,
      fechaCreacion: DateTime.now(),
    );
  }

  // Métodos privados
  static String _generarMensajeEstadoPedido(
    String codigoBarra,
    EstadoPedido estadoAnterior,
    EstadoPedido estadoNuevo,
    String? repartidorNombre,
    AppLocalizations l10n,
  ) {
    switch (estadoNuevo) {
      case EstadoPedido.asignado:
        return l10n.notificationOrderAssigned(codigoBarra);
      case EstadoPedido.recogido:
        return l10n.notificationOrderPickedUp(codigoBarra);
      case EstadoPedido.enRuta:
        return l10n.notificationOrderInRoute(codigoBarra);
      case EstadoPedido.entregado:
        return l10n.notificationOrderDelivered(codigoBarra);
      case EstadoPedido.fallido:
        return l10n.notificationOrderFailed(codigoBarra);
      case EstadoPedido.cancelado:
        return l10n.notificationOrderCancelled(codigoBarra);
      default:
        return l10n.notificationOrderStatusChanged(
          codigoBarra,
          StatusHelpers.estadoPedidoTexto(estadoNuevo, l10n),
          StatusHelpers.estadoPedidoTexto(estadoAnterior, l10n),
        );
    }
  }

  static int _obtenerPrioridadEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.fallido:
        return 5;
      case EstadoPedido.entregado:
        return 4;
      case EstadoPedido.enRuta:
        return 3;
      case EstadoPedido.recogido:
        return 2;
      default:
        return 1;
    }
  }

  static int _obtenerPrioridadEstadoRepartidor(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.desconectado:
        return 5;
      case EstadoRepartidor.enRuta:
        return 3;
      case EstadoRepartidor.disponible:
        return 2;
    }
  }

  static int _obtenerPrioridadEstadoFarmacia(EstadoFarmacia estado) {
    switch (estado) {
      case EstadoFarmacia.suspendida:
        return 5;
      case EstadoFarmacia.enRevision:
        return 3;
      default:
        return 1;
    }
  }

  Notificacion copyWith({
    int? id,
    String? titulo,
    String? mensaje,
    TipoNotificacion? tipo,
    EstadoNotificacion? estado,
    String? destinatarioId,
    TipoUsuario? tipoDestinatario,
    String? remitenteId,
    TipoUsuario? tipoRemitente,
    Map<String, dynamic>? datosAdicionales,
    String? urlAccion,
    String? icono,
    bool? requiereConfirmacion,
    bool? esUrgente,
    int? prioridad,
    DateTime? fechaCreacion,
    DateTime? fechaEnvio,
    DateTime? fechaLectura,
    DateTime? fechaExpiracion,
    int? intentosEnvio,
    String? errorUltimoIntento,
  }) {
    return Notificacion(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      destinatarioId: destinatarioId ?? this.destinatarioId,
      tipoDestinatario: tipoDestinatario ?? this.tipoDestinatario,
      remitenteId: remitenteId ?? this.remitenteId,
      tipoRemitente: tipoRemitente ?? this.tipoRemitente,
      datosAdicionales: datosAdicionales ?? this.datosAdicionales,
      urlAccion: urlAccion ?? this.urlAccion,
      icono: icono ?? this.icono,
      requiereConfirmacion: requiereConfirmacion ?? this.requiereConfirmacion,
      esUrgente: esUrgente ?? this.esUrgente,
      prioridad: prioridad ?? this.prioridad,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      fechaLectura: fechaLectura ?? this.fechaLectura,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      intentosEnvio: intentosEnvio ?? this.intentosEnvio,
      errorUltimoIntento: errorUltimoIntento ?? this.errorUltimoIntento,
    );
  }
}

/// Tipos de notificaciones
enum TipoNotificacion {
  informacion,
  estadoPedido,
  estadoRepartidor,
  estadoFarmacia,
  alerta,
  error,
  exito,
  recordatorio,
  sistema,
}

/// Estados de notificaciones
enum EstadoNotificacion {
  pendiente,
  enviada,
  leida,
  fallida,
}

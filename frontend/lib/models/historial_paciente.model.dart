import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/pedido.model.dart';

/// Modelo para el historial de pacientes
class HistorialPaciente {
  final int id;
  final String pacienteId;
  final String farmaciaId;

  // Información del paciente
  final String nombre;
  final String telefono;
  final String? email;
  final String? idNumber;
  final String? idType;

  // Dirección
  final String direccion;
  final String distrito;
  final String codigoPostal;
  final double latitud;
  final double longitud;

  // Historial de firmas
  final List<FirmaPaciente> firmas;

  // Historial de pedidos
  final List<PedidoHistorial> pedidos;

  // Información de medicamentos controlados
  final bool requiereAutorizacionEspecial;
  final String? documentoAutorizacionUrl;
  final DateTime? fechaAutorizacion;

  // Metadatos
  final DateTime fechaPrimeraVisita;
  final DateTime fechaUltimaVisita;
  final int totalPedidos;
  final double totalGastado;
  final bool activo;

  // Notas del repartidor
  final List<NotaRepartidor> notasRepartidor;

  // Timestamps
  final DateTime fechaCreacion;
  final DateTime fechaUltimaActualizacion;

  const HistorialPaciente({
    required this.id,
    required this.pacienteId,
    required this.farmaciaId,
    required this.nombre,
    required this.telefono,
    this.email,
    this.idNumber,
    this.idType,
    required this.direccion,
    required this.distrito,
    required this.codigoPostal,
    required this.latitud,
    required this.longitud,
    required this.firmas,
    required this.pedidos,
    this.requiereAutorizacionEspecial = false,
    this.documentoAutorizacionUrl,
    this.fechaAutorizacion,
    required this.fechaPrimeraVisita,
    required this.fechaUltimaVisita,
    required this.totalPedidos,
    required this.totalGastado,
    required this.activo,
    required this.notasRepartidor,
    required this.fechaCreacion,
    required this.fechaUltimaActualizacion,
  });

  factory HistorialPaciente.fromJson(Map<String, dynamic> json) {
    return HistorialPaciente(
      id: json['id'] as int,
      pacienteId: json['paciente_id'] as String,
      farmaciaId: json['farmacia_id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      idNumber: json['id_number'] as String?,
      idType: json['id_type'] as String?,
      direccion: json['direccion'] as String,
      distrito: json['distrito'] as String,
      codigoPostal: json['codigo_postal'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      firmas: (json['firmas'] as List<dynamic>?)
              ?.map((f) => FirmaPaciente.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      pedidos: (json['pedidos'] as List<dynamic>?)
              ?.map((p) => PedidoHistorial.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      requiereAutorizacionEspecial:
          json['requiere_autorizacion_especial'] as bool? ?? false,
      documentoAutorizacionUrl: json['documento_autorizacion_url'] as String?,
      fechaAutorizacion: json['fecha_autorizacion'] != null
          ? DateTime.parse(json['fecha_autorizacion'] as String)
          : null,
      fechaPrimeraVisita:
          DateTime.parse(json['fecha_primera_visita'] as String),
      fechaUltimaVisita: DateTime.parse(json['fecha_ultima_visita'] as String),
      totalPedidos: json['total_pedidos'] as int? ?? 0,
      totalGastado: (json['total_gastado'] as num?)?.toDouble() ?? 0.0,
      activo: json['activo'] as bool? ?? true,
      notasRepartidor: (json['notas_repartidor'] as List<dynamic>?)
              ?.map((n) => NotaRepartidor.fromJson(n as Map<String, dynamic>))
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
      'paciente_id': pacienteId,
      'farmacia_id': farmaciaId,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'id_number': idNumber,
      'id_type': idType,
      'direccion': direccion,
      'distrito': distrito,
      'codigo_postal': codigoPostal,
      'latitud': latitud,
      'longitud': longitud,
      'firmas': firmas.map((f) => f.toJson()).toList(),
      'pedidos': pedidos.map((p) => p.toJson()).toList(),
      'requiere_autorizacion_especial': requiereAutorizacionEspecial,
      'documento_autorizacion_url': documentoAutorizacionUrl,
      'fecha_autorizacion': fechaAutorizacion?.toIso8601String(),
      'fecha_primera_visita': fechaPrimeraVisita.toIso8601String(),
      'fecha_ultima_visita': fechaUltimaVisita.toIso8601String(),
      'total_pedidos': totalPedidos,
      'total_gastado': totalGastado,
      'activo': activo,
      'notas_repartidor': notasRepartidor.map((n) => n.toJson()).toList(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_ultima_actualizacion': fechaUltimaActualizacion.toIso8601String(),
    };
  }

  // Getters útiles
  bool get esPrimeraVez => firmas.isEmpty;
  bool get tieneFirmaAutorizacion =>
      firmas.any((f) => f.tipo == TipoFirma.autorizacion);
  bool get tieneFirmaRecepcion =>
      firmas.any((f) => f.tipo == TipoFirma.recepcion);
  bool get requiereFirmaEspecial =>
      requiereAutorizacionEspecial ||
      pedidos.any((p) => p.tipoPedido == TipoPedido.medicamentosControlados);

  // Obtener firmas por tipo
  List<FirmaPaciente> getFirmasPorTipo(TipoFirma tipo) {
    return firmas.where((f) => f.tipo == tipo).toList();
  }

  // Obtener pedidos por estado
  List<PedidoHistorial> getPedidosPorEstado(EstadoPedido estado) {
    return pedidos.where((p) => p.estado == estado).toList();
  }

  // Obtener pedidos por código postal
  List<PedidoHistorial> getPedidosPorCodigoPostal(String codigoPostal) {
    return pedidos.where((p) => p.codigoPostal == codigoPostal).toList();
  }

  // Obtener pedidos por distrito
  List<PedidoHistorial> getPedidosPorDistrito(String distrito) {
    return pedidos.where((p) => p.distrito == distrito).toList();
  }

  HistorialPaciente copyWith({
    int? id,
    String? pacienteId,
    String? farmaciaId,
    String? nombre,
    String? telefono,
    String? email,
    String? idNumber,
    String? idType,
    String? direccion,
    String? distrito,
    String? codigoPostal,
    double? latitud,
    double? longitud,
    List<FirmaPaciente>? firmas,
    List<PedidoHistorial>? pedidos,
    bool? requiereAutorizacionEspecial,
    String? documentoAutorizacionUrl,
    DateTime? fechaAutorizacion,
    DateTime? fechaPrimeraVisita,
    DateTime? fechaUltimaVisita,
    int? totalPedidos,
    double? totalGastado,
    bool? activo,
    List<NotaRepartidor>? notasRepartidor,
    DateTime? fechaCreacion,
    DateTime? fechaUltimaActualizacion,
  }) {
    return HistorialPaciente(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      farmaciaId: farmaciaId ?? this.farmaciaId,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      idNumber: idNumber ?? this.idNumber,
      idType: idType ?? this.idType,
      direccion: direccion ?? this.direccion,
      distrito: distrito ?? this.distrito,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      firmas: firmas ?? this.firmas,
      pedidos: pedidos ?? this.pedidos,
      requiereAutorizacionEspecial:
          requiereAutorizacionEspecial ?? this.requiereAutorizacionEspecial,
      documentoAutorizacionUrl:
          documentoAutorizacionUrl ?? this.documentoAutorizacionUrl,
      fechaAutorizacion: fechaAutorizacion ?? this.fechaAutorizacion,
      fechaPrimeraVisita: fechaPrimeraVisita ?? this.fechaPrimeraVisita,
      fechaUltimaVisita: fechaUltimaVisita ?? this.fechaUltimaVisita,
      totalPedidos: totalPedidos ?? this.totalPedidos,
      totalGastado: totalGastado ?? this.totalGastado,
      activo: activo ?? this.activo,
      notasRepartidor: notasRepartidor ?? this.notasRepartidor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaUltimaActualizacion:
          fechaUltimaActualizacion ?? this.fechaUltimaActualizacion,
    );
  }
}

/// Modelo para las firmas de los pacientes
class FirmaPaciente {
  final int id;
  final String pacienteId;
  final TipoFirma tipo;
  final String? repartidorId;
  final String? pedidoId;
  final String? firmaUrl;
  final String? documentoUrl;
  final String? observaciones;
  final DateTime fechaFirma;
  final bool valida;

  const FirmaPaciente({
    required this.id,
    required this.pacienteId,
    required this.tipo,
    this.repartidorId,
    this.pedidoId,
    this.firmaUrl,
    this.documentoUrl,
    this.observaciones,
    required this.fechaFirma,
    required this.valida,
  });

  factory FirmaPaciente.fromJson(Map<String, dynamic> json) {
    return FirmaPaciente(
      id: json['id'] as int,
      pacienteId: json['paciente_id'] as String,
      tipo: TipoFirma.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoFirma.recepcion,
      ),
      repartidorId: json['repartidor_id'] as String?,
      pedidoId: json['pedido_id'] as String?,
      firmaUrl: json['firma_url'] as String?,
      documentoUrl: json['documento_url'] as String?,
      observaciones: json['observaciones'] as String?,
      fechaFirma: DateTime.parse(json['fecha_firma'] as String),
      valida: json['valida'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'tipo': tipo.name,
      'repartidor_id': repartidorId,
      'pedido_id': pedidoId,
      'firma_url': firmaUrl,
      'documento_url': documentoUrl,
      'observaciones': observaciones,
      'fecha_firma': fechaFirma.toIso8601String(),
      'valida': valida,
    };
  }
}

/// Modelo para el historial de pedidos
class PedidoHistorial {
  final int id;
  final String codigoBarra;
  final TipoPedido tipoPedido;
  final EstadoPedido estado;
  final String distrito;
  final String codigoPostal;
  final double latitud;
  final double longitud;
  final DateTime fechaCreacion;
  final DateTime? fechaEntrega;
  final double? valor;
  final String? repartidorId;
  final String? repartidorNombre;

  const PedidoHistorial({
    required this.id,
    required this.codigoBarra,
    required this.tipoPedido,
    required this.estado,
    required this.distrito,
    required this.codigoPostal,
    required this.latitud,
    required this.longitud,
    required this.fechaCreacion,
    this.fechaEntrega,
    this.valor,
    this.repartidorId,
    this.repartidorNombre,
  });

  factory PedidoHistorial.fromJson(Map<String, dynamic> json) {
    return PedidoHistorial(
      id: json['id'] as int,
      codigoBarra: json['codigo_barra'] as String,
      tipoPedido: TipoPedido.values.firstWhere(
        (e) => e.name == json['tipo_pedido'],
        orElse: () => TipoPedido.medicamentos,
      ),
      estado: EstadoPedido.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoPedido.pendiente,
      ),
      distrito: json['distrito'] as String,
      codigoPostal: json['codigo_postal'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaEntrega: json['fecha_entrega'] != null
          ? DateTime.parse(json['fecha_entrega'] as String)
          : null,
      valor: (json['valor'] as num?)?.toDouble(),
      repartidorId: json['repartidor_id'] as String?,
      repartidorNombre: json['repartidor_nombre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_barra': codigoBarra,
      'tipo_pedido': tipoPedido.name,
      'estado': estado.name,
      'distrito': distrito,
      'codigo_postal': codigoPostal,
      'latitud': latitud,
      'longitud': longitud,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'valor': valor,
      'repartidor_id': repartidorId,
      'repartidor_nombre': repartidorNombre,
    };
  }
}

/// Modelo para las notas de los repartidores
class NotaRepartidor {
  final int id;
  final String repartidorId;
  final String repartidorNombre;
  final String? pedidoId;
  final String nota;
  final DateTime fechaCreacion;
  final bool importante;

  const NotaRepartidor({
    required this.id,
    required this.repartidorId,
    required this.repartidorNombre,
    this.pedidoId,
    required this.nota,
    required this.fechaCreacion,
    this.importante = false,
  });

  factory NotaRepartidor.fromJson(Map<String, dynamic> json) {
    return NotaRepartidor(
      id: json['id'] as int,
      repartidorId: json['repartidor_id'] as String,
      repartidorNombre: json['repartidor_nombre'] as String,
      pedidoId: json['pedido_id'] as String?,
      nota: json['nota'] as String,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      importante: json['importante'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repartidor_id': repartidorId,
      'repartidor_nombre': repartidorNombre,
      'pedido_id': pedidoId,
      'nota': nota,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'importante': importante,
    };
  }
}

// Enum para tipos de firma requeridos en historial
enum TipoFirma {
  primeraVez, // Primera vez que se conoce al paciente
  recepcion, // Firma de recepción del pedido
  medicamentoControlado, // Firma especial para medicamentos controlados
  autorizacion, // Firma de autorización inicial
}

extension TipoFirmaExtension on TipoFirma {
  String texto(AppLocalizations l10n) {
    switch (this) {
      case TipoFirma.primeraVez:
        return l10n.signatureTypeFirstTime;
      case TipoFirma.recepcion:
        return l10n.signatureTypeReception;
      case TipoFirma.medicamentoControlado:
        return l10n.signatureTypeControlledMedicine;
      case TipoFirma.autorizacion:
        return l10n.signatureTypeAuthorization;
    }
  }

  String descripcion(AppLocalizations l10n) {
    switch (this) {
      case TipoFirma.primeraVez:
        return l10n.signatureDescriptionFirstTime;
      case TipoFirma.recepcion:
        return l10n.signatureDescriptionReception;
      case TipoFirma.medicamentoControlado:
        return l10n.signatureDescriptionControlledMedicine;
      case TipoFirma.autorizacion:
        return l10n.signatureDescriptionAuthorization;
    }
  }
}

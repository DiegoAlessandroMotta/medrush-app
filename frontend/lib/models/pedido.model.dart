import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:medrush/l10n/app_localizations.dart';

// Estados de pedidos (alineados con EstadosPedidoEnum del backend)
enum EstadoPedido {
  pendiente,
  asignado,
  recogido,
  enRuta,
  entregado,
  fallido,
  cancelado,
}

// Tipos de pedidos/medicamentos (alineados con TiposPedidoEnum del backend)
enum TipoPedido {
  medicamentos,
  insumosMedicos,
  equiposMedicos,
  medicamentosControlados,
}

// Motivos de falla en entrega (alineados con MotivosFalloPedidoEnum del backend)
enum MotivoFalla {
  noSeEncontraba,
  direccionIncorrecta,
  noRecibioLlamadas,
  rechazoEntrega,
  accesoDenegado,
  otro,
}

// Modelo para el repartidor (basado en la respuesta del backend)
class Repartidor {
  final String id;
  final bool verificado;
  final String nombre;

  const Repartidor({
    required this.id,
    required this.verificado,
    required this.nombre,
  });

  factory Repartidor.fromJson(Map<String, dynamic> json) {
    return Repartidor(
      id: json['id'] as String? ?? '',
      verificado: json['verificado'] as bool? ?? false,
      nombre: json['nombre'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verificado': verificado,
      'nombre': nombre,
    };
  }
}

class Pedido {
  final String id;
  final String codigoBarra;

  // Relaciones
  final String farmaciaId;
  final String? repartidorId;
  final Repartidor? repartidor; // FIX: Agregar objeto repartidor completo

  // Información del paciente
  final String pacienteNombre;
  final String pacienteTelefono;
  final String? pacienteEmail;

  // Dirección de entrega (alineada con el backend)
  final String direccionEntrega;
  final String? direccionDetalle;
  final String distritoEntrega;
  final String? codigoAcceso;
  final String? codigoIsoPaisEntrega;
  final String? direccionEntregaLinea2;
  final String? estadoRegionEntrega;
  final String? codigoPostalEntrega;
  final String? codigoAccesoEdificio;

  // Ubicación de entrega (usando Point de Laravel)
  final double? latitudEntrega;
  final double? longitudEntrega;
  final Map<String, dynamic>?
      ubicacionEntrega; // Para compatibilidad con Laravel Point

  // Ubicación de recogida (usando Point de Laravel)
  final double? latitudRecojo;
  final double? longitudRecojo;
  final Map<String, dynamic>?
      ubicacionRecojo; // Para compatibilidad con Laravel Point

  // Información del pedido
  final TipoPedido tipoPedido;
  final List<Map<String, dynamic>> medicamentos; // JSONB con detalles
  final String? observaciones;
  final bool requiereFirmaEspecial;
  final int prioridad;

  // Estado y tracking
  final EstadoPedido estado;
  final String? motivoFallo; // Usando MotivosFalloPedidoEnum del backend
  final String? observacionesFallo;

  // URLs de archivos
  final String? firmaDigitalUrl;
  final String? fotoEntregaUrl;
  final String? documentoConsentimientoUrl;

  // Timestamps del backend Laravel
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? fechaAsignacion;
  final DateTime? fechaRecogida;
  final DateTime? fechaEntrega;

  // Campos calculados
  final int? tiempoEntregaEstimado; // En minutos
  final double? distanciaEstimada; // En kilómetros

  // Orden de la ruta optimizada
  final int? ordenOptimizado;
  final int? ordenPersonalizado;

  const Pedido({
    required this.id,
    required this.codigoBarra,
    required this.farmaciaId,
    this.repartidorId,
    this.repartidor, // FIX: Agregar parámetro repartidor
    required this.pacienteNombre,
    required this.pacienteTelefono,
    this.pacienteEmail,
    required this.direccionEntrega,
    this.direccionDetalle,
    required this.distritoEntrega,
    this.codigoAcceso,
    this.codigoIsoPaisEntrega,
    this.direccionEntregaLinea2,
    this.estadoRegionEntrega,
    this.codigoPostalEntrega,
    this.codigoAccesoEdificio,
    this.latitudEntrega,
    this.longitudEntrega,
    this.ubicacionEntrega,
    this.latitudRecojo,
    this.longitudRecojo,
    this.ubicacionRecojo,
    required this.tipoPedido,
    required this.medicamentos,
    this.observaciones,
    this.requiereFirmaEspecial = false,
    this.prioridad = 1,
    required this.estado,
    this.motivoFallo,
    this.observacionesFallo,
    this.firmaDigitalUrl,
    this.fotoEntregaUrl,
    this.documentoConsentimientoUrl,
    this.createdAt,
    this.updatedAt,
    this.fechaAsignacion,
    this.fechaRecogida,
    this.fechaEntrega,
    this.tiempoEntregaEstimado,
    this.distanciaEstimada,
    this.ordenOptimizado,
    this.ordenPersonalizado,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: (json['id'] ?? '').toString(),
      codigoBarra: json['codigo_barra'] as String? ??
          json['codigo_barras'] as String? ??
          '',
      farmaciaId: json['farmacia_id'] as String? ?? '',
      repartidorId: json['repartidor_id'] as String? ??
          (json['repartidor'] != null
              ? json['repartidor']['id'] as String?
              : null),
      repartidor: json['repartidor'] != null
          ? Repartidor.fromJson(json['repartidor'] as Map<String, dynamic>)
          : null,
      pacienteNombre: json['paciente_nombre'] as String? ??
          json['nombre_paciente'] as String? ??
          '',
      pacienteTelefono: json['paciente_telefono'] as String? ??
          json['telefono_paciente'] as String? ??
          '',
      pacienteEmail: _parseStringOrProtected(
          json['paciente_email'] ?? json['email_paciente']),
      direccionEntrega: _parseStringOrProtected(
              json['direccion_entrega_linea_1'] ??
                  json['direccion_entrega'] ??
                  json['direccion'] ??
                  'Dirección no especificada') ??
          'Dirección no especificada',
      direccionDetalle: _parseStringOrProtected(
          json['direccion_entrega_linea_2'] ?? json['direccion_detalle']),
      distritoEntrega: _parseStringOrProtected(json['ciudad_entrega'] ??
              json['distrito_entrega'] ??
              json['ciudad'] ??
              'Ciudad no especificada') ??
          'Ciudad no especificada',
      codigoAcceso: _parseStringOrProtected(
          json['codigo_acceso_edificio'] ?? json['codigo_acceso']),
      codigoIsoPaisEntrega:
          _parseStringOrProtected(json['codigo_iso_pais_entrega']),
      direccionEntregaLinea2:
          _parseStringOrProtected(json['direccion_entrega_linea_2']),
      estadoRegionEntrega:
          _parseStringOrProtected(json['estado_region_entrega']),
      codigoPostalEntrega:
          _parseStringOrProtected(json['codigo_postal_entrega']),
      codigoAccesoEdificio:
          _parseStringOrProtected(json['codigo_acceso_edificio']),
      latitudEntrega: json['ubicacion_entrega']?['latitude'] != null
          ? (json['ubicacion_entrega']['latitude'] as num).toDouble()
          : json['latitud'] != null
              ? (json['latitud'] as num).toDouble()
              : null,
      longitudEntrega: json['ubicacion_entrega']?['longitude'] != null
          ? (json['ubicacion_entrega']['longitude'] as num).toDouble()
          : json['longitud'] != null
              ? (json['longitud'] as num).toDouble()
              : null,
      ubicacionEntrega: json['ubicacion_entrega'] as Map<String, dynamic>?,
      latitudRecojo: json['ubicacion_recojo']?['latitude'] != null
          ? (json['ubicacion_recojo']['latitude'] as num).toDouble()
          : null,
      longitudRecojo: json['ubicacion_recojo']?['longitude'] != null
          ? (json['ubicacion_recojo']['longitude'] as num).toDouble()
          : null,
      ubicacionRecojo: json['ubicacion_recojo'] as Map<String, dynamic>?,
      tipoPedido: _parseTipoPedido(json['tipo_pedido'] ?? json['tipo']),
      medicamentos:
          _parseMedicamentos(json['medicamentos'] ?? json['medicinas']),
      observaciones: json['observaciones'] as String?,
      requiereFirmaEspecial: json['requiere_firma_especial'] as bool? ?? false,
      prioridad: json['prioridad'] as int? ?? 1,
      estado: _parseEstadoPedido(json['estado'] ?? json['status']),
      motivoFallo: json['motivo_fallo'] as String?,
      observacionesFallo: json['observaciones_fallo'] as String?,
      firmaDigitalUrl: json['firma_digital'] as String?,
      fotoEntregaUrl: json['foto_entrega'] as String?,
      documentoConsentimientoUrl:
          _parseStringOrProtected(json['firma_documento_consentimiento']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      fechaAsignacion: _parseDateTime(json['fecha_asignacion']),
      fechaRecogida: _parseDateTime(json['fecha_recogida']),
      fechaEntrega: _parseDateTime(json['fecha_entrega']),
      tiempoEntregaEstimado: json['tiempo_entrega_estimado'] as int?,
      distanciaEstimada: json['distancia_estimada'] != null
          ? (json['distancia_estimada'] as num).toDouble()
          : null,
      ordenOptimizado: () {
        final orden = json['entregas']?['orden_optimizado'] as int?;
        if (kDebugMode && orden != null) {
          debugPrint(
              '[Pedido] Parseando ordenOptimizado: $orden para pedido ${json['id']}');
        }
        return orden;
      }(),
      ordenPersonalizado: json['entregas']?['orden_personalizado'] as int?,
    );
  }

  static TipoPedido _parseTipoPedido(tipo) {
    if (tipo == null) {
      return TipoPedido.medicamentos;
    }

    final tipoStr = tipo.toString().toLowerCase();
    switch (tipoStr) {
      case 'medicamentos':
      case 'medicinas':
        return TipoPedido.medicamentos;
      case 'insumos_medicos':
      case 'insumos':
        return TipoPedido.insumosMedicos;
      case 'equipos_medicos':
      case 'equipos':
        return TipoPedido.equiposMedicos;
      case 'medicamentos_controlados':
      case 'controlados':
        return TipoPedido.medicamentosControlados;
      default:
        return TipoPedido.medicamentos;
    }
  }

  static EstadoPedido _parseEstadoPedido(estado) {
    if (estado == null) {
      return EstadoPedido.pendiente;
    }

    final estadoStr = estado.toString().toLowerCase();
    switch (estadoStr) {
      case 'pendiente':
        return EstadoPedido.pendiente;
      case 'asignado':
        return EstadoPedido.asignado;
      case 'recogido':
        return EstadoPedido.recogido;
      case 'en_ruta':
      case 'enruta':
        return EstadoPedido.enRuta;
      case 'entregado':
        return EstadoPedido.entregado;
      case 'fallido':
      case 'fallo':
        return EstadoPedido.fallido;
      case 'cancelado':
        return EstadoPedido.cancelado;
      default:
        return EstadoPedido.pendiente;
    }
  }

  static String? _parseStringOrProtected(value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      // Si el valor es [PROTEGIDO] o similar, retornar null
      if (value.startsWith('[') && value.endsWith(']')) {
        return null;
      }
      return value;
    }
    return null;
  }

  static DateTime? _parseDateTime(dateValue) {
    if (dateValue == null) {
      return null;
    }

    try {
      String dateStr = dateValue.toString();

      // Corregir formato de fecha mal formateado del backend
      // Ejemplo: "2025-09-02T15:08:9.000000Z" -> "2025-09-02T15:08:09.000000Z"
      // Buscar patrón: YYYY-MM-DDTHH:MM:(\d)\.(6 dígitos)Z donde \d es un solo dígito

      // Buscar posición de "T" que separa fecha y hora
      final tIndex = dateStr.indexOf('T');
      if (tIndex != -1 && dateStr.length > tIndex + 13) {
        // Buscar dos puntos después de T (HH:MM:)
        final colonIndex1 = dateStr.indexOf(':', tIndex);
        if (colonIndex1 != -1) {
          final colonIndex2 = dateStr.indexOf(':', colonIndex1 + 1);
          if (colonIndex2 != -1 && colonIndex2 + 1 < dateStr.length) {
            // Verificar si después de "HH:MM:" hay un solo dígito seguido de "."
            final secondsStart = colonIndex2 + 1;
            if (secondsStart + 8 < dateStr.length) {
              final char1 = dateStr.codeUnitAt(secondsStart);
              final char2 = dateStr.codeUnitAt(secondsStart + 1);
              final isDigit1 = char1 >= 48 && char1 <= 57; // '0'-'9'
              final isDot = char2 == 46; // '.'

              // Si hay un solo dígito antes del punto, necesita padding
              if (isDigit1 && isDot) {
                final prefix = dateStr.substring(0, secondsStart);
                final singleDigit = dateStr[secondsStart];
                final suffix = dateStr.substring(secondsStart + 1);
                dateStr = '$prefix${singleDigit.padLeft(2, '0')}$suffix';
              }
            }
          }
        }
      }

      return DateTime.parse(dateStr);
    } catch (e) {
      // Si falla el parsing, retornar null en lugar de lanzar excepción
      return null;
    }
  }

  static List<Map<String, dynamic>> _parseMedicamentos(medicamentosJson) {
    if (medicamentosJson == null) {
      return [];
    }

    if (medicamentosJson is List) {
      return medicamentosJson.map((m) {
        if (m is Map<String, dynamic>) {
          return m;
        } else if (m is String) {
          // Para compatibilidad con versiones anteriores
          return {'nombre': m, 'cantidad': 1};
        }
        return {'nombre': m.toString(), 'cantidad': 1};
      }).toList();
    }

    // NUEVO: si viene como cadena ("Item A, Item B"), dividir por coma
    if (medicamentosJson is String) {
      final parts = medicamentosJson.split(',');
      return parts
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) => {
                'nombre': p,
                'cantidad': 1,
              })
          .toList();
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_barra': codigoBarra,
      'farmacia_id': farmaciaId,
      'repartidor_id': repartidorId,
      'repartidor': repartidor?.toJson(), // FIX: Incluir objeto repartidor
      'paciente_nombre': pacienteNombre,
      'paciente_telefono': pacienteTelefono,
      'paciente_email': pacienteEmail,
      'direccion_entrega': direccionEntrega,
      'direccion_detalle': direccionDetalle,
      'distrito_entrega': distritoEntrega,
      'codigo_acceso': codigoAcceso,
      'latitud_entrega': latitudEntrega,
      'longitud_entrega': longitudEntrega,
      'latitud_recojo': latitudRecojo,
      'longitud_recojo': longitudRecojo,
      'tipo_pedido': _tipoPedidoToBackend(tipoPedido),
      'medicamentos': medicamentos,
      'observaciones': observaciones,
      'requiere_firma_especial': requiereFirmaEspecial,
      'prioridad': prioridad,
      'estado': _estadoPedidoToBackend(estado),
      'motivo_fallo': motivoFallo,
      'observaciones_fallo': observacionesFallo,
      'firma_digital': firmaDigitalUrl,
      'foto_entrega': fotoEntregaUrl,
      'firma_documento_consentimiento': documentoConsentimientoUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'tiempo_entrega_estimado': tiempoEntregaEstimado,
      'distancia_estimada': distanciaEstimada,
    };
  }

  static String _tipoPedidoToBackend(TipoPedido tipo) {
    switch (tipo) {
      case TipoPedido.medicamentos:
        return 'medicamentos';
      case TipoPedido.insumosMedicos:
        return 'insumos_medicos';
      case TipoPedido.equiposMedicos:
        return 'equipos_medicos';
      case TipoPedido.medicamentosControlados:
        return 'medicamentos_controlados';
    }
  }

  static String _estadoPedidoToBackend(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'pendiente';
      case EstadoPedido.asignado:
        return 'asignado';
      case EstadoPedido.recogido:
        return 'recogido';
      case EstadoPedido.enRuta:
        return 'en_ruta';
      case EstadoPedido.entregado:
        return 'entregado';
      case EstadoPedido.fallido:
        return 'fallido';
      case EstadoPedido.cancelado:
        return 'cancelado';
    }
  }

  // Métodos de conveniencia para compatibilidad
  String get direccion => direccionEntrega;
  double? get latitud => latitudEntrega;
  double? get longitud => longitudEntrega;
  TipoPedido get tipo => tipoPedido;
  String? get firmaUrl => firmaDigitalUrl;
  double? get valor => null; // Campo legacy, se puede calcular de medicamentos

  // Getters para ubicaciones de recogida
  double? get latRecojo => latitudRecojo;
  double? get lngRecojo => longitudRecojo;

  // Getter para teléfono del cliente (alias más claro)
  String? get telefonoCliente => pacienteTelefono;

  // Getters útiles
  List<String> get medicamentosNombres {
    return medicamentos.map((m) => m['nombre']?.toString() ?? '').toList();
  }

  String get medicamentosTexto {
    return medicamentos.map((m) {
      final nombre = m['nombre']?.toString() ?? '';
      final cantidad = m['cantidad']?.toString() ?? '1';
      return '$nombre (x$cantidad)';
    }).join(', ');
  }

  bool get estaAsignado => repartidorId != null;
  bool get puedeSerRecogido => estado == EstadoPedido.asignado && estaAsignado;
  bool get puedeSerEntregado =>
      estado == EstadoPedido.recogido || estado == EstadoPedido.enRuta;
  bool get estaCompleto => estado == EstadoPedido.entregado;
  bool get haFallado => estado == EstadoPedido.fallido;

  Pedido copyWith({
    String? id,
    String? codigoBarra,
    String? farmaciaId,
    String? repartidorId,
    Repartidor? repartidor, // FIX: Agregar parámetro repartidor
    String? pacienteNombre,
    String? pacienteTelefono,
    String? pacienteEmail,
    String? direccionEntrega,
    String? direccionDetalle,
    String? distritoEntrega,
    String? codigoAcceso,
    String? codigoIsoPaisEntrega,
    String? direccionEntregaLinea2,
    String? estadoRegionEntrega,
    String? codigoPostalEntrega,
    String? codigoAccesoEdificio,
    double? latitudEntrega,
    double? longitudEntrega,
    Map<String, dynamic>? ubicacionEntrega,
    double? latitudRecojo,
    double? longitudRecojo,
    Map<String, dynamic>? ubicacionRecojo,
    TipoPedido? tipoPedido,
    List<Map<String, dynamic>>? medicamentos,
    String? observaciones,
    bool? requiereFirmaEspecial,
    int? prioridad,
    EstadoPedido? estado,
    String? motivoFallo,
    String? observacionesFallo,
    String? firmaDigitalUrl,
    String? fotoEntregaUrl,
    String? documentoConsentimientoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? fechaAsignacion,
    DateTime? fechaRecogida,
    DateTime? fechaEntrega,
    int? tiempoEntregaEstimado,
    double? distanciaEstimada,
  }) {
    return Pedido(
      id: id ?? this.id,
      codigoBarra: codigoBarra ?? this.codigoBarra,
      farmaciaId: farmaciaId ?? this.farmaciaId,
      repartidorId: repartidorId ?? this.repartidorId,
      repartidor:
          repartidor ?? this.repartidor, // FIX: Incluir repartidor en copyWith
      pacienteNombre: pacienteNombre ?? this.pacienteNombre,
      pacienteTelefono: pacienteTelefono ?? this.pacienteTelefono,
      pacienteEmail: pacienteEmail ?? this.pacienteEmail,
      direccionEntrega: direccionEntrega ?? this.direccionEntrega,
      direccionDetalle: direccionDetalle ?? this.direccionDetalle,
      distritoEntrega: distritoEntrega ?? this.distritoEntrega,
      codigoAcceso: codigoAcceso ?? this.codigoAcceso,
      codigoIsoPaisEntrega: codigoIsoPaisEntrega ?? this.codigoIsoPaisEntrega,
      direccionEntregaLinea2:
          direccionEntregaLinea2 ?? this.direccionEntregaLinea2,
      estadoRegionEntrega: estadoRegionEntrega ?? this.estadoRegionEntrega,
      codigoPostalEntrega: codigoPostalEntrega ?? this.codigoPostalEntrega,
      codigoAccesoEdificio: codigoAccesoEdificio ?? this.codigoAccesoEdificio,
      latitudEntrega: latitudEntrega ?? this.latitudEntrega,
      longitudEntrega: longitudEntrega ?? this.longitudEntrega,
      latitudRecojo: latitudRecojo ?? this.latitudRecojo,
      longitudRecojo: longitudRecojo ?? this.longitudRecojo,
      tipoPedido: tipoPedido ?? this.tipoPedido,
      medicamentos: medicamentos ?? this.medicamentos,
      observaciones: observaciones ?? this.observaciones,
      requiereFirmaEspecial:
          requiereFirmaEspecial ?? this.requiereFirmaEspecial,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      motivoFallo: motivoFallo ?? this.motivoFallo,
      observacionesFallo: observacionesFallo ?? this.observacionesFallo,
      firmaDigitalUrl: firmaDigitalUrl ?? this.firmaDigitalUrl,
      fotoEntregaUrl: fotoEntregaUrl ?? this.fotoEntregaUrl,
      documentoConsentimientoUrl:
          documentoConsentimientoUrl ?? this.documentoConsentimientoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      fechaRecogida: fechaRecogida ?? this.fechaRecogida,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      tiempoEntregaEstimado:
          tiempoEntregaEstimado ?? this.tiempoEntregaEstimado,
      distanciaEstimada: distanciaEstimada ?? this.distanciaEstimada,
    );
  }
}

// Extensiones para los enums
extension MotivoFallaExtension on MotivoFalla {
  String texto(AppLocalizations l10n) {
    switch (this) {
      case MotivoFalla.noSeEncontraba:
        return l10n.failureReasonClientNotFound;
      case MotivoFalla.direccionIncorrecta:
        return l10n.failureReasonWrongAddress;
      case MotivoFalla.noRecibioLlamadas:
        return l10n.failureReasonNoCalls;
      case MotivoFalla.rechazoEntrega:
        return l10n.failureReasonDeliveryRejected;
      case MotivoFalla.accesoDenegado:
        return l10n.failureReasonAccessDenied;
      case MotivoFalla.otro:
        return l10n.failureReasonOther;
    }
  }
}

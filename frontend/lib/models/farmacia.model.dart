// import eliminado: colores centralizados en StatusHelpers

// Estados de farmacias en tiempo real
enum EstadoFarmacia {
  activa,
  inactiva,
  suspendida,
  enRevision,
}

class Farmacia {
  final String id;
  final String nombre;
  final String razonSocial;
  final String ruc;
  final String direccion;
  final String? direccionLinea1;
  final String? direccionLinea2;
  final String? telefono;
  final String? email;
  final double latitud;
  final double longitud;
  final EstadoFarmacia estado;
  final String? cadena;
  final String? horarioAtencion;
  final bool delivery24h;
  final String? contactoResponsable;
  final String? telefonoResponsable;
  final DateTime fechaRegistro;
  final DateTime? fechaUltimaActualizacion;

  // US-friendly addressing (canonical)
  final String? city;
  final String? state;
  final String? zipCode;
  final String? codigoIsoPais;

  const Farmacia({
    required this.id,
    required this.nombre,
    required this.razonSocial,
    required this.ruc,
    required this.direccion,
    this.direccionLinea1,
    this.direccionLinea2,
    this.telefono,
    this.email,
    required this.latitud,
    required this.longitud,
    required this.estado,
    this.cadena,
    this.horarioAtencion,
    required this.delivery24h,
    this.contactoResponsable,
    this.telefonoResponsable,
    required this.fechaRegistro,
    this.fechaUltimaActualizacion,
    this.city,
    this.state,
    this.zipCode,
    this.codigoIsoPais,
  });

  factory Farmacia.fromJson(Map<String, dynamic> json) {
    try {
      return Farmacia(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] as String?) ?? '',
        razonSocial: (json['razon_social'] as String?) ??
            (json['razonSocial'] as String?) ??
            (json['razon'] as String?) ??
            (json['nombre'] as String?) ??
            '',
        ruc: (json['ruc_ein'] ?? json['ruc'] ?? '').toString(),
        direccion: (json['direccion_linea_1'] as String?) ??
            (json['direccion'] as String?) ??
            '',
        direccionLinea1: json['direccion_linea_1'] as String?,
        direccionLinea2: json['direccion_linea_2'] as String?,
        telefono: json['telefono'] as String?,
        email: json['email'] as String?,
        latitud: json['ubicacion']?['latitude'] != null
            ? (json['ubicacion']['latitude'] as num).toDouble()
            : 0.0,
        longitud: json['ubicacion']?['longitude'] != null
            ? (json['ubicacion']['longitude'] as num).toDouble()
            : 0.0,
        estado: () {
          final raw = json['estado'] as String?;
          switch (raw) {
            case 'activa':
              return EstadoFarmacia.activa;
            case 'inactiva':
              return EstadoFarmacia.inactiva;
            case 'suspendida':
              return EstadoFarmacia.suspendida;
            case 'en_revision':
              return EstadoFarmacia.enRevision;
            default:
              return EstadoFarmacia.activa;
          }
        }(),
        cadena: json['cadena'] as String?,
        horarioAtencion: json['horario_atencion'] as String?,
        delivery24h: (() {
          final v = json['delivery_24h'];
          if (v is bool) {
            return v;
          }
          if (v is num) {
            return v != 0;
          }
          if (v is String) {
            return v.toLowerCase() == 'true';
          }
          return false;
        })(),
        contactoResponsable: json['contacto_responsable'] as String?,
        telefonoResponsable: json['telefono_responsable'] as String?,
        fechaRegistro: () {
          final v = json['created_at'];
          if (v is String && v.isNotEmpty) {
            return DateTime.tryParse(v) ?? DateTime.now();
          }
          return DateTime.now();
        }(),
        fechaUltimaActualizacion: () {
          final v = json['updated_at'];
          if (v is String && v.isNotEmpty) {
            return DateTime.tryParse(v);
          }
          return null;
        }(),
        city: (json['ciudad'] as String?) ?? (json['distrito'] as String?),
        state: (json['estado_region'] as String?) ??
            (json['provincia'] as String?),
        zipCode:
            (json['codigo_postal'] ?? json['zip_code'] ?? json['departamento'])
                ?.toString(),
        codigoIsoPais: json['codigo_iso_pais'] as String?,
      );
    } catch (e) {
      // Log del error para debugging
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'razon_social': razonSocial,
      'ruc_ein': ruc,
      'direccion_linea_1': direccionLinea1 ?? direccion,
      'direccion_linea_2': direccionLinea2,
      'telefono': telefono,
      'email': email,
      'ubicacion': {
        'latitude': latitud,
        'longitude': longitud,
      },
      'estado': () {
        switch (estado) {
          case EstadoFarmacia.activa:
            return 'activa';
          case EstadoFarmacia.inactiva:
            return 'inactiva';
          case EstadoFarmacia.suspendida:
            return 'suspendida';
          case EstadoFarmacia.enRevision:
            return 'en_revision';
        }
      }(),
      'cadena': cadena,
      'horario_atencion': horarioAtencion,
      'delivery_24h': delivery24h,
      'contacto_responsable': contactoResponsable,
      'telefono_responsable': telefonoResponsable,
      'created_at': fechaRegistro.toIso8601String(),
      'updated_at': fechaUltimaActualizacion?.toIso8601String(),
      // US-friendly fields
      'ciudad': city,
      'estado_region': state,
      'codigo_postal': zipCode,
      'codigo_iso_pais': codigoIsoPais ?? 'USA',
    };
  }

  Farmacia copyWith({
    String? id,
    String? nombre,
    String? razonSocial,
    String? ruc,
    String? direccion,
    String? direccionLinea1,
    String? direccionLinea2,
    String? city,
    String? state,
    String? zipCode,
    String? codigoIsoPais,
    String? telefono,
    String? email,
    double? latitud,
    double? longitud,
    EstadoFarmacia? estado,
    String? cadena,
    String? horarioAtencion,
    bool? delivery24h,
    String? contactoResponsable,
    String? telefonoResponsable,
    DateTime? fechaRegistro,
    DateTime? fechaUltimaActualizacion,
  }) {
    return Farmacia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      razonSocial: razonSocial ?? this.razonSocial,
      ruc: ruc ?? this.ruc,
      direccion: direccion ?? this.direccion,
      direccionLinea1: direccionLinea1 ?? this.direccionLinea1,
      direccionLinea2: direccionLinea2 ?? this.direccionLinea2,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      codigoIsoPais: codigoIsoPais ?? this.codigoIsoPais,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      estado: estado ?? this.estado,
      cadena: cadena ?? this.cadena,
      horarioAtencion: horarioAtencion ?? this.horarioAtencion,
      delivery24h: delivery24h ?? this.delivery24h,
      contactoResponsable: contactoResponsable ?? this.contactoResponsable,
      telefonoResponsable: telefonoResponsable ?? this.telefonoResponsable,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaUltimaActualizacion:
          fechaUltimaActualizacion ?? this.fechaUltimaActualizacion,
    );
  }

  // Factory method para crear Farmacia desde Map<String, String>
  factory Farmacia.fromMap(Map<String, String> map) {
    return Farmacia(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      razonSocial: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'],
      email: map['email'],
      contactoResponsable: map['responsable'],
      ruc: map['ruc'] ?? '12345678901',
      cadena: map['cadena'] ?? 'Cadena Demo',
      city: map['city'] ?? map['distrito'] ?? 'City',
      state: map['state'],
      zipCode: map['zip_code'],
      latitud: double.tryParse(map['latitud'] ?? '-12.0464') ?? -12.0464,
      longitud: double.tryParse(map['longitud'] ?? '-77.0428') ?? -77.0428,
      estado: (map['estado'] ?? 'activa').toLowerCase() == 'activa'
          ? EstadoFarmacia.activa
          : EstadoFarmacia.inactiva,
      horarioAtencion: map['horario'] ?? 'Lun-Vie: 8:00-20:00',
      delivery24h: map['delivery24h'] == 'true',
      fechaRegistro: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Farmacia(id: $id, nombre: $nombre, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Farmacia && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extensiones para los enums
extension EstadoFarmaciaExtension on EstadoFarmacia {
  // Texto y color centralizados en StatusHelpers
}

import 'package:uuid/uuid.dart';

// Tipos de usuario del sistema (alineados con RolesEnum del backend)
enum TipoUsuario {
  administrador,
  repartidor,
}

// Estados de repartidores en tiempo real (alineados con EstadosRepartidorEnum del backend)
enum EstadoRepartidor {
  disponible,
  enRuta,
  desconectado,
}

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String? password; // Nullable para respuestas del backend
  final TipoUsuario tipoUsuario;
  final String? telefono;
  final String? foto;
  final String? firmaDigital;

  // Campos específicos para repartidores (alineados con PerfilRepartidor del backend)
  final String? dniIdNumero;
  final String? dniIdImagenUrl;
  final String? licenciaNumero;
  final DateTime? licenciaVencimiento;
  final String? licenciaImagenUrl;
  final String? seguroVehiculoUrl;
  final String? vehiculoPlaca;
  final String? vehiculoMarca;
  final String? vehiculoModelo;
  final EstadoRepartidor? estadoRepartidor;
  final String? codigoIsoPais;
  final bool? verificado;
  final String? fotoDniId;
  final String? fotoLicencia;
  final String? fotoSeguroVehiculo;

  // Campos específicos para clientes (farmacias)
  final String? farmaciaId;

  // Timestamps del backend Laravel
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.password,
    required this.tipoUsuario,
    this.telefono,
    this.foto,
    this.firmaDigital,
    this.dniIdNumero,
    this.dniIdImagenUrl,
    this.licenciaNumero,
    this.licenciaVencimiento,
    this.licenciaImagenUrl,
    this.seguroVehiculoUrl,
    this.vehiculoPlaca,
    this.vehiculoMarca,
    this.vehiculoModelo,
    this.estadoRepartidor,
    this.codigoIsoPais,
    this.verificado,
    this.fotoDniId,
    this.fotoLicencia,
    this.fotoSeguroVehiculo,
    this.farmaciaId,
    this.createdAt,
    this.updatedAt,
    this.activo = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Extraer datos del perfil_repartidor si existe
    final perfilRepartidor = json['perfil_repartidor'] as Map<String, dynamic>?;

    return Usuario(
      id: (json['id'] ?? '').toString(),
      nombre: json['name'] as String? ?? json['nombre'] as String? ?? '',
      email: json['email'] as String,
      password: json['password'] as String?,
      tipoUsuario: _parseTipoUsuario(json['role'] ?? json['tipo_usuario']),
      telefono: perfilRepartidor?['telefono'] as String? ??
          json['phone'] as String? ??
          json['telefono'] as String?,
      foto: json['avatar'] as String? ??
          json['photo'] as String? ??
          json['foto'] as String?,
      firmaDigital: json['firma_digital'] as String?,
      dniIdNumero: perfilRepartidor?['dni_id_numero'] as String? ??
          json['dni_id_numero'] as String?,
      dniIdImagenUrl: perfilRepartidor?['foto_dni_id'] as String? ??
          json['dni_id_imagen_url'] as String?,
      licenciaNumero: perfilRepartidor?['licencia_numero'] as String? ??
          json['licencia_numero'] as String?,
      licenciaVencimiento: (perfilRepartidor?['licencia_vencimiento'] ??
                  json['licencia_vencimiento']) !=
              null
          ? DateTime.parse((perfilRepartidor?['licencia_vencimiento'] ??
              json['licencia_vencimiento']) as String)
          : null,
      licenciaImagenUrl: perfilRepartidor?['foto_licencia'] as String? ??
          json['licencia_imagen_url'] as String?,
      seguroVehiculoUrl: perfilRepartidor?['foto_seguro_vehiculo'] as String? ??
          json['seguro_vehiculo_url'] as String?,
      vehiculoPlaca: perfilRepartidor?['vehiculo_placa'] as String? ??
          json['vehiculo_placa'] as String?,
      vehiculoMarca: perfilRepartidor?['vehiculo_marca'] as String? ??
          json['vehiculo_marca'] as String?,
      vehiculoModelo: perfilRepartidor?['vehiculo_modelo'] as String? ??
          json['vehiculo_modelo'] as String?,
      estadoRepartidor:
          (perfilRepartidor?['estado'] ?? json['estado_repartidor']) != null
              ? _estadoRepartidorFromSnakeCase((perfilRepartidor?['estado'] ??
                  json['estado_repartidor']) as String)
              : null,
      codigoIsoPais: perfilRepartidor?['codigo_iso_pais'] as String? ??
          json['codigo_iso_pais'] as String?,
      verificado: perfilRepartidor?['verificado'] as bool? ??
          json['verificado'] as bool?,
      fotoDniId: perfilRepartidor?['foto_dni_id'] as String? ??
          json['foto_dni_id'] as String?,
      fotoLicencia: perfilRepartidor?['foto_licencia'] as String? ??
          json['foto_licencia'] as String?,
      fotoSeguroVehiculo:
          perfilRepartidor?['foto_seguro_vehiculo'] as String? ??
              json['foto_seguro_vehiculo'] as String?,
      farmaciaId: perfilRepartidor?['farmacia_id'] as String? ??
          json['farmacia_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      activo: json['is_active'] as bool? ??
          json['active'] as bool? ??
          json['activo'] as bool? ??
          true,
    );
  }

  static TipoUsuario _parseTipoUsuario(role) {
    if (role == null) {
      return TipoUsuario.repartidor;
    }

    final roleStr = role.toString().toLowerCase();
    switch (roleStr) {
      case 'admin':
      case 'administrador':
        return TipoUsuario.administrador;
      case 'repartidor':
      case 'delivery':
        return TipoUsuario.repartidor;
      case 'cliente':
      case 'farmacia':
      case 'botica':
        return TipoUsuario.administrador;
      default:
        return TipoUsuario.repartidor;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nombre, // Backend usa 'name'
      'email': email,
      'password': password,
      'role': _tipoUsuarioToBackend(tipoUsuario), // Backend usa 'role'
      'phone': telefono,
      'photo': foto,
      'firma_digital': firmaDigital,
      'licencia_numero': licenciaNumero,
      'licencia_vencimiento': licenciaVencimiento?.toIso8601String(),
      'licencia_imagen_url': licenciaImagenUrl,
      'seguro_vehiculo_url': seguroVehiculoUrl,
      'vehiculo_placa': vehiculoPlaca,
      'vehiculo_marca': vehiculoMarca,
      'vehiculo_modelo': vehiculoModelo,
      'estado_repartidor': estadoRepartidor != null
          ? _estadoRepartidorToSnakeCase(estadoRepartidor!)
          : null,
      'farmacia_id': farmaciaId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'active': activo,
    };
  }

  static String _tipoUsuarioToBackend(TipoUsuario tipo) {
    switch (tipo) {
      case TipoUsuario.administrador:
        return 'admin';
      case TipoUsuario.repartidor:
        return 'repartidor';
    }
  }

  // Métodos para convertir estado_repartidor entre camelCase y snake_case
  static EstadoRepartidor _estadoRepartidorFromSnakeCase(String snakeCase) {
    switch (snakeCase) {
      case 'disponible':
        return EstadoRepartidor.disponible;
      case 'desconectado':
        return EstadoRepartidor.desconectado;
      case 'en_ruta':
        return EstadoRepartidor.enRuta;
      default:
        return EstadoRepartidor.disponible;
    }
  }

  static String _estadoRepartidorToSnakeCase(EstadoRepartidor estado) {
    switch (estado) {
      case EstadoRepartidor.disponible:
        return 'disponible';
      case EstadoRepartidor.desconectado:
        return 'desconectado';
      case EstadoRepartidor.enRuta:
        return 'en_ruta';
    }
  }

  // Generar ID UUID para nuevos usuarios
  static String generateNewId() {
    const uuid = Uuid();
    return uuid.v4();
  }

  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? password,
    TipoUsuario? tipoUsuario,
    String? telefono,
    String? foto,
    String? licenciaNumero,
    DateTime? licenciaVencimiento,
    String? licenciaImagenUrl,
    String? seguroVehiculoUrl,
    String? vehiculoPlaca,
    String? vehiculoMarca,
    String? vehiculoModelo,
    EstadoRepartidor? estadoRepartidor,
    String? codigoIsoPais,
    bool? verificado,
    String? fotoDniId,
    String? fotoLicencia,
    String? fotoSeguroVehiculo,
    String? farmaciaId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? activo,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      password: password ?? this.password,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      telefono: telefono ?? this.telefono,
      foto: foto ?? this.foto,
      licenciaNumero: licenciaNumero ?? this.licenciaNumero,
      licenciaVencimiento: licenciaVencimiento ?? this.licenciaVencimiento,
      licenciaImagenUrl: licenciaImagenUrl ?? this.licenciaImagenUrl,
      seguroVehiculoUrl: seguroVehiculoUrl ?? this.seguroVehiculoUrl,
      vehiculoPlaca: vehiculoPlaca ?? this.vehiculoPlaca,
      vehiculoMarca: vehiculoMarca ?? this.vehiculoMarca,
      vehiculoModelo: vehiculoModelo ?? this.vehiculoModelo,
      estadoRepartidor: estadoRepartidor ?? this.estadoRepartidor,
      codigoIsoPais: codigoIsoPais ?? this.codigoIsoPais,
      verificado: verificado ?? this.verificado,
      fotoDniId: fotoDniId ?? this.fotoDniId,
      fotoLicencia: fotoLicencia ?? this.fotoLicencia,
      fotoSeguroVehiculo: fotoSeguroVehiculo ?? this.fotoSeguroVehiculo,
      farmaciaId: farmaciaId ?? this.farmaciaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activo: activo ?? this.activo,
    );
  }

  // Getters útiles
  bool get esRepartidor => tipoUsuario == TipoUsuario.repartidor;
  bool get esAdministrador => tipoUsuario == TipoUsuario.administrador;

  String get vehiculoCompleto {
    if (vehiculoMarca == null && vehiculoModelo == null) {
      return 'No especificado';
    }
    return '${vehiculoMarca ?? ''} ${vehiculoModelo ?? ''}'.trim();
  }

  bool get tieneVehiculoCompleto {
    return vehiculoPlaca != null &&
        vehiculoMarca != null &&
        vehiculoModelo != null;
  }

  bool get licenciaVigente {
    if (licenciaVencimiento == null) {
      return false;
    }
    return licenciaVencimiento!.isAfter(DateTime.now());
  }
}

// Extensiones para los enums
extension TipoUsuarioExtension on TipoUsuario {
  String get texto {
    switch (this) {
      case TipoUsuario.administrador:
        return 'Administrador';
      case TipoUsuario.repartidor:
        return 'Repartidor';
    }
  }
}

extension EstadoRepartidorExtension on EstadoRepartidor {
  // Texto y color centralizados en StatusHelpers
}

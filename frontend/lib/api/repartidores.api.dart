import 'package:image_picker/image_picker.dart';
import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/utils/loggers.dart';

class RepartidoresApi extends BaseApi {
  /// Obtiene todos los repartidores desde el endpoint /api/user/repartidores
  /// NOTA: El backend devuelve resultados paginados, este método obtiene solo la primera página
  static Future<List<Usuario>> getAllRepartidores() {
    return ApiHelper.getList<Usuario>(
      EndpointManager.repartidores,
      fromJson: Usuario.fromJson,
      operationName:
          'Obteniendo repartidores desde /api/user/repartidores (primera página)',
    );
  }

  /// Obtiene todos los repartidores con paginación completa
  static Future<List<Usuario>> getAllRepartidoresCompletos() async {
    final List<Usuario> todosRepartidores = [];
    int pagina = 1;
    bool hayMasPaginas = true;

    while (hayMasPaginas) {
      try {
        final response = await BaseApi.getPaginated<Usuario>(
          EndpointManager.repartidores,
          fromJson: Usuario.fromJson,
          page: pagina,
          perPage: 100, // Máximo por página para reducir llamadas
        );

        todosRepartidores.addAll(response.items);

        // Verificar si hay más páginas
        hayMasPaginas = pagina < response.pagination.lastPage;
        pagina++;
      } catch (e) {
        logError('Error obteniendo repartidores página $pagina', e);
        break;
      }
    }

    return todosRepartidores;
  }

  /// Obtiene un repartidor específico por ID
  static Future<Usuario?> getRepartidorById(String id) {
    return ApiHelper.getSingle<Usuario>(
      EndpointManager.repartidorById(id),
      fromJson: Usuario.fromJson,
      operationName: 'Obteniendo repartidor con ID: $id',
    );
  }

  /// Actualiza el estado de un repartidor
  static Future<bool> updateEstadoRepartidor(String id, String nuevoEstado) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch(
          EndpointManager.repartidorEstado(id),
          data: {'estado': nuevoEstado},
        );
        return ApiHelper.isValidResponse(response.data);
      },
      operationName: 'Actualizando estado del repartidor $id a: $nuevoEstado',
    );
  }

  /// Obtiene repartidores por estado
  static Future<List<Usuario>> getRepartidoresByEstado(String estado) {
    return ApiHelper.getList<Usuario>(
      '${EndpointManager.repartidores}?estado=$estado',
      fromJson: Usuario.fromJson,
      operationName: 'Obteniendo repartidores con estado: $estado',
    );
  }

  /// Obtiene repartidores disponibles (estado = "disponible")
  static Future<List<Usuario>> getRepartidoresDisponibles() {
    return getRepartidoresByEstado('disponible');
  }

  /// Obtiene repartidores activos (is_active = true)
  static Future<List<Usuario>> getRepartidoresActivos() {
    return ApiHelper.getList<Usuario>(
      '${EndpointManager.repartidores}?is_active=true',
      fromJson: Usuario.fromJson,
      operationName: 'Obteniendo repartidores activos',
    );
  }

  /// Crea un nuevo repartidor
  static Future<Usuario?> createRepartidor(Usuario repartidor) {
    return ApiHelper.executeWithLogging(
      () async {
        // Logs detallados de los datos del repartidor
        logInfo('🔍 DATOS DEL REPARTIDOR RECIBIDOS:');
        logInfo('🔍 - ID: ${repartidor.id}');
        logInfo('🔍 - Nombre: ${repartidor.nombre}');
        logInfo('🔍 - Email: ${repartidor.email}');
        logInfo(
            '🔍 - Password: ${repartidor.password?.isNotEmpty == true ? "***${repartidor.password!.substring(repartidor.password!.length - 2)}" : "null"}');
        logInfo('🔍 - Teléfono original: ${repartidor.telefono}');
        logInfo('🔍 - DNI ID: ${repartidor.dniIdNumero}');
        logInfo('🔍 - Licencia número: ${repartidor.licenciaNumero}');
        logInfo('🔍 - Licencia vencimiento: ${repartidor.licenciaVencimiento}');
        logInfo('🔍 - Vehículo placa: ${repartidor.vehiculoPlaca}');
        logInfo('🔍 - Vehículo marca: ${repartidor.vehiculoMarca}');
        logInfo('🔍 - Vehículo modelo: ${repartidor.vehiculoModelo}');
        logInfo('🔍 - Farmacia ID: ${repartidor.farmaciaId}');

        // Procesar teléfono
        String? telefonoProcesado;
        if (repartidor.telefono != null && repartidor.telefono!.isNotEmpty) {
          if (repartidor.telefono!.startsWith('+')) {
            telefonoProcesado = repartidor.telefono;
            logInfo('🔍 - Teléfono ya tiene formato E.164: $telefonoProcesado');
          } else {
            telefonoProcesado =
                '+1${repartidor.telefono!.replaceAll(RegExp(r'[^\d]'), '')}';
            logInfo('🔍 - Teléfono procesado a E.164: $telefonoProcesado');
          }
        } else {
          telefonoProcesado = null;
          logInfo('🔍 - Teléfono es null o vacío');
        }

        // Procesar fecha de licencia
        String? licenciaVencimientoProcesada;
        if (repartidor.licenciaVencimiento != null) {
          licenciaVencimientoProcesada =
              repartidor.licenciaVencimiento!.toIso8601String().split('T')[0];
          logInfo(
              '🔍 - Licencia vencimiento procesada: $licenciaVencimientoProcesada');
        } else {
          licenciaVencimientoProcesada = null;
          logInfo('🔍 - Licencia vencimiento es null');
        }

        final requestData = {
          // Campos base del usuario (según RegisterBaseUserRequest)
          'name': repartidor.nombre,
          'email': repartidor.email,
          'password': repartidor.password,
          'password_confirmation': repartidor.password,
          'device_name': 'Flutter App',

          // Campos específicos del repartidor (según RegisterRepartidorUserRequest)
          'codigo_iso_pais': 'USA', // Código ISO para Estados Unidos
          'dni_id_numero': repartidor.dniIdNumero,
          'telefono': telefonoProcesado,
          'licencia_numero': repartidor.licenciaNumero,
          'licencia_vencimiento': licenciaVencimientoProcesada,
          'vehiculo_placa': repartidor.vehiculoPlaca,
          'vehiculo_marca': repartidor.vehiculoMarca,
          'vehiculo_modelo': repartidor.vehiculoModelo,

          // Campos adicionales que el backend podría aceptar
          if (repartidor.farmaciaId != null)
            'farmacia_id': repartidor.farmaciaId,
        };

        logInfo('🔍 DATOS FINALES A ENVIAR AL BACKEND:');
        requestData.forEach((key, value) {
          if (key == 'password' || key == 'password_confirmation') {
            logInfo(
                '🔍 - $key: ${value != null ? "***${value.toString().substring(value.toString().length - 2)}" : "null"}');
          } else {
            logInfo('🔍 - $key: $value');
          }
        });

        final response =
            await BaseApi.post(EndpointManager.repartidores, data: requestData);

        // Procesar respuesta específica para creación de repartidor
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData == null) return null;

        final data = responseData['data'] as Map<String, dynamic>?;
        if (data == null) return null;

        final userData = data['user'] as Map<String, dynamic>?;
        if (userData == null) return null;

        return Usuario.fromJson(userData);
      },
      operationName: 'Creando nuevo repartidor: ${repartidor.nombre}',
    );
  }

  /// Actualiza un repartidor existente
  static Future<Usuario?> updateRepartidor(Usuario repartidor) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch(
          EndpointManager.repartidorById(repartidor.id),
          data: {
            // Campos base del usuario (según UpdateBaseUserRequest)
            'name': repartidor.nombre,
            'email': repartidor.email,
            if (repartidor.password?.isNotEmpty == true)
              'password': repartidor.password,
            if (repartidor.password?.isNotEmpty == true)
              'password_confirmation': repartidor.password,

            // Campos específicos del repartidor (según UpdateRepartidorUserRequest)
            'farmacia_id': repartidor.farmaciaId,
            'codigo_iso_pais': 'USA', // Código ISO para Estados Unidos
            'dni_id_numero': repartidor.dniIdNumero,
            'telefono': repartidor.telefono,
            'licencia_numero': repartidor.licenciaNumero,
            'licencia_vencimiento':
                repartidor.licenciaVencimiento?.toIso8601String(),
            'vehiculo_placa': repartidor.vehiculoPlaca,
            'vehiculo_marca': repartidor.vehiculoMarca,
            'vehiculo_modelo': repartidor.vehiculoModelo,
          },
        );
        return ApiHelper.processSingleResponse(response.data, Usuario.fromJson);
      },
      operationName:
          'Actualizando repartidor: ${repartidor.nombre} (ID: ${repartidor.id})',
    );
  }

  /// Elimina un repartidor por ID
  static Future<bool> deleteRepartidor(String id) {
    return ApiHelper.executeWithLogging(
      () async {
        final response =
            await BaseApi.delete(EndpointManager.repartidorById(id));
        return ApiHelper.isValidResponse(response.data);
      },
      operationName: 'Eliminando repartidor con ID: $id',
    );
  }

  /// Sube foto de perfil del repartidor
  static Future<String?> uploadFotoPerfil(XFile imageFile) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.uploadImage(
          imageFile: imageFile,
          userId: 'current', // Usar usuario actual
        );
        return response;
      },
      operationName: 'Subiendo foto de perfil',
    );
  }

  /// Sube foto de DNI/ID del repartidor
  static Future<String?> uploadFotoDniId(String repartidorId, XFile imageFile) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.uploadFile<Map<String, dynamic>>(
          EndpointManager.repartidorDniId(repartidorId),
          filePath: imageFile.path,
          fieldName: 'foto_dni_id',
        );

        if (response.statusCode == 200 &&
            response.data?['status'] == 'success') {
          return response.data?['data']?['url'] as String?;
        }
        return null;
      },
      operationName: 'Subiendo foto de DNI/ID para repartidor: $repartidorId',
    );
  }

  /// Sube foto de licencia del repartidor
  static Future<String?> uploadFotoLicencia(
      String repartidorId, XFile imageFile) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.uploadFile<Map<String, dynamic>>(
          EndpointManager.repartidorLicencia(repartidorId),
          filePath: imageFile.path,
          fieldName: 'foto_licencia',
        );

        if (response.statusCode == 200 &&
            response.data?['status'] == 'success') {
          return response.data?['data']?['url'] as String?;
        }
        return null;
      },
      operationName: 'Subiendo foto de licencia para repartidor: $repartidorId',
    );
  }

  /// Sube foto de seguro vehicular del repartidor
  static Future<String?> uploadFotoSeguroVehiculo(
      String repartidorId, XFile imageFile) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.uploadFile<Map<String, dynamic>>(
          EndpointManager.repartidorSeguroVehiculo(repartidorId),
          filePath: imageFile.path,
          fieldName: 'foto_seguro_vehiculo',
        );

        if (response.statusCode == 200 &&
            response.data?['status'] == 'success') {
          return response.data?['data']?['url'] as String?;
        }
        return null;
      },
      operationName:
          'Subiendo foto de seguro vehicular para repartidor: $repartidorId',
    );
  }

  /// Cambia la contraseña del repartidor
  static Future<bool> cambiarPassword({
    required String repartidorId,
    required String nuevaPassword,
    required String confirmacionPassword,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch<Map<String, dynamic>>(
          '${EndpointManager.repartidores}/$repartidorId',
          data: {
            'password': nuevaPassword,
            'password_confirmation': confirmacionPassword,
          },
        );

        return response.data?['status'] == 'success';
      },
      operationName: 'Cambiando contraseña del repartidor: $repartidorId',
    );
  }
}

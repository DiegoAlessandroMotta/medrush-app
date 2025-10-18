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
      successMessage: 'Estado del repartidor actualizado exitosamente',
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
        final response =
            await BaseApi.post(EndpointManager.repartidores, data: {
          // Campos base del usuario (según RegisterBaseUserRequest)
          'name': repartidor.nombre,
          'email': repartidor.email,
          'password': repartidor.password,
          'password_confirmation': repartidor.password,
          'device_name': 'Flutter App',

          // Campos específicos del repartidor (según RegisterRepartidorUserRequest)
          'codigo_iso_pais': 'PER', // Código ISO para Perú
          'dni_id_numero': repartidor.dniIdNumero,
          'telefono': repartidor.telefono,
          'licencia_numero': repartidor.licenciaNumero,
          'licencia_vencimiento':
              repartidor.licenciaVencimiento?.toIso8601String(),
          'vehiculo_placa': repartidor.vehiculoPlaca,
          'vehiculo_marca': repartidor.vehiculoMarca,
          'vehiculo_modelo': repartidor.vehiculoModelo,

          // Campos adicionales que el backend podría aceptar
          'farmacia_id': repartidor.farmaciaId,
        });
        return ApiHelper.processSingleResponse(response.data, Usuario.fromJson);
      },
      operationName: 'Creando nuevo repartidor: ${repartidor.nombre}',
      successMessage: 'Repartidor creado exitosamente',
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
            'codigo_iso_pais': 'PER', // Código ISO para Perú
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
      successMessage: 'Repartidor actualizado exitosamente',
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
      successMessage: 'Repartidor eliminado exitosamente',
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
      successMessage: 'Foto de perfil subida exitosamente',
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
      successMessage: 'Foto de DNI/ID subida exitosamente',
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
      successMessage: 'Foto de licencia subida exitosamente',
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
      successMessage: 'Foto de seguro vehicular subida exitosamente',
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
      successMessage: 'Contraseña del repartidor cambiada exitosamente',
    );
  }
}

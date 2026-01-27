// UsuariosApi eliminado - no existe en el backend
import 'package:image_picker/image_picker.dart';
import 'package:medrush/api/repartidores.api.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/validators.dart';

/// Repository para gestionar la lógica de negocio de repartidores
/// Proporciona una capa de abstracción entre la UI y la API
class RepartidorRepository extends BaseRepository {
  RepartidorRepository();

  /// Obtiene todos los repartidores del sistema
  Future<RepositoryResult<List<Usuario>>> getAllRepartidores() {
    return execute<List<Usuario>>(() async {
      logInfo('Obteniendo todos los repartidores');
      final repartidores = await RepartidoresApi.getAllRepartidores();

      logInfo('${repartidores.length} repartidores obtenidos exitosamente');
      return repartidores;
    }, errorMessage: 'Error al obtener repartidores');
  }

  /// Obtiene un repartidor específico por ID
  Future<RepositoryResult<Usuario?>> getRepartidorById(String id) {
    return execute<Usuario?>(() async {
      validateId(id, 'ID de repartidor');
      logInfo('Obteniendo repartidor con ID: $id');
      final repartidor = await RepartidoresApi.getRepartidorById(id);

      if (repartidor != null) {
        logInfo('Repartidor obtenido: ${repartidor.nombre}');
      } else {
        logInfo('Repartidor no encontrado: $id');
      }

      return repartidor;
    }, errorMessage: 'Error al obtener repartidor por ID');
  }

  /// Actualiza el estado de un repartidor
  Future<RepositoryResult<bool>> updateEstadoRepartidor(
    String id,
    String nuevoEstado,
  ) {
    return execute<bool>(() async {
      validateId(id, 'ID de repartidor');
      validateNotEmpty(nuevoEstado, 'Estado del repartidor');

      logInfo('Actualizando estado del repartidor $id a: $nuevoEstado');
      final resultado =
          await RepartidoresApi.updateEstadoRepartidor(id, nuevoEstado);

      if (resultado) {
        logInfo('Estado del repartidor actualizado exitosamente');
      } else {
        logError('Error al actualizar estado del repartidor');
      }

      return resultado;
    }, errorMessage: 'Error al actualizar estado del repartidor');
  }

  /// Obtiene repartidores por estado
  Future<RepositoryResult<List<Usuario>>> getRepartidoresByEstado(
      String estado) {
    return execute<List<Usuario>>(() async {
      validateNotEmpty(estado, 'Estado del repartidor');
      logInfo('Obteniendo repartidores con estado: $estado');
      final repartidores =
          await RepartidoresApi.getRepartidoresByEstado(estado);

      logInfo(
          '${repartidores.length} repartidores con estado $estado obtenidos');
      return repartidores;
    }, errorMessage: 'Error al obtener repartidores por estado');
  }

  /// Obtiene repartidores disponibles
  Future<RepositoryResult<List<Usuario>>> getRepartidoresDisponibles() {
    return execute<List<Usuario>>(() async {
      logInfo('Obteniendo repartidores disponibles');
      final repartidores = await RepartidoresApi.getRepartidoresDisponibles();

      logInfo('${repartidores.length} repartidores disponibles obtenidos');
      return repartidores;
    }, errorMessage: 'Error al obtener repartidores disponibles');
  }

  /// Obtiene repartidores activos
  Future<RepositoryResult<List<Usuario>>> getRepartidoresActivos() {
    return execute<List<Usuario>>(() async {
      logInfo('Obteniendo repartidores activos');
      final repartidores = await RepartidoresApi.getRepartidoresActivos();

      logInfo('${repartidores.length} repartidores activos obtenidos');
      return repartidores;
    }, errorMessage: 'Error al obtener repartidores activos');
  }

  /// Crea un nuevo repartidor
  Future<RepositoryResult<Usuario?>> createRepartidor(Usuario repartidor) {
    return execute<Usuario?>(() async {
      validateNotNull(repartidor, 'Repartidor');
      logInfo('Creando nuevo repartidor: ${repartidor.nombre}');

      // Validar datos antes de enviar
      if (!validarDatosRepartidor(repartidor)) {
        throw ArgumentError('Datos del repartidor no válidos');
      }
      final nuevoRepartidor =
          await RepartidoresApi.createRepartidor(repartidor);

      if (nuevoRepartidor != null) {
        logInfo('Repartidor creado exitosamente: ${nuevoRepartidor.nombre}');
      } else {
        logError('Error al crear repartidor');
      }

      return nuevoRepartidor;
    }, errorMessage: 'Error al crear repartidor');
  }

  /// Actualiza un repartidor existente
  Future<RepositoryResult<Usuario?>> updateRepartidor(Usuario repartidor,
      {String? emailOriginal}) {
    return execute<Usuario?>(() async {
      validateNotNull(repartidor, 'Repartidor');
      validateId(repartidor.id, 'ID de repartidor');
      logInfo(
          'Actualizando repartidor: ${repartidor.nombre} (ID: ${repartidor.id})');

      // Validar datos antes de enviar
      if (!validarDatosRepartidor(repartidor)) {
        throw ArgumentError('Datos del repartidor no válidos');
      }
      final repartidorActualizado = await RepartidoresApi.updateRepartidor(
          repartidor,
          emailOriginal: emailOriginal);

      if (repartidorActualizado != null) {
        logInfo(
            'Repartidor actualizado exitosamente: ${repartidorActualizado.nombre}');
      } else {
        logError('Error al actualizar repartidor');
      }

      return repartidorActualizado;
    }, errorMessage: 'Error al actualizar repartidor');
  }

  /// Cambia el estado activo/inactivo del usuario (is_active)
  Future<RepositoryResult<bool>> setUsuarioActivo({
    required String userId,
    required bool isActive,
  }) {
    return execute<bool>(() async {
      validateId(userId, 'ID de usuario');
      logInfo('Actualizando is_active de usuario $userId a: $isActive');
      final ok = await RepartidoresApi.setUsuarioActivo(
        userId: userId,
        isActive: isActive,
      );
      if (!ok) {
        logError('Error al actualizar is_active');
      }
      return ok;
    }, errorMessage: 'Error al actualizar estado activo del usuario');
  }

  /// Elimina un repartidor
  Future<RepositoryResult<bool>> deleteRepartidor(String id) {
    return execute<bool>(() async {
      validateId(id, 'ID de repartidor');
      logInfo('Eliminando repartidor con ID: $id');
      final resultado = await RepartidoresApi.deleteRepartidor(id);

      if (resultado) {
        logInfo('Repartidor eliminado exitosamente');
      } else {
        logError('Error al eliminar repartidor');
      }

      return resultado;
    }, errorMessage: 'Error al eliminar repartidor');
  }

  /// Valida los datos de un repartidor
  bool validarDatosRepartidor(Usuario repartidor) {
    try {
      validateNotNull(repartidor, 'Repartidor');
      validateNotEmpty(repartidor.nombre, 'Nombre del repartidor');
      validateEmail(repartidor.email);

      // Validar teléfono si existe
      if (repartidor.telefono != null && repartidor.telefono!.isNotEmpty) {
        if (!Validators.isValidPhoneFormat(repartidor.telefono!)) {
          throw ArgumentError('Formato de teléfono no válido');
        }
      }

      return true;
    } catch (e) {
      logError('Error de validación en repartidor', e);
      return false;
    }
  }

  /// Obtiene estadísticas de repartidores
  Future<RepositoryResult<Map<String, dynamic>>> getEstadisticasRepartidores() {
    return execute<Map<String, dynamic>>(() async {
      logInfo('Obteniendo estadísticas de repartidores');
      final todosRepartidores =
          await RepartidoresApi.getAllRepartidoresCompletos();
      final repartidoresActivos =
          await RepartidoresApi.getRepartidoresActivos();
      final repartidoresDisponibles =
          await RepartidoresApi.getRepartidoresDisponibles();

      final int total = todosRepartidores.length;
      final estadisticas = {
        'total': todosRepartidores.length,
        'activos': repartidoresActivos.length,
        'disponibles': repartidoresDisponibles.length,
        'ocupados': todosRepartidores.length - repartidoresDisponibles.length,
        'porcentajeActivos':
            total == 0 ? 0.0 : (repartidoresActivos.length / total) * 100,
        'porcentajeDisponibles':
            total == 0 ? 0.0 : (repartidoresDisponibles.length / total) * 100,
      };

      logInfo('Estadísticas de repartidores obtenidas: $estadisticas');
      return estadisticas;
    }, errorMessage: 'Error al obtener estadísticas de repartidores');
  }

  /// Busca repartidores por nombre o email
  Future<RepositoryResult<List<Usuario>>> buscarRepartidores(String query) {
    return execute<List<Usuario>>(() async {
      validateNotEmpty(query, 'Consulta de búsqueda');
      logInfo('Buscando repartidores con: $query');
      final todosRepartidores = await RepartidoresApi.getAllRepartidores();

      final repartidoresFiltrados = todosRepartidores.where((repartidor) {
        final nombre = repartidor.nombre.toLowerCase();
        final email = repartidor.email.toLowerCase();
        final queryLower = query.toLowerCase();

        return nombre.contains(queryLower) || email.contains(queryLower);
      }).toList();

      logInfo('${repartidoresFiltrados.length} repartidores encontrados');
      return repartidoresFiltrados;
    }, errorMessage: 'Error al buscar repartidores');
  }

  /// Sube foto de perfil del repartidor
  Future<RepositoryResult<String?>> uploadFotoPerfil(XFile imageFile) {
    return execute<String?>(() async {
      logInfo('Subiendo foto de perfil');

      final url = await RepartidoresApi.uploadFotoPerfil(imageFile);

      if (url != null) {
        logInfo('Foto de perfil subida exitosamente: $url');
      } else {
        logError('Error al subir foto de perfil');
      }

      return url;
    }, errorMessage: 'Error al subir foto de perfil');
  }

  /// Sube foto de DNI/ID del repartidor
  Future<RepositoryResult<String?>> uploadFotoDniId(
      String repartidorId, XFile imageFile) {
    return execute<String?>(() async {
      validateId(repartidorId, 'ID de repartidor');
      logInfo('Subiendo foto de DNI/ID para repartidor: $repartidorId');

      final url =
          await RepartidoresApi.uploadFotoDniId(repartidorId, imageFile);

      if (url != null) {
        logInfo('Foto de DNI/ID subida exitosamente: $url');
      } else {
        logError('Error al subir foto de DNI/ID');
      }

      return url;
    }, errorMessage: 'Error al subir foto de DNI/ID');
  }

  /// Sube foto de licencia del repartidor
  Future<RepositoryResult<String?>> uploadFotoLicencia(
      String repartidorId, XFile imageFile) {
    return execute<String?>(() async {
      validateId(repartidorId, 'ID de repartidor');
      logInfo('Subiendo foto de licencia para repartidor: $repartidorId');

      final url =
          await RepartidoresApi.uploadFotoLicencia(repartidorId, imageFile);

      if (url != null) {
        logInfo('Foto de licencia subida exitosamente: $url');
      } else {
        logError('Error al subir foto de licencia');
      }

      return url;
    }, errorMessage: 'Error al subir foto de licencia');
  }

  /// Sube foto de seguro vehicular del repartidor
  Future<RepositoryResult<String?>> uploadFotoSeguroVehiculo(
      String repartidorId, XFile imageFile) {
    return execute<String?>(() async {
      validateId(repartidorId, 'ID de repartidor');
      logInfo(
          'Subiendo foto de seguro vehicular para repartidor: $repartidorId');

      final url = await RepartidoresApi.uploadFotoSeguroVehiculo(
          repartidorId, imageFile);

      if (url != null) {
        logInfo('Foto de seguro vehicular subida exitosamente: $url');
      } else {
        logError('Error al subir foto de seguro vehicular');
      }

      return url;
    }, errorMessage: 'Error al subir foto de seguro vehicular');
  }

  /// Cambia la contraseña del repartidor
  Future<RepositoryResult<bool>> cambiarPassword({
    required String repartidorId,
    required String nuevaPassword,
    required String confirmacionPassword,
  }) {
    return execute<bool>(() async {
      validateId(repartidorId, 'ID de repartidor');
      validateNotEmpty(nuevaPassword, 'Nueva contraseña');
      validateNotEmpty(confirmacionPassword, 'Confirmación de contraseña');

      // Validar que las contraseñas coincidan
      if (nuevaPassword != confirmacionPassword) {
        throw ArgumentError('Las contraseñas no coinciden');
      }

      // Validar longitud mínima
      if (nuevaPassword.length < 8) {
        throw ArgumentError('La contraseña debe tener al menos 8 caracteres');
      }

      logInfo('Cambiando contraseña del repartidor: $repartidorId');

      final resultado = await RepartidoresApi.cambiarPassword(
        repartidorId: repartidorId,
        nuevaPassword: nuevaPassword,
        confirmacionPassword: confirmacionPassword,
      );

      if (resultado) {
        logInfo('Contraseña del repartidor cambiada exitosamente');
      } else {
        logError('Error al cambiar contraseña del repartidor');
      }

      return resultado;
    }, errorMessage: 'Error al cambiar contraseña del repartidor');
  }
}

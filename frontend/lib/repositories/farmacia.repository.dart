import 'dart:math';

import 'package:medrush/api/farmacias.api.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/pagination.model.dart' as pagination;
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/utils/validators.dart';

/// Repositorio para la gestión de farmacias
/// Proporciona una capa de abstracción entre los providers y la API de farmacias
class FarmaciaRepository extends BaseRepository {
  FarmaciaRepository();

  /// Obtiene una farmacia por su ID
  Future<RepositoryResult<Farmacia?>> obtenerPorId(String id) {
    return execute(() async {
      validateId(id, 'ID de farmacia');

      final farmacia = await FarmaciasApi.getFarmaciaById(id);

      return farmacia;
    }, errorMessage: 'Error al obtener farmacia por ID');
  }

  /// Obtiene todas las farmacias
  Future<RepositoryResult<List<Farmacia>>> obtenerTodas() {
    return execute(() async {
      final farmacias = await FarmaciasApi.getAllFarmacias();

      return farmacias;
    }, errorMessage: 'Error al obtener farmacias');
  }

  /// Obtiene farmacias activas
  Future<RepositoryResult<List<Farmacia>>> obtenerActivas() {
    return execute(() async {
      final todasFarmacias = await FarmaciasApi.getAllFarmaciasCompletas();
      final farmaciasActivas = todasFarmacias
          .where((f) => f.estado == EstadoFarmacia.activa)
          .toList();

      return farmaciasActivas;
    }, errorMessage: 'Error al obtener farmacias activas');
  }

  /// Busca farmacias por nombre
  Future<RepositoryResult<List<Farmacia>>> buscarPorNombre(String nombre) {
    return execute(() async {
      validateNotEmpty(nombre, 'Nombre de farmacia');

      final farmacias = await FarmaciasApi.searchFarmacias(nombre);

      return farmacias;
    }, errorMessage: 'Error al buscar farmacias por nombre');
  }

  /// Obtiene farmacias cercanas a una ubicación (calculado localmente)
  Future<RepositoryResult<List<Farmacia>>> obtenerCercanas(
    double latitud,
    double longitud, {
    double radioKm = 5.0,
  }) {
    return execute(() async {
      validateNotNull(latitud, 'Latitud');
      validateNotNull(longitud, 'Longitud');

      // Como no existe endpoint específico, obtener todas y filtrar localmente
      final todasFarmacias = await FarmaciasApi.getAllFarmaciasCompletas();

      // Filtrar farmacias dentro del radio (implementación básica)
      final farmaciasCercanas = todasFarmacias.where((farmacia) {
        final distancia = _calcularDistancia(
            latitud, longitud, farmacia.latitud, farmacia.longitud);
        return distancia <= radioKm;
      }).toList();

      return farmaciasCercanas;
    }, errorMessage: 'Error al obtener farmacias cercanas');
  }

  /// Calcula la distancia entre dos puntos (fórmula de Haversine)
  double _calcularDistancia(
      double lat1, double lon1, double lat2, double lon2) {
    const double radioTierra = 6371; // Radio de la Tierra en kilómetros

    final double dLat = _gradosARadianes(lat2 - lat1);
    final double dLon = _gradosARadianes(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(lat1)) *
            cos(_gradosARadianes(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return radioTierra * c;
  }

  /// Convierte grados a radianes
  double _gradosARadianes(double grados) {
    return grados * (3.14159265359 / 180);
  }

  /// Crea una nueva farmacia
  Future<RepositoryResult<Farmacia>> crear(Farmacia farmacia) {
    return execute(() async {
      validateNotNull(farmacia, 'Farmacia');
      validateNotEmpty(farmacia.nombre, 'Nombre de farmacia');
      validateNotEmpty(farmacia.direccion, 'Dirección');
      validateNotEmpty(farmacia.telefono, 'Teléfono');
      final farmaciaCreada = await FarmaciasApi.createFarmacia(farmacia);

      return farmaciaCreada;
    }, errorMessage: 'Error al crear farmacia');
  }

  /// Actualiza una farmacia existente
  Future<RepositoryResult<Farmacia>> actualizar(Farmacia farmacia) {
    return execute(() async {
      validateNotNull(farmacia, 'Farmacia');
      validateId(farmacia.id, 'ID de farmacia');
      validateNotEmpty(farmacia.nombre, 'Nombre de farmacia');
      validateNotEmpty(farmacia.direccion, 'Dirección');
      validateNotEmpty(farmacia.telefono, 'Teléfono');
      final farmaciaActualizada = await FarmaciasApi.updateFarmacia(farmacia);

      return farmaciaActualizada;
    }, errorMessage: 'Error al actualizar farmacia');
  }

  /// Activa o desactiva una farmacia
  Future<RepositoryResult<bool>> cambiarEstadoActivo(String farmaciaId,
      {required bool activo}) {
    return execute(() async {
      validateId(farmaciaId, 'ID de farmacia');

      // Como no existe el método específico en la API, simular la actualización
      // En una implementación real, esto se haría mediante updateFarmacia
      final farmacia = await FarmaciasApi.getFarmaciaById(farmaciaId);
      if (farmacia == null) {
        throw Exception('Farmacia no encontrada');
      }

      final estadoNuevo =
          activo ? EstadoFarmacia.activa : EstadoFarmacia.inactiva;
      final farmaciaActualizada = farmacia.copyWith(estado: estadoNuevo);

      await FarmaciasApi.updateFarmacia(farmaciaActualizada);

      return true;
    }, errorMessage: 'Error al cambiar estado de la farmacia');
  }

  /// Elimina una farmacia
  Future<RepositoryResult<bool>> eliminar(String farmaciaId) {
    return execute(() async {
      validateId(farmaciaId, 'ID de farmacia');

      final resultado = await FarmaciasApi.deleteFarmacia(farmaciaId);

      return resultado;
    }, errorMessage: 'Error al eliminar farmacia');
  }

  /// Obtiene estadísticas de farmacias
  Future<RepositoryResult<Map<String, dynamic>>> obtenerEstadisticas() {
    return execute(() async {
      final todasFarmacias = await FarmaciasApi.getAllFarmaciasCompletas();
      final farmaciasActivas = todasFarmacias
          .where((f) => f.estado == EstadoFarmacia.activa)
          .toList();

      final int total = todasFarmacias.length;
      final estadisticas = {
        'total': todasFarmacias.length,
        'activas': farmaciasActivas.length,
        'inactivas': todasFarmacias.length - farmaciasActivas.length,
        'porcentajeActivas':
            total == 0 ? 0.0 : (farmaciasActivas.length / total) * 100,
      };

      return estadisticas;
    }, errorMessage: 'Error al obtener estadísticas de farmacias');
  }

  /// Obtiene estadísticas desde la API (usando método local)
  Future<RepositoryResult<Map<String, dynamic>>> obtenerEstadisticasDesdeApi() {
    return execute(() async {
      // Usar el método local ya que no existe endpoint específico
      final resultado = await obtenerEstadisticas();
      return resultado.data!;
    }, errorMessage: 'Error al obtener estadísticas de farmacias desde API');
  }

  /// Actualiza solo el estado de una farmacia
  Future<RepositoryResult<Farmacia>> actualizarEstado(
    String farmaciaId,
    EstadoFarmacia estado,
  ) {
    return execute(() async {
      validateId(farmaciaId, 'ID de farmacia');

      // Obtener farmacia actual
      final farmacia = await FarmaciasApi.getFarmaciaById(farmaciaId);
      if (farmacia == null) {
        throw Exception('Farmacia no encontrada');
      }

      // Actualizar usando el método general
      final farmaciaActualizada = farmacia.copyWith(estado: estado);
      final resultado = await FarmaciasApi.updateFarmacia(farmaciaActualizada);

      return resultado;
    }, errorMessage: 'Error al actualizar estado de la farmacia');
  }

  /// Actualiza solo la ubicación de una farmacia
  Future<RepositoryResult<Farmacia>> actualizarUbicacion(
    String farmaciaId,
    double latitud,
    double longitud,
  ) {
    return execute(() async {
      validateId(farmaciaId, 'ID de farmacia');
      validateNotNull(latitud, 'Latitud');
      validateNotNull(longitud, 'Longitud');

      // Validar coordenadas
      if (latitud < -90 || latitud > 90) {
        throw ArgumentError('Latitud debe estar entre -90 y 90');
      }
      if (longitud < -180 || longitud > 180) {
        throw ArgumentError('Longitud debe estar entre -180 y 180');
      }

      // Obtener farmacia actual
      final farmacia = await FarmaciasApi.getFarmaciaById(farmaciaId);
      if (farmacia == null) {
        throw Exception('Farmacia no encontrada');
      }

      // Actualizar usando el método general
      final farmaciaActualizada = farmacia.copyWith(
        latitud: latitud,
        longitud: longitud,
      );
      final resultado = await FarmaciasApi.updateFarmacia(farmaciaActualizada);

      return resultado;
    }, errorMessage: 'Error al actualizar ubicación de la farmacia');
  }

  /// Obtiene farmacias con paginación
  Future<RepositoryResult<pagination.PaginatedResponse<Farmacia>>>
      obtenerPaginadas({
    int page = 1,
    int perPage = 20,
    String? orderBy,
    String orderDirection = 'desc',
    String? search,
    String? city,
    String? cadena,
    bool? delivery24h,
    String? estado,
  }) {
    return execute(() async {
      final resultado = await FarmaciasApi.getFarmaciasPaginated(
        page: page,
        perPage: perPage,
        orderBy: orderBy,
        orderDirection: orderDirection,
        search: search,
        city: city,
        cadena: cadena,
        delivery24h: delivery24h,
        estado: estado,
      );

      return resultado;
    }, errorMessage: 'Error al obtener farmacias paginadas');
  }

  /// Valida los datos de una farmacia antes de crear/actualizar
  bool validarDatosFarmacia(Farmacia farmacia) {
    try {
      validateNotNull(farmacia, 'Farmacia');
      validateNotEmpty(farmacia.nombre, 'Nombre de farmacia');
      validateNotEmpty(farmacia.direccion, 'Dirección');
      // Validar teléfono solo si no es null
      if (farmacia.telefono != null && farmacia.telefono!.isNotEmpty) {
        // Validar formato de teléfono
        if (!Validators.isValidPhoneFormat(farmacia.telefono!)) {
          throw ArgumentError('Formato de teléfono no válido');
        }
      }

      // Validar email si existe
      if (farmacia.email != null && farmacia.email!.isNotEmpty) {
        validateEmail(farmacia.email!);
      }

      // Validar coordenadas (siempre están presentes en el modelo)
      if (farmacia.latitud < -90 || farmacia.latitud > 90) {
        throw ArgumentError('Latitud debe estar entre -90 y 90');
      }
      if (farmacia.longitud < -180 || farmacia.longitud > 180) {
        throw ArgumentError('Longitud debe estar entre -180 y 180');
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Helper estático para cargar farmacias con manejo de estado consistente
  /// Retorna un Map con 'farmacias', 'isLoading', 'error' y 'success'
  static Future<Map<String, dynamic>> loadFarmaciasWithState({
    bool showLoading = true,
    String? errorMessage,
  }) async {
    final repository = FarmaciaRepository();

    try {
      if (showLoading) {
        // Simular estado de carga inicial
      }

      final result = await repository.obtenerTodas();

      if (result.success && result.data != null) {
        return {
          'farmacias': result.data!,
          'isLoading': false,
          'error': null,
          'success': true,
        };
      } else {
        return {
          'farmacias': <Farmacia>[],
          'isLoading': false,
          'error': result.error ?? errorMessage ?? 'Error al cargar farmacias',
          'success': false,
        };
      }
    } catch (e) {
      return {
        'farmacias': <Farmacia>[],
        'isLoading': false,
        'error': errorMessage ?? 'Error al cargar farmacias: $e',
        'success': false,
      };
    }
  }

  /// Helper estático para cargar farmacias activas con manejo de estado consistente
  static Future<Map<String, dynamic>> loadFarmaciasActivasWithState({
    bool showLoading = true,
    String? errorMessage,
  }) async {
    final repository = FarmaciaRepository();

    try {
      if (showLoading) {
        // Simular estado de carga inicial
      }

      final result = await repository.obtenerActivas();

      if (result.success && result.data != null) {
        return {
          'farmacias': result.data!,
          'isLoading': false,
          'error': null,
          'success': true,
        };
      } else {
        return {
          'farmacias': <Farmacia>[],
          'isLoading': false,
          'error': result.error ??
              errorMessage ??
              'Error al cargar farmacias activas',
          'success': false,
        };
      }
    } catch (e) {
      return {
        'farmacias': <Farmacia>[],
        'isLoading': false,
        'error': errorMessage ?? 'Error al cargar farmacias activas: $e',
        'success': false,
      };
    }
  }
}

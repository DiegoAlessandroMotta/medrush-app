import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/rutas.api.dart';
import 'package:medrush/models/pagination.model.dart' as pagination;
import 'package:medrush/models/ruta_optimizada.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/utils/loggers.dart';

/// Repositorio para la gestión de rutas optimizadas
/// Proporciona una capa de abstracción entre los providers y la API de rutas
class RutaRepository extends BaseRepository {
  RutaRepository();

  /// Obtiene una ruta optimizada por su ID
  Future<RepositoryResult<RutaOptimizada?>> obtenerPorId(String id) {
    return execute(() async {
      validateId(id, 'ID de ruta');

      logInfo('Obteniendo ruta optimizada: $id');
      final ruta = await RutasOptimizadasApi.getRutaOptimizadaById(id);

      if (ruta != null) {
        logInfo('Ruta optimizada obtenida exitosamente: ${ruta.id}');
      } else {
        logInfo('Ruta optimizada no encontrada: $id');
      }

      return ruta;
    }, errorMessage: 'Error al obtener ruta optimizada por ID');
  }

  /// Obtiene todas las rutas optimizadas con paginación
  Future<RepositoryResult<pagination.PaginatedResponse<RutaOptimizada>>>
      obtenerPaginadas({
    int page = 1,
    int perPage = 20,
    String? orderBy = 'created_at',
    String? orderDirection = 'desc',
  }) {
    return execute(() async {
      logInfo(
          'Obteniendo rutas optimizadas paginadas: página $page, $perPage por página');

      // Usar BaseApi.getPaginated para obtener datos paginados del backend
      final response = await BaseApi.getPaginated<RutaOptimizada>(
        '/rutas', // FIX: Corregir endpoint para coincidir con backend
        fromJson: RutaOptimizada.fromJson,
        page: page,
        perPage: perPage,
        filters: {
          if (orderBy != null) 'order_by': orderBy,
          if (orderDirection != null) 'order_direction': orderDirection,
        },
      );

      logInfo('${response.items.length} rutas optimizadas obtenidas');
      return response;
    }, errorMessage: 'Error al obtener rutas optimizadas paginadas');
  }

  /// Obtiene todas las rutas optimizadas (sin paginación)
  Future<RepositoryResult<List<RutaOptimizada>>> obtenerTodas({
    int perPage = 100,
    String? orderBy = 'created_at',
    String? orderDirection = 'desc',
  }) {
    return execute(() async {
      logInfo('Obteniendo todas las rutas optimizadas');

      final rutas = await RutasOptimizadasApi.getAllRutasOptimizadas(
        perPage: perPage,
        orderBy: orderBy,
        orderDirection: orderDirection,
      );

      logInfo('${rutas.length} rutas optimizadas obtenidas');
      return rutas;
    }, errorMessage: 'Error al obtener todas las rutas optimizadas');
  }

  /// Obtiene rutas optimizadas activas (sin fecha de completado)
  Future<RepositoryResult<List<RutaOptimizada>>> obtenerActivas() {
    return execute(() async {
      logInfo('Obteniendo rutas optimizadas activas');

      final rutas = await RutasOptimizadasApi.getRutasActivas();

      logInfo('${rutas.length} rutas activas obtenidas');
      return rutas;
    }, errorMessage: 'Error al obtener rutas activas');
  }

  /// Obtiene rutas optimizadas por repartidor
  Future<RepositoryResult<List<RutaOptimizada>>> obtenerPorRepartidor(
      String repartidorId) {
    return execute(() async {
      validateId(repartidorId, 'ID de repartidor');

      logInfo('Obteniendo rutas del repartidor: $repartidorId');

      final rutas =
          await RutasOptimizadasApi.getRutasByRepartidor(repartidorId);

      logInfo('${rutas.length} rutas del repartidor obtenidas');
      return rutas;
    }, errorMessage: 'Error al obtener rutas por repartidor');
  }

  /// Obtiene los pedidos de una ruta específica
  Future<RepositoryResult<List<Map<String, dynamic>>>> obtenerPedidosRuta({
    required String rutaId,
    String? estado,
    String? orderBy,
    String? orderDirection,
  }) {
    return execute(() async {
      validateId(rutaId, 'ID de ruta');

      logInfo('Obteniendo pedidos de la ruta: $rutaId');

      final pedidos = await RutasOptimizadasApi.getPedidosRutaOptimizada(
        rutaId: rutaId,
        estado: estado,
        orderBy: orderBy,
        orderDirection: orderDirection,
      );

      logInfo('${pedidos.length} pedidos de la ruta obtenidos');
      return pedidos;
    }, errorMessage: 'Error al obtener pedidos de la ruta');
  }

  /// Obtiene una ruta con sus pedidos en paralelo (patrón optimizado)
  Future<RepositoryResult<Map<String, dynamic>>> obtenerRutaConPedidos({
    required String rutaId,
    String? estadoPedidos,
    String? orderBy,
    String? orderDirection,
  }) {
    return execute(() async {
      validateId(rutaId, 'ID de ruta');

      logInfo('Obteniendo ruta con pedidos en paralelo: $rutaId');

      // Ejecutar ambas consultas en paralelo
      final futures = await Future.wait([
        obtenerPorId(rutaId),
        obtenerPedidosRuta(
          rutaId: rutaId,
          estado: estadoPedidos,
          orderBy: orderBy,
          orderDirection: orderDirection,
        ),
      ]);

      final rutaResult = futures[0] as RepositoryResult<RutaOptimizada?>;
      final pedidosResult =
          futures[1] as RepositoryResult<List<Map<String, dynamic>>>;

      // Verificar si ambas operaciones fueron exitosas
      if (!rutaResult.success) {
        throw Exception('Error al obtener ruta: ${rutaResult.error}');
      }

      if (!pedidosResult.success) {
        throw Exception('Error al obtener pedidos: ${pedidosResult.error}');
      }

      final ruta = rutaResult.data;
      final pedidos = pedidosResult.data ?? [];

      if (ruta == null) {
        throw Exception('Ruta no encontrada');
      }

      logInfo('Ruta con ${pedidos.length} pedidos obtenida exitosamente');

      return {
        'ruta': ruta,
        'pedidos': pedidos,
      };
    }, errorMessage: 'Error al obtener ruta con pedidos');
  }

  /// Crea una nueva ruta optimizada
  Future<RepositoryResult<RutaOptimizada?>> crear({
    required String repartidorId,
    required String nombre,
    Map<String, dynamic>? puntoInicio,
    Map<String, dynamic>? puntoFinal,
    String? polylineEncoded,
    double? distanciaTotalEstimada,
    int? tiempoTotalEstimado,
    DateTime? fechaInicio,
    DateTime? fechaCompletado,
  }) {
    return execute(() async {
      validateId(repartidorId, 'ID de repartidor');
      validateNotEmpty(nombre, 'Nombre de la ruta');

      logInfo('Creando nueva ruta optimizada para repartidor: $repartidorId');

      final ruta = await RutasOptimizadasApi.createRutaOptimizada(
        repartidorId: repartidorId,
        nombre: nombre,
        puntoInicio: puntoInicio,
        puntoFinal: puntoFinal,
        polylineEncoded: polylineEncoded,
        distanciaTotalEstimada: distanciaTotalEstimada,
        tiempoTotalEstimado: tiempoTotalEstimado,
        fechaInicio: fechaInicio,
        fechaCompletado: fechaCompletado,
      );

      if (ruta != null) {
        logInfo('Ruta optimizada creada exitosamente: ${ruta.id}');
      }

      return ruta;
    }, errorMessage: 'Error al crear ruta optimizada');
  }

  /// Actualiza una ruta optimizada existente
  Future<RepositoryResult<RutaOptimizada?>> actualizar({
    required String id,
    String? nombre,
    Map<String, dynamic>? puntoInicio,
    Map<String, dynamic>? puntoFinal,
    String? polylineEncoded,
    double? distanciaTotalEstimada,
    int? tiempoTotalEstimado,
    DateTime? fechaInicio,
    DateTime? fechaCompletado,
  }) {
    return execute(() async {
      validateId(id, 'ID de ruta');

      logInfo('Actualizando ruta optimizada: $id');

      final ruta = await RutasOptimizadasApi.updateRutaOptimizada(
        id: id,
        nombre: nombre,
        puntoInicio: puntoInicio,
        puntoFinal: puntoFinal,
        polylineEncoded: polylineEncoded,
        distanciaTotalEstimada: distanciaTotalEstimada,
        tiempoTotalEstimado: tiempoTotalEstimado,
        fechaInicio: fechaInicio,
        fechaCompletado: fechaCompletado,
      );

      if (ruta != null) {
        logInfo('Ruta optimizada actualizada exitosamente: ${ruta.id}');
      }

      return ruta;
    }, errorMessage: 'Error al actualizar ruta optimizada');
  }

  /// Elimina una ruta optimizada
  Future<RepositoryResult<bool>> eliminar(String id) {
    return execute(() async {
      validateId(id, 'ID de ruta');

      logInfo('Eliminando ruta optimizada: $id');

      final resultado = await RutasOptimizadasApi.deleteRutaOptimizada(id);

      if (resultado) {
        logInfo('Ruta optimizada eliminada exitosamente: $id');
      }

      return resultado;
    }, errorMessage: 'Error al eliminar ruta optimizada');
  }

  /// Optimiza rutas usando Google Route Optimization API
  Future<RepositoryResult<Map<String, dynamic>>> optimizarRutas({
    required String codigoIsoPais,
    required String inicioJornada,
    required String finJornada,
    String? codigoPostal,
  }) {
    return execute(() async {
      validateNotEmpty(codigoIsoPais, 'Código ISO del país');
      validateNotEmpty(inicioJornada, 'Inicio de jornada');
      validateNotEmpty(finJornada, 'Fin de jornada');

      logInfo('Optimizando rutas con Google API');

      final resultado = await RutasOptimizadasApi.optimizeRutas(
        codigoIsoPais: codigoIsoPais,
        inicioJornada: inicioJornada,
        finJornada: finJornada,
        codigoPostal: codigoPostal,
      );

      logInfo('Rutas optimizadas exitosamente');
      return resultado;
    }, errorMessage: 'Error al optimizar rutas');
  }

  /// Re-optimiza una ruta existente
  Future<RepositoryResult<Map<String, dynamic>>> reOptimizarRuta({
    required String rutaId,
    required String inicioJornada,
    required String finJornada,
  }) {
    return execute(() async {
      validateId(rutaId, 'ID de ruta');
      validateNotEmpty(inicioJornada, 'Inicio de jornada');
      validateNotEmpty(finJornada, 'Fin de jornada');

      logInfo('Re-optimizando ruta: $rutaId');

      final resultado = await RutasOptimizadasApi.reOptimizarRuta(
        rutaId: rutaId,
        inicioJornada: inicioJornada,
        finJornada: finJornada,
      );

      logInfo('Ruta re-optimizada exitosamente: $rutaId');
      return resultado;
    }, errorMessage: 'Error al re-optimizar ruta');
  }

  /// Actualiza el orden personalizado de un pedido
  Future<RepositoryResult<bool>> actualizarOrdenPersonalizado({
    required String pedidoId,
    required int ordenPersonalizado,
  }) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');
      validateNotNull(ordenPersonalizado, 'Orden personalizado');

      logInfo('Actualizando orden personalizado del pedido: $pedidoId');

      final resultado = await RutasOptimizadasApi.actualizarOrdenPersonalizado(
        pedidoId: pedidoId,
        ordenPersonalizado: ordenPersonalizado,
      );

      if (resultado) {
        logInfo('Orden personalizado actualizado exitosamente');
      }

      return resultado;
    }, errorMessage: 'Error al actualizar orden personalizado');
  }

  /// Obtiene el estado de optimización de una ruta
  Future<RepositoryResult<Map<String, dynamic>>> obtenerEstadoOptimizacion(
      String rutaId) {
    return execute(() async {
      validateId(rutaId, 'ID de ruta');

      logInfo('Obteniendo estado de optimización: $rutaId');

      final estado = await RutasOptimizadasApi.getEstadoOptimizacion(
        rutaId: rutaId,
      );

      logInfo('Estado de optimización obtenido exitosamente');
      return estado;
    }, errorMessage: 'Error al obtener estado de optimización');
  }

  /// Obtiene la ruta actual del repartidor autenticado
  Future<RepositoryResult<Map<String, dynamic>?>> obtenerRutaActual({
    String? estado,
    String? orderBy,
    String? orderDirection,
  }) {
    return execute(() async {
      logInfo('Obteniendo ruta actual del repartidor autenticado');

      final rutaActual = await RutasOptimizadasApi.getRutaActual(
        estado: estado,
        orderBy: orderBy,
        orderDirection: orderDirection,
      );

      if (rutaActual != null) {
        logInfo('Ruta actual obtenida exitosamente');
      } else {
        logInfo('No se encontró ruta actual para el repartidor');
      }

      return rutaActual;
    }, errorMessage: 'Error al obtener ruta actual del repartidor');
  }

  /// Obtiene estadísticas de rutas optimizadas
  Future<RepositoryResult<Map<String, dynamic>>> obtenerEstadisticas() {
    return execute(() async {
      logInfo('Obteniendo estadísticas de rutas optimizadas');

      final estadisticas = await RutasOptimizadasApi.getRutasStats();

      logInfo('Estadísticas de rutas obtenidas exitosamente');
      return estadisticas;
    }, errorMessage: 'Error al obtener estadísticas de rutas');
  }

  /// Busca rutas por nombre o repartidor
  Future<RepositoryResult<List<RutaOptimizada>>> buscarRutas(String query) {
    return execute(() async {
      validateNotEmpty(query, 'Consulta de búsqueda');

      logInfo('Buscando rutas con: $query');

      // Como no existe endpoint específico de búsqueda, obtener todas y filtrar localmente
      final todasRutas = await RutasOptimizadasApi.getAllRutasOptimizadas(
        perPage: 1000, // Obtener más rutas para filtrar
      );

      final rutasFiltradas = todasRutas.where((ruta) {
        final nombre = ruta.nombre?.toLowerCase() ?? '';
        final repartidorNombre =
            ruta.repartidor?['nombre']?.toString().toLowerCase() ?? '';
        final queryLower = query.toLowerCase();

        return nombre.contains(queryLower) ||
            repartidorNombre.contains(queryLower);
      }).toList();

      logInfo('${rutasFiltradas.length} rutas encontradas');
      return rutasFiltradas;
    }, errorMessage: 'Error al buscar rutas');
  }

  /// Obtiene rutas por rango de fechas
  Future<RepositoryResult<List<RutaOptimizada>>> obtenerRutasPorRangoFechas(
    DateTime fechaInicio,
    DateTime fechaFin, {
    String? repartidorId,
  }) {
    return execute(() async {
      validateNotNull(fechaInicio, 'Fecha de inicio');
      validateNotNull(fechaFin, 'Fecha de fin');

      logInfo(
          'Obteniendo rutas del ${fechaInicio.toIso8601String()} al ${fechaFin.toIso8601String()}');

      // Como no existe endpoint específico, obtener todas y filtrar localmente
      final todasRutas = await RutasOptimizadasApi.getAllRutasOptimizadas(
        perPage: 1000, // Obtener más rutas para filtrar
      );

      final rutasFiltradas = todasRutas.where((ruta) {
        // Filtrar por rango de fechas
        final fechaCreacion = ruta.createdAt;
        final fechaInicioRuta = ruta.fechaInicio;

        final estaEnRango = fechaCreacion != null &&
            fechaCreacion.isAfter(fechaInicio) &&
            fechaCreacion.isBefore(fechaFin);

        final estaEnRangoInicio = fechaInicioRuta != null &&
            fechaInicioRuta.isAfter(fechaInicio) &&
            fechaInicioRuta.isBefore(fechaFin);

        final cumpleRepartidor =
            repartidorId == null || ruta.repartidor?['id'] == repartidorId;

        return (estaEnRango || estaEnRangoInicio) && cumpleRepartidor;
      }).toList();

      logInfo('${rutasFiltradas.length} rutas obtenidas en el rango de fechas');
      return rutasFiltradas;
    }, errorMessage: 'Error al obtener rutas por rango de fechas');
  }

  /// Valida los datos de una ruta antes de crear/actualizar
  bool validarDatosRuta({
    required String repartidorId,
    required String nombre,
    Map<String, dynamic>? puntoInicio,
    Map<String, dynamic>? puntoFinal,
  }) {
    try {
      validateId(repartidorId, 'ID de repartidor');
      validateNotEmpty(nombre, 'Nombre de la ruta');

      // Validar punto de inicio si se proporciona
      if (puntoInicio != null) {
        if (!puntoInicio.containsKey('lat') ||
            !puntoInicio.containsKey('lng')) {
          throw ArgumentError('Punto de inicio debe tener lat y lng');
        }
        final lat = puntoInicio['lat'] as double?;
        final lng = puntoInicio['lng'] as double?;
        if (lat == null || lng == null) {
          throw ArgumentError(
              'Lat y lng del punto de inicio deben ser números');
        }
        if (lat < -90 || lat > 90) {
          throw ArgumentError('Latitud debe estar entre -90 y 90');
        }
        if (lng < -180 || lng > 180) {
          throw ArgumentError('Longitud debe estar entre -180 y 180');
        }
      }

      // Validar punto final si se proporciona
      if (puntoFinal != null) {
        if (!puntoFinal.containsKey('lat') || !puntoFinal.containsKey('lng')) {
          throw ArgumentError('Punto final debe tener lat y lng');
        }
        final lat = puntoFinal['lat'] as double?;
        final lng = puntoFinal['lng'] as double?;
        if (lat == null || lng == null) {
          throw ArgumentError('Lat y lng del punto final deben ser números');
        }
        if (lat < -90 || lat > 90) {
          throw ArgumentError('Latitud debe estar entre -90 y 90');
        }
        if (lng < -180 || lng > 180) {
          throw ArgumentError('Longitud debe estar entre -180 y 180');
        }
      }

      return true;
    } catch (e) {
      logError('Error de validación de ruta: $e');
      return false;
    }
  }
}

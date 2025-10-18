import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/ruta_optimizada.model.dart';

class RutasOptimizadasApi {
  /// Obtiene todas las rutas optimizadas con paginación
  static Future<List<RutaOptimizada>> getAllRutasOptimizadas({
    int page = 1,
    int perPage = 20,
    String? orderBy = 'created_at',
    String? orderDirection = 'desc',
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          EndpointManager.rutas, // FIX: Usar endpoint correcto del backend
          queryParameters: {
            'current_page': page,
            'per_page': perPage,
            'order_by': orderBy,
            'order_direction': orderDirection,
          },
        );

        // FIX: Manejar estructura de respuesta del backend Laravel
        if (response.data?['status'] == 'success') {
          final List<dynamic> rutasData = response.data?['data'] ?? [];
          return rutasData
              .map((json) =>
                  RutaOptimizada.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return <RutaOptimizada>[];
      },
      operationName: 'Obteniendo rutas optimizadas: página $page',
      successMessage: 'Rutas optimizadas obtenidas exitosamente',
    );
  }

  /// Obtiene una ruta optimizada específica por ID
  static Future<RutaOptimizada?> getRutaOptimizadaById(String id) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          '${EndpointManager.rutas}/$id',
        );

        if (response.data?['status'] == 'success') {
          // El backend devuelve la ruta en response.data['data']['ruta']
          final rutaData = response.data?['data']?['ruta'];
          if (rutaData != null) {
            return RutaOptimizada.fromJson(rutaData as Map<String, dynamic>);
          }
        }
        return null;
      },
      operationName: 'Obteniendo ruta optimizada: $id',
      successMessage: 'Ruta optimizada obtenida exitosamente',
    );
  }

  /// Obtiene los pedidos de una ruta específica (ya ordenados por el backend)
  static Future<List<Map<String, dynamic>>> getPedidosRuta({
    required String rutaId,
    String? estado,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final queryParams = <String, String>{};

        if (estado != null) {
          queryParams['estado'] = estado;
        }

        final response = await BaseApi.get<Map<String, dynamic>>(
          '${EndpointManager.rutas}/$rutaId',
          queryParameters: queryParams,
        );

        if (response.data?['status'] == 'success') {
          // El backend devuelve los pedidos en response.data['data']['pedidos']
          final List<dynamic> pedidosData =
              response.data?['data']?['pedidos'] ?? [];
          return pedidosData.cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      },
      operationName: 'Obteniendo pedidos de la ruta: $rutaId',
      successMessage: 'Pedidos de la ruta obtenidos exitosamente',
    );
  }

  /// Crea una nueva ruta optimizada
  static Future<RutaOptimizada?> createRutaOptimizada({
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
    return ApiHelper.executeWithLogging(
      () async {
        final data = <String, dynamic>{
          'repartidor_id': repartidorId,
          'nombre': nombre,
        };

        if (puntoInicio != null) {
          data['punto_inicio'] = puntoInicio;
        }
        if (puntoFinal != null) {
          data['punto_final'] = puntoFinal;
        }
        if (polylineEncoded != null) {
          data['polyline_encoded'] = polylineEncoded;
        }
        if (distanciaTotalEstimada != null) {
          data['distancia_total_estimada'] = distanciaTotalEstimada;
        }
        if (tiempoTotalEstimado != null) {
          data['tiempo_total_estimado'] = tiempoTotalEstimado;
        }
        if (fechaInicio != null) {
          data['fecha_inicio'] = fechaInicio.toIso8601String();
        }
        if (fechaCompletado != null) {
          data['fecha_completado'] = fechaCompletado.toIso8601String();
        }

        final response = await BaseApi.post<Map<String, dynamic>>(
          EndpointManager.rutas,
          data: data,
        );

        if (response.data?['status'] == 'success') {
          return RutaOptimizada.fromJson(response.data?['data']);
        }
        return null;
      },
      operationName:
          'Creando nueva ruta optimizada para repartidor: $repartidorId',
      successMessage: 'Ruta optimizada creada exitosamente',
    );
  }

  /// Actualiza una ruta optimizada existente
  static Future<RutaOptimizada?> updateRutaOptimizada({
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
    return ApiHelper.executeWithLogging(
      () async {
        final data = <String, dynamic>{};
        if (nombre != null) {
          data['nombre'] = nombre;
        }
        if (puntoInicio != null) {
          data['punto_inicio'] = puntoInicio;
        }
        if (puntoFinal != null) {
          data['punto_final'] = puntoFinal;
        }
        if (polylineEncoded != null) {
          data['polyline_encoded'] = polylineEncoded;
        }
        if (distanciaTotalEstimada != null) {
          data['distancia_total_estimada'] = distanciaTotalEstimada;
        }
        if (tiempoTotalEstimado != null) {
          data['tiempo_total_estimado'] = tiempoTotalEstimado;
        }
        if (fechaInicio != null) {
          data['fecha_inicio'] = fechaInicio.toIso8601String();
        }
        if (fechaCompletado != null) {
          data['fecha_completado'] = fechaCompletado.toIso8601String();
        }

        final response = await BaseApi.patch<Map<String, dynamic>>(
          '${EndpointManager.rutas}/$id',
          data: data,
        );

        if (response.data?['status'] == 'success') {
          return RutaOptimizada.fromJson(response.data?['data']);
        }
        return null;
      },
      operationName: 'Actualizando ruta optimizada: $id',
      successMessage: 'Ruta optimizada actualizada exitosamente',
    );
  }

  /// Elimina una ruta optimizada
  static Future<bool> deleteRutaOptimizada(String id) {
    return ApiHelper.executeWithLogging(
      () async {
        await BaseApi.delete('${EndpointManager.rutas}/$id');
        return true;
      },
      operationName: 'Eliminando ruta optimizada: $id',
      successMessage: 'Ruta optimizada eliminada exitosamente',
    );
  }

  /// Optimiza rutas usando Google Route Optimization API
  static Future<Map<String, dynamic>> optimizeRutas({
    required String codigoIsoPais,
    required String inicioJornada,
    required String finJornada,
    String? codigoPostal,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.post<Map<String, dynamic>>(
          '${EndpointManager.rutas}/optimizar',
          data: {
            'codigo_iso_pais': codigoIsoPais,
            'inicio_jornada': inicioJornada,
            'fin_jornada': finJornada,
            if (codigoPostal != null) 'codigo_postal': codigoPostal,
          },
        );

        return response.data ?? <String, dynamic>{};
      },
      operationName: 'Optimizando rutas con Google API',
      successMessage: 'Rutas optimizadas exitosamente',
    );
  }

  /// Obtiene los pedidos de una ruta optimizada específica
  static Future<List<Map<String, dynamic>>> getPedidosRutaOptimizada({
    required String rutaId,
    String? estado,
    String? orderBy,
    String? orderDirection,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final queryParams = <String, dynamic>{};

        // Solo agregar parámetros si se especifican explícitamente
        if (orderBy != null) {
          queryParams['order_by'] = orderBy;
        }
        if (orderDirection != null) {
          queryParams['order_direction'] = orderDirection;
        }
        if (estado != null) {
          queryParams['estado'] = estado;
        }

        final response = await BaseApi.get<Map<String, dynamic>>(
          '${EndpointManager.rutas}/$rutaId/pedidos',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        if (response.data?['status'] == 'success') {
          final List<dynamic> pedidosData = response.data?['data'] ?? [];
          return pedidosData
              .map((json) => json as Map<String, dynamic>)
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
      operationName: 'Obteniendo pedidos de ruta optimizada: $rutaId',
      successMessage: 'Pedidos de ruta optimizada obtenidos exitosamente',
    );
  }

  /// Obtiene rutas optimizadas por repartidor
  static Future<List<RutaOptimizada>> getRutasByRepartidor(
      String repartidorId) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          EndpointManager.rutas,
          queryParameters: {
            'repartidor_id': repartidorId
          }, // FIX: Usar parámetro correcto
        );

        // FIX: Manejar estructura de respuesta del backend Laravel
        if (response.data?['status'] == 'success') {
          final List<dynamic> rutasData = response.data?['data'] ?? [];
          return rutasData
              .map((json) =>
                  RutaOptimizada.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return <RutaOptimizada>[];
      },
      operationName:
          'Obteniendo rutas optimizadas del repartidor: $repartidorId',
      successMessage: 'Rutas del repartidor obtenidas exitosamente',
    );
  }

  /// Obtiene rutas optimizadas activas (sin fecha de completado)
  static Future<List<RutaOptimizada>> getRutasActivas() {
    return ApiHelper.executeWithLogging(
      () async {
        // FIX: Obtener todas las rutas y filtrar en el frontend
        final response = await BaseApi.get<Map<String, dynamic>>(
          EndpointManager.rutas,
          queryParameters: {
            'per_page': '1000' // FIX: Obtener más rutas para filtrar
          },
        );

        // FIX: Manejar estructura de respuesta del backend Laravel
        if (response.data?['status'] == 'success') {
          final List<dynamic> rutasData = response.data?['data'] ?? [];
          final todasRutas = rutasData
              .map((json) =>
                  RutaOptimizada.fromJson(json as Map<String, dynamic>))
              .toList();

          // Filtrar rutas activas (sin fecha de completado)
          return todasRutas
              .where((ruta) => ruta.fechaCompletado == null)
              .toList();
        }
        return <RutaOptimizada>[];
      },
      operationName: 'Obteniendo rutas optimizadas activas',
      successMessage: 'Rutas activas obtenidas exitosamente',
    );
  }

  /// Re-optimiza una ruta existente
  static Future<Map<String, dynamic>> reOptimizarRuta({
    required String rutaId,
    required String inicioJornada,
    required String finJornada,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch<Map<String, dynamic>>(
          '${EndpointManager.rutas}/$rutaId/optimizar',
          data: {
            'inicio_jornada': inicioJornada,
            'fin_jornada': finJornada,
          },
        );

        return response.data ?? <String, dynamic>{};
      },
      operationName: 'Re-optimizando ruta: $rutaId',
      successMessage: 'Ruta re-optimizada exitosamente',
    );
  }

  /// Actualiza el orden personalizado de un pedido
  static Future<bool> actualizarOrdenPersonalizado({
    required String pedidoId,
    required int ordenPersonalizado,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        await BaseApi.put(
          '${EndpointManager.rutas}/pedidos/$pedidoId/orden',
          data: {
            'orden_personalizado': ordenPersonalizado,
          },
        );
        return true;
      },
      operationName: 'Actualizando orden personalizado del pedido: $pedidoId',
      successMessage: 'Orden personalizado actualizado exitosamente',
    );
  }

  /// Obtiene el estado de optimización de una ruta
  static Future<Map<String, dynamic>> getEstadoOptimizacion({
    required String rutaId,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          '${EndpointManager.rutas}/$rutaId/estado',
        );

        return response.data ?? <String, dynamic>{};
      },
      operationName: 'Obteniendo estado de optimización: $rutaId',
      successMessage: 'Estado de optimización obtenido exitosamente',
    );
  }

  /// Obtiene la ruta actual del repartidor autenticado
  /// Solo funciona para usuarios con rol repartidor
  static Future<Map<String, dynamic>?> getRutaActual({
    String? estado,
    String? orderBy,
    String? orderDirection,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final queryParams = <String, dynamic>{};

        // Solo agregar parámetros si se especifican explícitamente
        if (orderBy != null) {
          queryParams['order_by'] = orderBy;
        }
        if (orderDirection != null) {
          queryParams['order_direction'] = orderDirection;
        }
        if (estado != null) {
          queryParams['estado'] = estado;
        }

        final response = await BaseApi.get<Map<String, dynamic>>(
          '${EndpointManager.rutas}/current',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        if (response.data?['status'] == 'success') {
          return response.data?['data'] as Map<String, dynamic>?;
        }
        return null;
      },
      operationName: 'Obteniendo ruta actual del repartidor autenticado',
      successMessage: 'Ruta actual obtenida exitosamente',
    );
  }

  /// Obtiene estadísticas de rutas optimizadas
  static Future<Map<String, dynamic>> getRutasStats() {
    return ApiHelper.executeWithLogging(
      () async {
        // Por ahora, calculamos estadísticas básicas
        final rutas = await getAllRutasOptimizadas(perPage: 1000);

        return <String, dynamic>{
          'total_rutas': rutas.length,
          'rutas_activas': rutas.where((r) => r.fechaCompletado == null).length,
          'rutas_completadas':
              rutas.where((r) => r.fechaCompletado != null).length,
          'distancia_total_estimada': rutas
              .where((r) => r.distanciaTotalEstimada != null)
              .fold(0.0, (sum, r) => sum + (r.distanciaTotalEstimada ?? 0.0)),
          'tiempo_total_estimado': rutas
              .where((r) => r.tiempoTotalEstimado != null)
              .fold(0, (sum, r) => sum + (r.tiempoTotalEstimado ?? 0)),
          'fecha_ultima_actualizacion': DateTime.now().toIso8601String(),
        };
      },
      operationName: 'Obteniendo estadísticas de rutas optimizadas',
      successMessage: 'Estadísticas de rutas obtenidas exitosamente',
    );
  }
}

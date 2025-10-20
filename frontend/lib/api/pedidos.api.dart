import 'dart:io';

import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/utils/loggers.dart';

class PedidosApi {
  /// Obtiene todos los pedidos con paginación y filtros
  static Future<List<Pedido>> getAllPedidos({
    int? page = 1,
    int? perPage = 15,
    String? estado,
    List<String>? estados,
    String? orderBy = 'updated_at',
    String? orderDirection = 'desc',
  }) {
    final params = <String, dynamic>{
      'current_page': page,
      'per_page': perPage,
      'order_by': orderBy,
      'order_direction': orderDirection,
    };

    if (estado != null) {
      params['estado'] = estado;
    }
    if (estados != null && estados.isNotEmpty) {
      params['estados'] = estados.join(',');
    }

    return ApiHelper.getList<Pedido>(
      EndpointManager.pedidos,
      fromJson: Pedido.fromJson,
      queryParameters: params,
      operationName: 'Obteniendo todos los pedidos',
    );
  }

  /// Obtiene un pedido por ID
  static Future<Pedido?> getPedidoById(String id) {
    return ApiHelper.getSingle<Pedido>(
      EndpointManager.pedidoById(id),
      fromJson: Pedido.fromJson,
      operationName: 'Obteniendo pedido por ID: $id',
    );
  }

  /// Crea un nuevo pedido
  static Future<Pedido?> createPedido(Map<String, dynamic> pedidoData) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.post(
          EndpointManager.pedidos,
          data: pedidoData,
        );
        return ApiHelper.processSingleResponse(response.data, Pedido.fromJson);
      },
      operationName: 'Creando nuevo pedido',
    );
  }

  /// Actualiza un pedido existente
  static Future<Pedido?> updatePedido(
      String id, Map<String, dynamic> pedidoData) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch(
          EndpointManager.pedidoById(id),
          data: pedidoData,
        );
        return ApiHelper.processSingleResponse(response.data, Pedido.fromJson);
      },
      operationName: 'Actualizando pedido $id',
    );
  }

  /// Elimina un pedido
  static Future<bool> deletePedido(String id) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.delete(
          EndpointManager.pedidoById(id),
        );

        // Para DELETE, el backend devuelve 204 (No Content) o un objeto con data vacía
        // Verificamos si la respuesta es exitosa basándose en el status code
        if (response.statusCode == 204) {
          return true;
        }

        // Si hay data, verificar que sea un objeto válido
        if (response.data is Map<String, dynamic>) {
          return ApiHelper.isValidResponse(response.data);
        }

        // Si es un string o null, considerar como exitoso si el status code es 200-299
        return response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300;
      },
      operationName: 'Eliminando pedido $id',
    );
  }

  /// Sube un archivo CSV de pedidos
  static Future<bool> uploadPedidosCsv(String filePath, String farmaciaId) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.uploadFile(
          EndpointManager.pedidosCargarCsv,
          filePath: filePath,
          fieldName: 'pedidos_csv',
          extraData: {'farmacia_id': farmaciaId},
        );
        return ApiHelper.isValidResponse(response.data);
      },
      operationName: 'Subiendo archivo CSV de pedidos',
    );
  }

  /// Asigna un pedido a un repartidor
  static Future<Pedido?> asignarPedido(String pedidoId, String repartidorId) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch(
          EndpointManager.pedidoAsignar(pedidoId),
          data: {'repartidor_id': repartidorId},
        );
        return ApiHelper.processSingleResponse(response.data, Pedido.fromJson);
      },
      operationName: 'Asignando pedido $pedidoId a repartidor $repartidorId',
    );
  }

  /// Marca un pedido como recogido
  static Future<Pedido?> marcarPedidoRecogido(String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch(
          '${EndpointManager.pedidos}/$pedidoId/recoger',
        );
        return ApiHelper.processSingleResponse(response.data, Pedido.fromJson);
      },
      operationName: 'Marcando pedido $pedidoId como recogido',
    );
  }

  /// Marca un pedido como en ruta
  static Future<Pedido?> marcarPedidoEnRuta(String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch(
          '${EndpointManager.pedidos}/$pedidoId/en-ruta',
        );
        return ApiHelper.processSingleResponse(response.data, Pedido.fromJson);
      },
      operationName: 'Marcando pedido $pedidoId como en ruta',
    );
  }

  /// Marca un pedido como entregado
  static Future<Pedido?> marcarPedidoEntregado(
    String pedidoId, {
    required double latitud,
    required double longitud,
    String? firmaDigitalPath,
    String? fotoEntregaPath,
  }) async {
    try {
      final data = <String, dynamic>{
        'ubicacion': {
          'latitude': latitud,
          'longitude': longitud,
        },
      };

      // Si hay firma SVG, la enviamos como texto
      if (firmaDigitalPath != null) {
        data['firma_digital'] = firmaDigitalPath; // Enviar SVG como texto
        logInfo(
            '📝 Enviando firma SVG: ${firmaDigitalPath.substring(0, 50)}...');
      }

      // Preparar archivos para envío multipart
      final files = <Map<String, dynamic>>[];
      if (fotoEntregaPath != null) {
        files.add({
          'field': 'foto_entrega',
          'path': fotoEntregaPath,
        });
        logInfo('📸 Enviando foto de entrega: $fotoEntregaPath');
      }

      final response = await BaseApi.postMultipart(
        EndpointManager.pedidoEntregar(pedidoId),
        data: data,
        files: files,
      );

      logInfo('Respuesta del servidor: ${response.data['status']}');

      if (response.data['status'] == 'success') {
        final pedido = Pedido.fromJson(response.data['data']);
        logInfo(
            'Pedido actualizado - Firma: ${pedido.firmaDigitalUrl != null ? "Sí" : "No"}, Foto: ${pedido.fotoEntregaUrl != null ? "Sí" : "No"}');
        return pedido;
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Marca un pedido como fallido
  static Future<Pedido?> marcarPedidoFallido(
    String pedidoId, {
    required String motivoFallo,
    String? observacionesFallo,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final data = <String, dynamic>{
        'motivo_fallo': motivoFallo,
        'ubicacion': {
          'latitude': latitud,
          'longitude': longitud,
        },
      };

      if (observacionesFallo != null) {
        data['observaciones_fallo'] = observacionesFallo;
      }

      final response = await BaseApi.patch(
        '${EndpointManager.pedidos}/$pedidoId/fallo-entrega',
        data: data,
      );

      if (response.data['status'] == 'success') {
        return Pedido.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Marca un pedido como devuelto
  static Future<Pedido?> marcarPedidoDevuelto(String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.patch(
          '${EndpointManager.pedidos}/$pedidoId/devolver',
        );
        return ApiHelper.processSingleResponse(response.data, Pedido.fromJson);
      },
      operationName: 'Marcando pedido $pedidoId como devuelto',
    );
  }

  /// Obtiene los eventos de un pedido
  static Future<List<Map<String, dynamic>>> getEventosPedido(
      String pedidoId) async {
    try {
      final response = await BaseApi.get(
        EndpointManager.pedidoEventos(pedidoId),
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> eventosData = response.data['data'];
        return eventosData.map((json) => json as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene pedidos por estado
  static Future<List<Pedido>> getPedidosByEstado(String estado) {
    return ApiHelper.getList<Pedido>(
      EndpointManager.pedidos,
      fromJson: Pedido.fromJson,
      queryParameters: {'estado': estado},
      operationName: 'Obteniendo pedidos por estado: $estado',
    );
  }

  /// Obtiene pedidos por repartidor
  static Future<List<Pedido>> getPedidosByRepartidor(String repartidorId) {
    return ApiHelper.getList<Pedido>(
      EndpointManager.pedidos,
      fromJson: Pedido.fromJson,
      queryParameters: {'repartidor_id': repartidorId},
      operationName: 'Obteniendo pedidos por repartidor: $repartidorId',
    );
  }

  /// Obtiene pedidos por farmacia
  static Future<List<Pedido>> getPedidosByFarmacia(String farmaciaId) {
    return ApiHelper.getList<Pedido>(
      EndpointManager.pedidos,
      fromJson: Pedido.fromJson,
      queryParameters: {'farmacia_id': farmaciaId},
      operationName: 'Obteniendo pedidos por farmacia: $farmaciaId',
    );
  }

  /// Busca pedidos por texto
  static Future<List<Pedido>> searchPedidos(String query) {
    return ApiHelper.getList<Pedido>(
      EndpointManager.pedidos,
      fromJson: Pedido.fromJson,
      queryParameters: {'search': query},
      operationName: 'Buscando pedidos con query: $query',
    );
  }

  /// Ubicaciones de repartidor por pedido (listar)
  static Future<List<Map<String, dynamic>>> getUbicacionesRepartidor(
      String pedidoId) async {
    try {
      final response = await BaseApi.get(
        EndpointManager.ubicacionesRepartidor,
        queryParameters: {'pedido_id': pedidoId},
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Registrar ubicación del repartidor durante entrega del pedido
  static Future<bool> registrarUbicacionRepartidor({
    required String pedidoId,
    required String repartidorId,
    required double latitud,
    required double longitud,
    double? precisionMetros,
    double? velocidadMs,
    double? direccionGrados,
  }) async {
    try {
      final body = <String, dynamic>{
        'repartidor_id': repartidorId,
        'ubicacion': {
          'latitude': latitud,
          'longitude': longitud,
        },
      };

      if (precisionMetros != null) {
        body['precision_m'] = precisionMetros;
      }
      if (velocidadMs != null) {
        body['velocidad_ms'] = velocidadMs;
      }
      if (direccionGrados != null) {
        body['direccion'] = direccionGrados;
      }

      final response = await BaseApi.post(
        EndpointManager.ubicacionesRepartidor,
        data: body,
      );

      return response.data['status'] == 'success';
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene pedidos por código de barras
  static Future<Pedido?> getPedidoByCodigoBarra(String codigoBarra) async {
    try {
      final response = await BaseApi.get(
        EndpointManager.pedidoByCodigoBarra(codigoBarra),
      );

      if (response.data['status'] == 'success') {
        return Pedido.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene pedidos pendientes por farmacia
  static Future<List<Pedido>> getPedidosPendientesByFarmacia(
      String farmaciaId) async {
    try {
      final response = await BaseApi.get(
        EndpointManager.pedidos,
        queryParameters: {
          'farmacia_id': farmaciaId,
          'estado': 'PENDIENTE',
        },
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> pedidosData = response.data['data'];
        return pedidosData.map((json) => Pedido.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene pedidos por rango de fechas
  static Future<List<Pedido>> getPedidosByDateRange(
    DateTime fechaInicio,
    DateTime fechaFin, {
    String? farmaciaId,
    String? repartidorId,
  }) async {
    try {
      final params = <String, dynamic>{
        'fecha_inicio': fechaInicio.toIso8601String(),
        'fecha_fin': fechaFin.toIso8601String(),
      };

      if (farmaciaId != null) {
        params['farmacia_id'] = farmaciaId;
      }

      if (repartidorId != null) {
        params['repartidor_id'] = repartidorId;
      }

      final response = await BaseApi.get(
        EndpointManager.pedidos,
        queryParameters: params,
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> pedidosData = response.data['data'];
        return pedidosData.map((json) => Pedido.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene pedidos cercanos a una ubicación
  static Future<List<Pedido>> getPedidosCercanos(
    double latitud,
    double longitud, {
    double radioKm = 10.0,
    String? estado,
  }) async {
    try {
      final params = <String, dynamic>{
        'latitud': latitud,
        'longitud': longitud,
        'radio_km': radioKm,
      };

      if (estado != null) {
        params['estado'] = estado;
      }

      final response = await BaseApi.get(
        '${EndpointManager.pedidos}/cercanos',
        queryParameters: params,
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> pedidosData = response.data['data'];
        return pedidosData.map((json) => Pedido.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene pedidos con paginación avanzada
  static Future<Map<String, dynamic>> getPedidosPaginated({
    int page = 1,
    int perPage = 15,
    String? estado,
    List<String>? estados,
    String? farmaciaId,
    String? repartidorId,
    String? search,
    String? orderBy = 'updated_at',
    String? orderDirection = 'desc',
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      final params = <String, dynamic>{
        'current_page': page,
        'per_page': perPage,
        'order_by': orderBy,
        'order_direction': orderDirection,
      };

      if (estado != null) {
        params['estado'] = estado;
      }
      if (estados != null && estados.isNotEmpty) {
        params['estados'] = estados.join(',');
      }
      if (farmaciaId != null) {
        params['farmacia_id'] = farmaciaId;
      }
      if (repartidorId != null) {
        params['repartidor_id'] = repartidorId;
      }
      if (search != null) {
        params['search'] = search;
      }
      if (fechaDesde != null) {
        params['fecha_desde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        params['fecha_hasta'] = fechaHasta.toIso8601String();
      }

      final response = await BaseApi.get(
        EndpointManager.pedidos,
        queryParameters: params,
      );

      if (response.data['status'] == 'success') {
        final List<dynamic> pedidosData = response.data['data'];
        final pedidos =
            pedidosData.map((json) => Pedido.fromJson(json)).toList();

        return {
          'pedidos': pedidos,
          'pagination': response.data['pagination'] ?? {},
          'total': response.data['pagination']?['total'] ?? pedidos.length,
          'current_page': response.data['pagination']?['current_page'] ?? page,
          'per_page': response.data['pagination']?['per_page'] ?? perPage,
        };
      }

      return {
        'pedidos': <Pedido>[],
        'pagination': {},
        'total': 0,
        'current_page': page,
        'per_page': perPage,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Carga pedidos desde un archivo CSV
  static Future<bool> cargarPedidosCsv(String filePath) async {
    try {
      final response = await BaseApi.uploadFile(
        EndpointManager.pedidosCargarCsv,
        filePath: filePath,
        fieldName: 'pedidos_csv',
      );

      return response.data['status'] == 'success';
    } catch (e) {
      rethrow;
    }
  }

  /// Sube un archivo CSV de pedidos al backend
  static Future<bool> uploadCsv(File csvFile, String farmaciaId) async {
    try {
      final response = await BaseApi.uploadFile(
        EndpointManager.pedidosCargarCsv,
        filePath: csvFile.path,
        fieldName: 'pedidos_csv',
        extraData: {'farmacia_id': farmaciaId},
      );

      return response.data['status'] == 'success';
    } catch (e) {
      rethrow;
    }
  }

  /// Sube un CSV desde bytes (Web/bytes en memoria)
  static Future<bool> uploadCsvBytes({
    required List<int> bytes,
    required String filename,
    required String farmaciaId,
  }) async {
    try {
      final response = await BaseApi.uploadBytes(
        EndpointManager.pedidosCargarCsv,
        bytes: bytes,
        filename: filename,
        fieldName: 'pedidos_csv',
        extraData: {'farmacia_id': farmaciaId},
      );

      return response.data['status'] == 'success';
    } catch (e) {
      rethrow;
    }
  }

  /// Retira un repartidor de un pedido
  static Future<Pedido?> retirarRepartidor(String pedidoId) async {
    try {
      final response = await BaseApi.patch(
        '${EndpointManager.pedidos}/$pedidoId/retirar-repartidor',
      );

      if (response.data['status'] == 'success') {
        return Pedido.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancela un pedido
  static Future<Pedido?> cancelarPedido(String pedidoId) async {
    try {
      final response = await BaseApi.patch(
        EndpointManager.pedidoCancelar(pedidoId),
      );

      if (response.data['status'] == 'success') {
        return Pedido.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza la ruta de un pedido
  static Future<Pedido?> actualizarRutaPedido(
    String pedidoId, {
    required List<Map<String, double>> waypoints,
    String? instrucciones,
  }) async {
    try {
      final data = <String, dynamic>{
        'waypoints': waypoints,
      };

      if (instrucciones != null) {
        data['instrucciones'] = instrucciones;
      }

      final response = await BaseApi.patch(
        '${EndpointManager.pedidos}/$pedidoId/ruta',
        data: data,
      );

      if (response.data['status'] == 'success') {
        return Pedido.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene URL firmada para descargar plantilla CSV
  static Future<Map<String, dynamic>?> getSignedTemplateUrl({
    required String lang,
    required String templateKey,
  }) async {
    try {
      final response = await BaseApi.get(
        '/downloads/templates/csv/$lang/$templateKey/signed-url',
      );

      if (response.data['status'] == 'success') {
        return {
          'signed_url': response.data['data']['signed_url'],
          'expires_at': response.data['data']['expires_at'],
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Descarga plantilla CSV directamente
  static Future<String?> downloadTemplate({
    required String lang,
    required String templateKey,
  }) async {
    try {
      final response = await BaseApi.get(
        '/downloads/templates/csv/$lang/$templateKey',
      );

      // El backend retorna el archivo directamente
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Genera PDF de etiquetas de envío para pedidos seleccionados
  static Future<Map<String, dynamic>?> generarEtiquetasPdf({
    required List<String> pedidosIds,
  }) async {
    try {
      final response = await BaseApi.post(
        EndpointManager.pedidosGenerarEtiquetasPdf,
        data: {'pedidos': pedidosIds},
      );

      if (response.data['status'] == 'success') {
        // El endpoint asíncrono devuelve un ReportePdf en proceso
        final reportePdf = response.data['data'] as Map<String, dynamic>;

        return {
          'reporte_id': reportePdf['id'],
          'filename': reportePdf['nombre'] ?? 'etiquetas_medrush.pdf',
          'status': reportePdf['status'],
          'pedidos_count': pedidosIds.length,
          'created_at': reportePdf['created_at'],
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Consulta el estado de un reporte PDF
  static Future<Map<String, dynamic>?> consultarEstadoReportePdf({
    required String reporteId,
  }) async {
    try {
      final response = await BaseApi.get(
        EndpointManager.reportePdfById(reporteId),
      );

      if (response.data['status'] == 'success') {
        final reportePdf = response.data['data'] as Map<String, dynamic>;

        return {
          'reporte_id': reportePdf['id'],
          'filename': reportePdf['nombre'],
          'status': reportePdf['status'],
          'file_url': reportePdf['file_url'],
          'file_size': reportePdf['file_size'],
          'pedidos_count': (reportePdf['pedidos'] as List?)?.length ?? 0,
          'created_at': reportePdf['created_at'],
          'updated_at': reportePdf['updated_at'],
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene la ruta actual del repartidor autenticado
  /// Solo funciona para usuarios con rol repartidor
  static Future<Map<String, dynamic>?> getRutaActual({
    String? estado,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
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
        '/rutas/current',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data?['status'] == 'success') {
        return response.data?['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina archivos multimedia de pedidos antiguos
  static Future<bool> eliminarPedidosAntiguos(int semanas) async {
    try {
      logInfo(
          'Iniciando limpieza de archivos multimedia de pedidos antiguos: $semanas semanas');

      final response = await BaseApi.delete(
        '/pedidos/antiguos',
        queryParameters: {'semanas': semanas},
      );

      // El backend devuelve 202 (Accepted) para operaciones asíncronas
      if (response.statusCode == 202) {
        logInfo(
            'Limpieza de archivos multimedia de pedidos antiguos iniciada exitosamente');
        return true;
      }

      logWarning('Respuesta inesperada del servidor: ${response.statusCode}');
      return false;
    } catch (e) {
      logError(
          'Error al iniciar la limpieza de archivos multimedia de pedidos antiguos',
          e);
      rethrow;
    }
  }
}

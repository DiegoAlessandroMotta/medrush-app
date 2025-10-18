import 'dart:io';

import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/pedidos.api.dart';
import 'package:medrush/models/pagination.model.dart' as pagination;
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/utils/loggers.dart';

/// Repositorio para la gestión de pedidos
/// Proporciona una capa de abstracción entre los providers y la API de pedidos
class PedidoRepository extends BaseRepository {
  // FIX: Sistema de caché eliminado completamente

  PedidoRepository();

  /// Obtiene un pedido por su ID
  Future<RepositoryResult<Pedido?>> obtenerPorId(String id) {
    return execute(() async {
      validateId(id, 'ID de pedido');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedido = await PedidosApi.getPedidoById(id.toString());
      return pedido;
    }, errorMessage: 'Error al obtener pedido por ID');
  }

  /// Obtiene pedidos paginados del backend
  Future<RepositoryResult<pagination.PaginatedResponse<Pedido>>>
      obtenerPaginados({
    int page = 1,
    int perPage = 20,
    EstadoPedido? estado,
    List<EstadoPedido>? estados, // FIX: Agregar soporte para múltiples estados
    String? repartidorId,
    String? farmaciaId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? search, // FIX: Agregar parámetro de búsqueda
    String? orderBy =
        'updated_at', // FIX: Usar updated_at por defecto para consistencia
    String? orderDirection =
        'desc', // FIX: Usar desc por defecto para consistencia
  }) {
    return execute(() async {
      logInfo(
          'Obteniendo pedidos paginados: página $page, $perPage por página');

      // Crear filtros
      final filters = <String, dynamic>{};
      if (estado != null) {
        // Convertir estado único a lista para usar filtro 'estados'
        filters['estados'] = _convertEstadoToBackend(estado);
      } else if (estados != null && estados.isNotEmpty) {
        // FIX: Usar filtro múltiple de estados como string separado por comas
        filters['estados'] = estados.map(_convertEstadoToBackend).join(',');
      }
      if (repartidorId != null) {
        filters['repartidor_id'] = repartidorId;
      }
      if (farmaciaId != null) {
        filters['farmacia_id'] = farmaciaId;
      }
      if (fechaDesde != null) {
        filters['fecha_desde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        filters['fecha_hasta'] = fechaHasta.toIso8601String();
      }
      if (search != null && search.isNotEmpty) {
        filters['search'] = search; // FIX: Agregar filtro de búsqueda
      }

      // FIX: Cache deshabilitado - obtener directamente de la API
      final response = await BaseApi.getPaginated<Pedido>(
        '/pedidos',
        fromJson: Pedido.fromJson,
        page: page,
        perPage: perPage,
        filters: filters,
        orderBy:
            orderBy, // FIX: Solo pasar si se especifica - el backend maneja el ordenamiento por defecto
        orderDirection:
            orderDirection, // FIX: Solo pasar si se especifica - el backend maneja el ordenamiento por defecto
      );

      return response;
    }, errorMessage: 'Error al obtener pedidos paginados');
  }

  /// Crea un nuevo pedido
  Future<RepositoryResult<Pedido?>> crearPedido(
      Map<String, dynamic> pedidoData) {
    return execute(() async {
      validateNotNull(pedidoData, 'Datos del pedido');

      logInfo('Creando nuevo pedido');

      // FIX: Cache deshabilitado - crear directamente en la API
      final pedido = await PedidosApi.createPedido(pedidoData);

      if (pedido != null) {
        logInfo('Pedido creado exitosamente: ${pedido.id}');
      }

      return pedido;
    }, errorMessage: 'Error al crear pedido');
  }

  /// Actualiza un pedido existente
  Future<RepositoryResult<Pedido?>> actualizarPedido(
    String id,
    Map<String, dynamic> pedidoData,
  ) {
    return execute(() async {
      validateId(id, 'ID de pedido');
      validateNotNull(pedidoData, 'Datos del pedido');

      logInfo('Actualizando pedido: $id');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.updatePedido(id, pedidoData);

      if (pedido != null) {
        logInfo('Pedido actualizado exitosamente: ${pedido.id}');
      }

      return pedido;
    }, errorMessage: 'Error al actualizar pedido');
  }

  /// Elimina un pedido
  Future<RepositoryResult<bool>> eliminarPedido(String id) {
    return execute(() async {
      validateId(id, 'ID de pedido');

      logInfo('Eliminando pedido: $id');

      // FIX: Cache deshabilitado - eliminar directamente de la API
      final resultado = await PedidosApi.deletePedido(id);

      if (resultado) {
        logInfo('Pedido eliminado exitosamente: $id');
      }

      return resultado;
    }, errorMessage: 'Error al eliminar pedido');
  }

  /// Asigna un pedido a un repartidor
  Future<RepositoryResult<Pedido?>> asignarPedido(
    String pedidoId,
    String repartidorId,
  ) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');
      validateId(repartidorId, 'ID de repartidor');

      logInfo('Asignando pedido $pedidoId al repartidor $repartidorId');

      // FIX: Cache deshabilitado - asignar directamente en la API
      final pedido = await PedidosApi.asignarPedido(pedidoId, repartidorId);

      if (pedido != null) {
        logInfo('Pedido asignado exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al asignar pedido');
  }

  /// Marca un pedido como recogido
  Future<RepositoryResult<Pedido?>> marcarPedidoRecogido(String pedidoId) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');

      logInfo('Marcando pedido como recogido: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.marcarPedidoRecogido(pedidoId);

      if (pedido != null) {
        logInfo('Pedido marcado como recogido exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al marcar pedido como recogido');
  }

  /// Marca un pedido como en ruta
  Future<RepositoryResult<Pedido?>> marcarPedidoEnRuta(String pedidoId) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');

      logInfo('Marcando pedido como en ruta: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.marcarPedidoEnRuta(pedidoId);

      if (pedido != null) {
        logInfo('Pedido marcado como en ruta exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al marcar pedido como en ruta');
  }

  /// Marca un pedido como entregado
  Future<RepositoryResult<Pedido?>> marcarPedidoEntregado(
    String pedidoId, {
    required double latitud,
    required double longitud,
    String? firmaDigitalPath,
    String? fotoEntregaPath,
  }) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');
      validateNotNull(latitud, 'Latitud');
      validateNotNull(longitud, 'Longitud');

      logInfo('Marcando pedido como entregado: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.marcarPedidoEntregado(
        pedidoId,
        latitud: latitud,
        longitud: longitud,
        firmaDigitalPath: firmaDigitalPath,
        fotoEntregaPath: fotoEntregaPath,
      );

      if (pedido != null) {
        logInfo('Pedido marcado como entregado exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al marcar pedido como entregado');
  }

  /// Marca un pedido como fallido
  Future<RepositoryResult<Pedido?>> marcarPedidoFallido(
    String pedidoId, {
    required String motivoFallo,
    String? observacionesFallo,
    required double latitud,
    required double longitud,
  }) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');
      validateNotEmpty(motivoFallo, 'Motivo del fallo');
      validateNotNull(latitud, 'Latitud');
      validateNotNull(longitud, 'Longitud');

      logInfo('Marcando pedido como fallido: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.marcarPedidoFallido(
        pedidoId,
        motivoFallo: motivoFallo,
        observacionesFallo: observacionesFallo,
        latitud: latitud,
        longitud: longitud,
      );

      if (pedido != null) {
        logInfo('Pedido marcado como fallido exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al marcar pedido como fallido');
  }

  /// Marca un pedido como devuelto
  Future<RepositoryResult<Pedido?>> marcarPedidoDevuelto(String pedidoId) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');

      logInfo('Marcando pedido como devuelto: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.marcarPedidoDevuelto(pedidoId);

      if (pedido != null) {
        logInfo('Pedido marcado como devuelto exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al marcar pedido como devuelto');
  }

  /// Obtiene los eventos de un pedido
  Future<RepositoryResult<List<Map<String, dynamic>>>> obtenerEventosPedido(
    String pedidoId,
  ) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');

      logInfo('Obteniendo eventos del pedido: $pedidoId');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final eventos = await PedidosApi.getEventosPedido(pedidoId);

      logInfo('${eventos.length} eventos obtenidos del pedido');
      return eventos;
    }, errorMessage: 'Error al obtener eventos del pedido');
  }

  /// Obtiene pedidos por estado
  Future<RepositoryResult<List<Pedido>>> obtenerPedidosPorEstado(
    EstadoPedido estado,
  ) {
    return execute(() async {
      validateNotNull(estado, 'Estado del pedido');

      logInfo('Obteniendo pedidos con estado: ${estado.name}');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedidos = await PedidosApi.getPedidosByEstado(estado.name);

      logInfo('${pedidos.length} pedidos con estado ${estado.name} obtenidos');
      return pedidos;
    }, errorMessage: 'Error al obtener pedidos por estado');
  }

  /// Obtiene pedidos por repartidor
  Future<RepositoryResult<List<Pedido>>> obtenerPedidosPorRepartidor(
    String repartidorId,
  ) {
    return execute(() async {
      validateId(repartidorId, 'ID de repartidor');

      logInfo('Obteniendo pedidos del repartidor: $repartidorId');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedidos = await PedidosApi.getPedidosByRepartidor(repartidorId);

      logInfo('${pedidos.length} pedidos del repartidor obtenidos');
      return pedidos;
    }, errorMessage: 'Error al obtener pedidos por repartidor');
  }

  /// Obtiene pedidos por farmacia
  Future<RepositoryResult<List<Pedido>>> obtenerPedidosPorFarmacia(
    String farmaciaId,
  ) {
    return execute(() async {
      validateId(farmaciaId, 'ID de farmacia');

      logInfo('Obteniendo pedidos de la farmacia: $farmaciaId');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedidos = await PedidosApi.getPedidosByFarmacia(farmaciaId);

      logInfo('${pedidos.length} pedidos de la farmacia obtenidos');
      return pedidos;
    }, errorMessage: 'Error al obtener pedidos por farmacia');
  }

  /// Busca pedidos por texto
  Future<RepositoryResult<List<Pedido>>> buscarPedidos(String query) {
    return execute(() async {
      validateNotEmpty(query, 'Consulta de búsqueda');

      logInfo('Buscando pedidos con: $query');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedidos = await PedidosApi.searchPedidos(query);

      logInfo('${pedidos.length} pedidos encontrados');
      return pedidos;
    }, errorMessage: 'Error al buscar pedidos');
  }

  /// Obtiene estadísticas de pedidos (calculadas localmente)
  Future<RepositoryResult<Map<String, dynamic>>> obtenerEstadisticasPedidos() {
    return execute(() async {
      logInfo('Obteniendo estadísticas de pedidos (calculadas localmente)');

      // Como no existe endpoint específico, calcular estadísticas localmente
      final todosPedidos = await PedidosApi.getAllPedidos();

      final total = todosPedidos.length;
      final pendientes =
          todosPedidos.where((p) => p.estado == EstadoPedido.pendiente).length;
      final asignados =
          todosPedidos.where((p) => p.estado == EstadoPedido.asignado).length;
      final entregados =
          todosPedidos.where((p) => p.estado == EstadoPedido.entregado).length;
      final fallidos =
          todosPedidos.where((p) => p.estado == EstadoPedido.fallido).length;
      final cancelados =
          todosPedidos.where((p) => p.estado == EstadoPedido.cancelado).length;

      final estadisticas = {
        'total': total,
        'pendientes': pendientes,
        'asignados': asignados,
        'entregados': entregados,
        'fallidos': fallidos,
        'cancelados': cancelados,
        'porcentaje_entregados':
            total > 0 ? (entregados / total * 100).round() : 0,
        'porcentaje_fallidos': total > 0 ? (fallidos / total * 100).round() : 0,
      };

      logInfo('Estadísticas de pedidos calculadas localmente');
      return estadisticas;
    }, errorMessage: 'Error al obtener estadísticas de pedidos');
  }

  /// Obtiene pedidos por rango de fechas
  Future<RepositoryResult<List<Pedido>>> obtenerPedidosPorRangoFechas(
    DateTime fechaInicio,
    DateTime fechaFin, {
    String? farmaciaId,
    String? repartidorId,
  }) {
    return execute(() async {
      validateNotNull(fechaInicio, 'Fecha de inicio');
      validateNotNull(fechaFin, 'Fecha de fin');

      logInfo(
          'Obteniendo pedidos del ${fechaInicio.toIso8601String()} al ${fechaFin.toIso8601String()}');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedidos = await PedidosApi.getPedidosByDateRange(
        fechaInicio,
        fechaFin,
        farmaciaId: farmaciaId,
        repartidorId: repartidorId,
      );

      logInfo('${pedidos.length} pedidos obtenidos en el rango de fechas');
      return pedidos;
    }, errorMessage: 'Error al obtener pedidos por rango de fechas');
  }

  /// Obtiene pedidos cercanos a una ubicación
  Future<RepositoryResult<List<Pedido>>> obtenerPedidosCercanos(
    double latitud,
    double longitud, {
    double radioKm = 10.0,
    String? estado,
  }) {
    return execute(() async {
      validateNotNull(latitud, 'Latitud');
      validateNotNull(longitud, 'Longitud');

      logInfo(
          'Obteniendo pedidos cercanos a ($latitud, $longitud) en un radio de ${radioKm}km');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedidos = await PedidosApi.getPedidosCercanos(
        latitud,
        longitud,
        radioKm: radioKm,
        estado: estado,
      );

      logInfo('${pedidos.length} pedidos cercanos obtenidos');
      return pedidos;
    }, errorMessage: 'Error al obtener pedidos cercanos');
  }

  /// Obtiene pedidos con paginación avanzada
  Future<RepositoryResult<Map<String, dynamic>>> obtenerPedidosPaginados({
    int page = 1,
    int perPage = 15,
    String? estado,
    String? farmaciaId,
    String? repartidorId,
    String? search,
    String? orderBy = 'updated_at',
    String? orderDirection = 'desc',
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) {
    return execute(() async {
      logInfo(
          'Obteniendo pedidos paginados: página $page, $perPage por página');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final response = await PedidosApi.getPedidosPaginated(
        page: page,
        perPage: perPage,
        estado: estado,
        farmaciaId: farmaciaId,
        repartidorId: repartidorId,
        search: search,
        orderBy: orderBy,
        orderDirection: orderDirection,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      return response;
    }, errorMessage: 'Error al obtener pedidos paginados');
  }

  /// Obtiene un pedido por código de barras
  Future<RepositoryResult<Pedido?>> obtenerPedidoPorCodigoBarra(
    String codigoBarra,
  ) {
    return execute(() async {
      validateNotEmpty(codigoBarra, 'Código de barras');

      logInfo('Obteniendo pedido por código de barras: $codigoBarra');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final pedido = await PedidosApi.getPedidoByCodigoBarra(codigoBarra);

      if (pedido != null) {
        logInfo('Pedido encontrado por código de barras: ${pedido.id}');
      } else {
        logInfo('Pedido no encontrado con código de barras: $codigoBarra');
      }

      return pedido;
    }, errorMessage: 'Error al obtener pedido por código de barras');
  }

  /// Carga pedidos desde un archivo CSV
  Future<RepositoryResult<bool>> cargarPedidosCsv(String filePath) {
    return execute(() async {
      validateNotEmpty(filePath, 'Ruta del archivo CSV');

      logInfo('Cargando pedidos desde CSV: $filePath');

      // FIX: Cache deshabilitado - cargar directamente en la API
      final resultado = await PedidosApi.cargarPedidosCsv(filePath);

      if (resultado) {
        logInfo('Pedidos cargados desde CSV exitosamente');
      }

      return resultado;
    }, errorMessage: 'Error al cargar pedidos desde CSV');
  }

  /// Sube un archivo CSV de pedidos al backend
  Future<RepositoryResult<bool>> uploadCsv(File csvFile, String farmaciaId) {
    return execute(() async {
      validateNotNull(csvFile, 'Archivo CSV');
      validateNotEmpty(farmaciaId, 'ID de farmacia');

      logInfo('Subiendo archivo CSV de pedidos para farmacia: $farmaciaId');

      // FIX: Cache deshabilitado - subir directamente a la API
      final resultado = await PedidosApi.uploadCsv(csvFile, farmaciaId);

      if (resultado) {
        logInfo('Archivo CSV subido exitosamente');
      }

      return resultado;
    }, errorMessage: 'Error al subir archivo CSV');
  }

  /// Sube un CSV desde bytes (Web/bytes en memoria)
  Future<RepositoryResult<bool>> uploadCsvBytes({
    required List<int> bytes,
    required String filename,
    required String farmaciaId,
  }) {
    return execute(() async {
      validateNotNull(bytes, 'Bytes de CSV');
      validateNotEmpty(filename, 'Nombre de archivo CSV');
      validateNotEmpty(farmaciaId, 'ID de farmacia');

      logInfo('Subiendo CSV (bytes) para farmacia: $farmaciaId');

      final resultado = await PedidosApi.uploadCsvBytes(
        bytes: bytes,
        filename: filename,
        farmaciaId: farmaciaId,
      );

      if (resultado) {
        logInfo('Archivo CSV (bytes) subido exitosamente');
      }

      return resultado;
    }, errorMessage: 'Error al subir archivo CSV (bytes)');
  }

  /// Retira un repartidor de un pedido
  Future<RepositoryResult<Pedido?>> retirarRepartidor(String pedidoId) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');

      logInfo('Retirando repartidor del pedido: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.retirarRepartidor(pedidoId);

      if (pedido != null) {
        logInfo('Repartidor retirado del pedido exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al retirar repartidor del pedido');
  }

  /// Cancela un pedido
  Future<RepositoryResult<Pedido?>> cancelarPedido(String pedidoId) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');

      logInfo('Cancelando pedido: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.cancelarPedido(pedidoId);

      if (pedido != null) {
        logInfo('Pedido cancelado exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al cancelar pedido');
  }

  /// Actualiza la ruta de un pedido
  Future<RepositoryResult<Pedido?>> actualizarRutaPedido(
    String pedidoId, {
    required List<Map<String, double>> waypoints,
    String? instrucciones,
  }) {
    return execute(() async {
      validateId(pedidoId, 'ID de pedido');
      validateNotNull(waypoints, 'Waypoints de la ruta');

      logInfo('Actualizando ruta del pedido: $pedidoId');

      // FIX: Cache deshabilitado - actualizar directamente en la API
      final pedido = await PedidosApi.actualizarRutaPedido(
        pedidoId,
        waypoints: waypoints,
        instrucciones: instrucciones,
      );

      if (pedido != null) {
        logInfo('Ruta del pedido actualizada exitosamente');
      }

      return pedido;
    }, errorMessage: 'Error al actualizar ruta del pedido');
  }

  /// Obtiene URL firmada para descargar plantilla CSV
  Future<RepositoryResult<Map<String, dynamic>?>> obtenerUrlPlantillaCsv({
    required String lang,
    required String templateKey,
  }) {
    return execute(() async {
      validateNotEmpty(lang, 'Idioma');
      validateNotEmpty(templateKey, 'Clave de plantilla');

      logInfo('Obteniendo URL firmada para plantilla CSV: $lang/$templateKey');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final urlData = await PedidosApi.getSignedTemplateUrl(
        lang: lang,
        templateKey: templateKey,
      );

      if (urlData != null) {
        logInfo('URL firmada obtenida exitosamente');
      }

      return urlData;
    }, errorMessage: 'Error al obtener URL de plantilla CSV');
  }

  /// Descarga plantilla CSV directamente
  Future<RepositoryResult<String?>> descargarPlantillaCsv({
    required String lang,
    required String templateKey,
  }) {
    return execute(() async {
      validateNotEmpty(lang, 'Idioma');
      validateNotEmpty(templateKey, 'Clave de plantilla');

      logInfo('Descargando plantilla CSV: $lang/$templateKey');

      // FIX: Cache deshabilitado - descargar directamente de la API
      final templateData = await PedidosApi.downloadTemplate(
        lang: lang,
        templateKey: templateKey,
      );

      if (templateData != null) {
        logInfo('Plantilla CSV descargada exitosamente');
      }

      return templateData;
    }, errorMessage: 'Error al descargar plantilla CSV');
  }

  // FIX: Métodos de caché eliminados completamente

  /// Genera PDF de etiquetas de envío para pedidos seleccionados
  Future<RepositoryResult<Map<String, dynamic>?>> generarEtiquetasPdf({
    required List<String> pedidosIds,
  }) {
    return execute(() async {
      validateNotNull(pedidosIds, 'IDs de pedidos');
      validateNotEmpty(pedidosIds.length.toString(), 'Lista de pedidos');

      logInfo('Generando PDF de etiquetas para ${pedidosIds.length} pedidos');

      // Iniciar proceso de generación
      final reporteData = await PedidosApi.generarEtiquetasPdf(
        pedidosIds: pedidosIds,
      );

      if (reporteData != null) {
        final reporteId = reporteData['reporte_id'] as String;
        logInfo('PDF de etiquetas iniciado - Reporte ID: $reporteId');

        // Hacer polling hasta que esté listo
        return _esperarReporteListo(reporteId);
      } else {
        logInfo('No se pudo iniciar la generación del PDF de etiquetas');
        return null;
      }
    }, errorMessage: 'Error al generar PDF de etiquetas');
  }

  /// Espera a que el reporte PDF esté listo mediante polling
  Future<Map<String, dynamic>?> _esperarReporteListo(String reporteId) async {
    const maxIntentos = 30; // 30 intentos = ~1 minuto
    const intervalo = Duration(seconds: 2);

    for (int intento = 1; intento <= maxIntentos; intento++) {
      await Future.delayed(intervalo);

      final estadoData = await PedidosApi.consultarEstadoReportePdf(
        reporteId: reporteId,
      );

      if (estadoData != null) {
        final status = estadoData['status'] as String;

        if (status == 'creado') {
          logInfo('PDF de etiquetas completado: ${estadoData['filename']}');
          return estadoData;
        } else if (status == 'fallido') {
          throw Exception('Error en la generación del PDF');
        }

        // Continuar polling si está en proceso
        logInfo('PDF en proceso... (intento $intento/$maxIntentos)');
      }
    }

    throw Exception('Timeout: La generación del PDF tardó demasiado');
  }

  /// Obtiene la ruta actual del repartidor autenticado
  /// Solo funciona para usuarios con rol repartidor
  Future<RepositoryResult<Map<String, dynamic>?>> obtenerRutaActual({
    String? estado,
    String? orderBy,
    String? orderDirection,
  }) {
    return execute(() async {
      logInfo('Obteniendo ruta actual del repartidor autenticado');

      // FIX: Cache deshabilitado - obtener directamente de la API
      final rutaActual = await PedidosApi.getRutaActual(
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

  /// Convierte el enum EstadoPedido al formato esperado por el backend
  String _convertEstadoToBackend(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'pendiente';
      case EstadoPedido.asignado:
        return 'asignado';
      case EstadoPedido.recogido:
        return 'recogido';
      case EstadoPedido.enRuta:
        return 'en_ruta'; // FIX: Backend espera 'en_ruta' con guión bajo
      case EstadoPedido.entregado:
        return 'entregado';
      case EstadoPedido.fallido:
        return 'fallido';
      case EstadoPedido.cancelado:
        return 'cancelado';
    }
  }
}

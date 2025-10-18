import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';

/// Servicio para decodificación de polylines, manejo de colores y caché
class PolylineDecodingService {
  // Cache de polylines para evitar llamadas innecesarias a Google Directions API
  static final Map<String, List<LatLng>> _polylineCache = {};
  static final Map<String, DateTime> _polylineCacheTime = {};
  static const Duration _polylineCacheExpiry =
      Duration(minutes: 10); // Cache válido por 10 minutos
  /// Decodifica polyline manualmente para Directions API
  /// Directions API solo soporta polyline5 (1e5)
  static List<LatLng> decodePolylineManual(String encoded) {
    if (encoded.isEmpty) {
      return [];
    }

    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    // Directions API siempre usa polyline5 (1e5)
    const double divisor = 100000.0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      // Decodificar latitud
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      // Decodificar longitud
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / divisor, lng / divisor));
    }

    return points;
  }

  /// Decodifica polyline desde Directions API
  static List<LatLng> decodePolylineFromResponse(Map<String, dynamic> route) {
    try {
      // Directions API siempre devuelve overview_polyline.points
      if (route.containsKey('overview_polyline')) {
        final overviewPolyline =
            route['overview_polyline'] as Map<String, dynamic>;

        if (overviewPolyline.containsKey('points')) {
          final encoded = overviewPolyline['points'] as String;
          return decodePolylineManual(encoded);
        }
      }

      logWarning('⚠️ No se encontró overview_polyline.points en la respuesta');
      return [];
    } catch (e) {
      logError('❌ Error al decodificar polyline', e);
      return [];
    }
  }

  /// Crea polyline para ruta del servidor
  static Polyline createServerPolyline(String polylineId, List<LatLng> points) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: const Color(0xFF2196F3)
          .withValues(alpha: 0.8), // Azul para ruta del servidor
      width: 6,
    );
  }

  /// Crea polyline para ruta optimizada (Google Directions API)
  static Polyline createOptimizedPolyline(
      String polylineId, List<LatLng> points) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: const Color(0xFF2196F3)
          .withValues(alpha: 0.8), // Azul para ruta principal
      width: 6,
    );
  }

  /// Crea polyline para ruta de recogida
  static Polyline createPickupPolyline(String polylineId, List<LatLng> points) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: const Color(0xFF9C27B0)
          .withValues(alpha: 0.8), // Morado para recogida
      width: 6,
    );
  }

  /// Crea polyline para ruta de recogida simple
  static Polyline createSimplePickupPolyline(
      String polylineId, List<LatLng> points) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: const Color(0xFF9C27B0)
          .withValues(alpha: 0.8), // Morado para recogida
      width: 6,
    );
  }

  /// Valida si un polyline es válido
  static bool isValidPolyline(List<LatLng> points) {
    return points.isNotEmpty && points.length >= 2;
  }

  /// Obtiene el color de polyline según el tipo
  static Color getPolylineColor(String type) {
    switch (type.toLowerCase()) {
      case 'server':
        return const Color(0xFF2196F3); // Azul para servidor
      case 'optimized':
        return const Color(0xFF2196F3); // Azul para optimizada
      case 'pickup':
        return const Color(0xFF9C27B0); // Morado para recogida
      default:
        return const Color(0xFF2196F3); // Azul por defecto
    }
  }

  /// Obtiene el ancho de polyline según el tipo
  static int getPolylineWidth(String type) {
    switch (type.toLowerCase()) {
      case 'server':
      case 'optimized':
      case 'pickup':
        return 6;
      default:
        return 4;
    }
  }

  /// Crea polyline con configuración personalizada
  static Polyline createCustomPolyline({
    required String polylineId,
    required List<LatLng> points,
    required String type,
    int? customWidth,
    double? customAlpha,
  }) {
    final color = getPolylineColor(type);
    final width = customWidth ?? getPolylineWidth(type);
    final alpha = customAlpha ?? 0.8;

    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color.withValues(alpha: alpha),
      width: width,
    );
  }

  /// Logs de debug para polylines
  static void logPolylineInfo(
      String polylineId, List<LatLng> points, String type) {
    logInfo('🔍 Polyline $polylineId: $type - ${points.length} puntos');
  }

  /// Logs de debug para múltiples polylines
  static void logMultiplePolylines(List<Polyline> polylines) {
    logInfo('✅ ${polylines.length} polylines creadas');
    for (int i = 0; i < polylines.length; i++) {
      final polyline = polylines.elementAt(i);
      logInfo(
          '🔍 Polyline $i: ${polyline.polylineId.value} - ${polyline.points.length} puntos - color: ${polyline.color} - width: ${polyline.width.toInt()}');
    }
  }

  // ===== SISTEMA DE CACHÉ =====

  /// Genera una clave única para el cache de polylines basada en los waypoints
  static String generatePolylineCacheKey(List<LatLng> waypoints) {
    final waypointStrings = waypoints
        .map((wp) => StatusHelpers.formatearCoordenadasAltaPrecision(
            wp.latitude, wp.longitude))
        .join('|');
    return 'polyline_${waypointStrings.hashCode}';
  }

  /// Verifica si el cache de polyline es válido
  static bool isPolylineCacheValid(String cacheKey) {
    if (!_polylineCache.containsKey(cacheKey) ||
        !_polylineCacheTime.containsKey(cacheKey)) {
      return false;
    }

    final now = DateTime.now();
    final cacheTime = _polylineCacheTime[cacheKey]!;
    final difference = now.difference(cacheTime);

    return difference < _polylineCacheExpiry;
  }

  /// Obtiene polyline del cache si es válido
  static List<LatLng>? getCachedPolyline(String cacheKey) {
    if (isPolylineCacheValid(cacheKey)) {
      logInfo('🎯 Usando polyline del cache: $cacheKey');
      return _polylineCache[cacheKey];
    }
    return null;
  }

  /// Guarda polyline en el cache
  static void savePolylineToCache(String cacheKey, List<LatLng> points) {
    _polylineCache[cacheKey] = points;
    _polylineCacheTime[cacheKey] = DateTime.now();
    logInfo(
        '💾 Polyline guardado en cache: $cacheKey (${points.length} puntos)');
  }

  /// Limpia el cache de polylines expirados
  static void cleanExpiredPolylineCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _polylineCacheTime.entries) {
      final difference = now.difference(entry.value);
      if (difference >= _polylineCacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _polylineCache.remove(key);
      _polylineCacheTime.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      logInfo(
          '🧹 Cache de polylines limpiado: ${expiredKeys.length} entradas expiradas');
    }
  }

  /// Limpia todo el cache de polylines
  static void clearPolylineCache() {
    _polylineCache.clear();
    _polylineCacheTime.clear();
    logInfo('🧹 Cache de polylines completamente limpiado');
  }

  /// Obtiene estadísticas del cache
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;

    for (final entry in _polylineCacheTime.entries) {
      final difference = now.difference(entry.value);
      if (difference < _polylineCacheExpiry) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }

    return {
      'total_entries': _polylineCache.length,
      'valid_entries': validEntries,
      'expired_entries': expiredEntries,
      'cache_expiry_minutes': _polylineCacheExpiry.inMinutes,
    };
  }

  // ===== GOOGLE DIRECTIONS API =====

  /// Obtiene polyline usando Google Directions API con waypoints optimizados
  static Future<List<LatLng>> getPolylineWithWaypoints({
    required LatLng origen,
    required LatLng destino,
    required List<LatLng> waypoints,
  }) async {
    // Generar clave de cache
    final allPoints = [origen, ...waypoints, destino];
    final cacheKey = generatePolylineCacheKey(allPoints);

    // Verificar cache primero
    final cachedPolyline = getCachedPolyline(cacheKey);
    if (cachedPolyline != null) {
      logInfo('💾 Usando polyline desde caché');
      return cachedPolyline;
    }

    try {
      logInfo(
          '🌐 Llamando a Google Directions API con ${waypoints.length} waypoints...');

      final dio = Dio();
      final origin = '${origen.latitude},${origen.longitude}';
      final destination = '${destino.latitude},${destino.longitude}';

      // Construir waypoints intermedios
      final waypointsParam =
          waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');

      final url = 'https://maps.googleapis.com/maps/api/directions/json';
      final query = {
        'origin': origin,
        'destination': destination,
        'mode': 'driving',
        'units': 'metric',
        'departure_time': 'now',
        'key': EndpointManager.googleMapsApiKey,
      };

      // Agregar waypoints solo si hay puntos intermedios
      if (waypointsParam.isNotEmpty) {
        query['waypoints'] =
            'optimize:true|$waypointsParam'; // Optimizar waypoints automáticamente
      }

      logInfo('🌐 URL completa: $url');
      logInfo('🌐 Query parameters: $query');

      final resp = await dio.get(url, queryParameters: query);

      logInfo('🌐 Respuesta recibida: status=${resp.statusCode}');
      logInfo('🌐 Status de API: ${resp.data['status']}');

      if (resp.statusCode == 200 && resp.data['status'] == 'OK') {
        final route = resp.data['routes'][0];
        logInfo('🌐 Estructura de route recibida: ${route.keys.toList()}');

        final polylinePoints = decodePolylineFromResponse(route);

        // Guardar en caché
        savePolylineToCache(cacheKey, polylinePoints);

        logInfo('✅ Polyline obtenida con ${polylinePoints.length} puntos');
        return polylinePoints;
      } else {
        logError('❌ Error en Google Directions API: ${resp.data['status']}');
        logError('❌ Respuesta completa: ${resp.data}');
        return [];
      }
    } catch (e) {
      logError('❌ Error llamando a Google Directions API: $e');
      return [];
    }
  }

  /// Obtiene polyline usando Google Directions API para lista de waypoints
  static Future<List<LatLng>> getPolylineWithDirectionsAPI(
      List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      return [];
    }

    // Generar clave de cache
    final cacheKey = generatePolylineCacheKey(waypoints);

    // Verificar cache primero
    final cachedPolyline = getCachedPolyline(cacheKey);
    if (cachedPolyline != null) {
      return cachedPolyline;
    }

    try {
      logInfo(
          '🌐 Llamando a Google Directions API para ${waypoints.length} waypoints...');

      final dio = Dio();
      final origin = '${waypoints.first.latitude},${waypoints.first.longitude}';
      final destination =
          '${waypoints.last.latitude},${waypoints.last.longitude}';

      // Construir waypoints intermedios (excluyendo origen y destino)
      final intermediateWaypoints =
          waypoints.skip(1).take(waypoints.length - 2);
      final waypointsParam = intermediateWaypoints
          .map((wp) => '${wp.latitude},${wp.longitude}')
          .join('|');

      final url = 'https://maps.googleapis.com/maps/api/directions/json';
      final query = {
        'origin': origin,
        'destination': destination,
        'mode': 'driving',
        'units': 'metric',
        'departure_time': 'now',
        'key': EndpointManager.googleMapsApiKey,
      };

      // Agregar waypoints solo si hay puntos intermedios
      if (waypointsParam.isNotEmpty) {
        query['waypoints'] = waypointsParam;
      }

      logInfo('🌐 URL completa: $url');
      logInfo('🌐 Query parameters: $query');

      final resp = await dio.get(url, queryParameters: query);

      logInfo('🌐 Respuesta recibida: status=${resp.statusCode}');
      logInfo('🌐 Status de API: ${resp.data['status']}');

      if (resp.statusCode == 200 && resp.data['status'] == 'OK') {
        final route = resp.data['routes'][0];
        logInfo('🌐 Estructura de route recibida: ${route.keys.toList()}');

        // Decodificar polyline usando función unificada
        final decodedPoints = decodePolylineFromResponse(route);

        // Guardar en cache
        savePolylineToCache(cacheKey, decodedPoints);

        // Limpiar cache expirado
        cleanExpiredPolylineCache();

        return decodedPoints;
      } else {
        logWarning('⚠️ Google Directions API error: ${resp.data['status']}');
        logWarning('⚠️ Respuesta completa: ${resp.data}');
        return [];
      }
    } catch (e) {
      logError('❌ Error en Google Directions API', e);
      return [];
    }
  }

  /// Extrae información de tiempo y distancia de la respuesta de Google Directions API
  static Map<String, dynamic> extractRouteInfo(
      Map<String, dynamic> route, List<LatLng> waypoints) {
    final Map<String, dynamic> legInfoByPedidoId = {};

    try {
      final legs = route['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) {
        return legInfoByPedidoId;
      }

      int cumulativeDurationSeconds = 0;

      for (int i = 0; i < legs.length && i < waypoints.length - 1; i++) {
        final leg = legs[i];
        final distance = leg['distance']['text'] as String;
        final duration = leg['duration']['text'] as String;
        final durationSeconds = leg['duration']['value'] as int;

        cumulativeDurationSeconds += durationSeconds;

        // Formatear tiempo acumulativo
        final cumulativeDurationText =
            _formatDuration(cumulativeDurationSeconds);

        // Crear LegInfo para este segmento
        final legInfo = {
          'distanceText': distance,
          'durationText': duration,
          'durationSeconds': durationSeconds,
          'cumulativeDurationText': cumulativeDurationText,
          'cumulativeDurationSeconds': cumulativeDurationSeconds,
        };

        // Asociar con el waypoint correspondiente (i+1, ya que el primero es la ubicación actual)
        if (i + 1 < waypoints.length) {
          final waypoint = waypoints[i + 1];
          final key = StatusHelpers.formatearCoordenadasAltaPrecision(
              waypoint.latitude, waypoint.longitude);
          legInfoByPedidoId[key] = legInfo;
        }
      }

      logInfo(
          '✅ Información de ruta extraída para ${legInfoByPedidoId.length} waypoints');
    } catch (e) {
      logError('❌ Error al extraer información de ruta', e);
    }

    return legInfoByPedidoId;
  }

  /// Formatea duración en segundos a texto legible
  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Obtiene información real de tiempo y distancia de Google Directions API
  static Future<Map<String, LegInfo>> getRealRouteInfo({
    required LatLng origen,
    required LatLng destino,
    required List<LatLng> waypoints,
    required List<Pedido> pedidos,
    required Set<String> pedidosConPolyline,
  }) async {
    final Map<String, LegInfo> legInfoByPedidoId = {};

    try {
      logInfo('🌐 Obteniendo información real de Google Directions API...');

      final dio = Dio();
      final origin = '${origen.latitude},${origen.longitude}';
      final destination = '${destino.latitude},${destino.longitude}';

      // Construir waypoints intermedios
      final waypointsParam =
          waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');

      final url = 'https://maps.googleapis.com/maps/api/directions/json';
      final query = {
        'origin': origin,
        'destination': destination,
        'mode': 'driving',
        'units': 'metric',
        'departure_time': 'now',
        'key': EndpointManager.googleMapsApiKey,
      };

      // Agregar waypoints solo si hay puntos intermedios
      if (waypointsParam.isNotEmpty) {
        query['waypoints'] = 'optimize:true|$waypointsParam';
      }

      final resp = await dio.get(url, queryParameters: query);

      if (resp.statusCode == 200 && resp.data['status'] == 'OK') {
        final route = resp.data['routes'][0];
        final legs = route['legs'] as List<dynamic>?;

        if (legs != null && legs.isNotEmpty) {
          int tiempoAcumulativo = 0;

          // Crear waypoints completos (origen + waypoints + destino)
          final allWaypoints = [origen, ...waypoints, destino];

          for (int i = 0; i < legs.length && i < allWaypoints.length - 1; i++) {
            final leg = legs[i];
            final distance = leg['distance']['text'] as String;
            final duration = leg['duration']['text'] as String;
            final durationSeconds = leg['duration']['value'] as int;

            tiempoAcumulativo += durationSeconds;

            // Formatear tiempo acumulativo
            final cumulativeDurationText = _formatDuration(tiempoAcumulativo);

            // Crear LegInfo para este segmento
            final legInfo = LegInfo(
              distance, // distanceText
              duration, // durationText
              durationSeconds, // durationSeconds
              cumulativeDurationText, // cumulativeDurationText
              tiempoAcumulativo, // cumulativeDurationSeconds
            );

            // Asociar con el pedido correspondiente (i+1, ya que el primero es la ubicación actual)
            if (i + 1 < allWaypoints.length) {
              final waypoint = allWaypoints[i + 1];

              // Buscar el pedido que corresponde a este waypoint
              for (final pedido in pedidos) {
                if (pedidosConPolyline.contains(pedido.id) &&
                    pedido.latitudEntrega != null &&
                    pedido.longitudEntrega != null) {
                  final distancia = Geolocator.distanceBetween(
                    waypoint.latitude,
                    waypoint.longitude,
                    pedido.latitudEntrega!,
                    pedido.longitudEntrega!,
                  );

                  // Si la distancia es menor a 50 metros, es el mismo punto
                  if (distancia < 50) {
                    legInfoByPedidoId[pedido.id] = legInfo;
                    logInfo(
                        '📊 Leg info real para pedido ${pedido.id}: ${legInfo.distanceText}, ${legInfo.durationText}, ${legInfo.cumulativeDurationText}');
                    break;
                  }
                }
              }
            }
          }

          logInfo(
              '✅ Información real de Google Directions API obtenida para ${legInfoByPedidoId.length} pedidos');
        }
      } else {
        logWarning('⚠️ Error en Google Directions API: ${resp.data['status']}');
      }
    } catch (e) {
      logError(
          '❌ Error obteniendo información real de Google Directions API', e);
    }

    return legInfoByPedidoId;
  }

  /// Obtiene información de tiempo inteligente según el estado del pedido
  static Future<Map<String, LegInfo>> getSmartRouteInfo({
    required LatLng origen,
    required List<Pedido> pedidos,
    required Set<String> pedidosConPolyline,
  }) async {
    final Map<String, LegInfo> legInfoByPedidoId = {};

    try {
      logInfo('🧠 Calculando tiempos inteligentes según estado de pedidos...');

      for (final pedido in pedidos) {
        if (!pedidosConPolyline.contains(pedido.id)) {
          continue;
        }

        LatLng? destino;
        String tipoDestino = '';

        // Determinar destino según el estado del pedido
        switch (pedido.estado) {
          case EstadoPedido.asignado:
          case EstadoPedido.pendiente:
            // Para pedidos asignados o pendientes, calcular tiempo hasta recogida
            if (pedido.latitudRecojo != null && pedido.longitudRecojo != null) {
              destino = LatLng(pedido.latitudRecojo!, pedido.longitudRecojo!);
              tipoDestino = 'recogida';
            }

          case EstadoPedido.recogido:
          case EstadoPedido.enRuta:
            // Para pedidos recogidos o en ruta, calcular tiempo hasta entrega
            if (pedido.latitudEntrega != null &&
                pedido.longitudEntrega != null) {
              destino = LatLng(pedido.latitudEntrega!, pedido.longitudEntrega!);
              tipoDestino = 'entrega';
            }

          case EstadoPedido.entregado:
          case EstadoPedido.fallido:
          case EstadoPedido.cancelado:
            // No calcular tiempos para pedidos ya procesados
            continue;
        }

        if (destino == null) {
          logWarning(
              '⚠️ No hay destino válido para pedido ${pedido.id} (${pedido.estado})');
          continue;
        }

        // Calcular tiempo desde origen hasta el destino específico
        final legInfo =
            await _calculateTimeToDestination(origen, destino, tipoDestino);
        if (legInfo != null) {
          legInfoByPedidoId[pedido.id] = legInfo;
          logInfo(
              '⏱️ Tiempo a $tipoDestino para pedido ${pedido.id}: ${legInfo.durationText}');
        }
      }

      logInfo(
          '✅ Tiempos inteligentes calculados para ${legInfoByPedidoId.length} pedidos');
    } catch (e) {
      logError('❌ Error calculando tiempos inteligentes', e);
    }

    return legInfoByPedidoId;
  }

  /// Calcula el tiempo desde origen hasta un destino específico
  static Future<LegInfo?> _calculateTimeToDestination(
      LatLng origen, LatLng destino, String tipoDestino) async {
    try {
      final dio = Dio();
      final origin = '${origen.latitude},${origen.longitude}';
      final destination = '${destino.latitude},${destino.longitude}';

      final url = 'https://maps.googleapis.com/maps/api/directions/json';
      final query = {
        'origin': origin,
        'destination': destination,
        'mode': 'driving',
        'units': 'metric',
        'departure_time': 'now',
        'key': EndpointManager.googleMapsApiKey,
      };

      final resp = await dio.get(url, queryParameters: query);

      if (resp.statusCode == 200 && resp.data['status'] == 'OK') {
        final route = resp.data['routes'][0];
        final legs = route['legs'] as List<dynamic>?;

        if (legs != null && legs.isNotEmpty) {
          final leg = legs[0];
          final distance = leg['distance']['text'] as String;
          final duration = leg['duration']['text'] as String;
          final durationSeconds = leg['duration']['value'] as int;

          // Para tiempos inteligentes, el tiempo acumulativo es igual al tiempo del segmento
          final cumulativeDurationText = _formatDuration(durationSeconds);

          return LegInfo(
            distance,
            duration,
            durationSeconds,
            cumulativeDurationText,
            durationSeconds, // Tiempo acumulativo = tiempo del segmento
          );
        }
      }
    } catch (e) {
      logError('❌ Error calculando tiempo a $tipoDestino', e);
    }

    return null;
  }
}

/// Información de un segmento de ruta
class LegInfo {
  final String distanceText;
  final String durationText;
  final int durationSeconds;
  final String cumulativeDurationText; // Tiempo acumulativo
  final int cumulativeDurationSeconds; // Segundos acumulativos

  const LegInfo(
    this.distanceText,
    this.durationText,
    this.durationSeconds,
    this.cumulativeDurationText,
    this.cumulativeDurationSeconds,
  );
}

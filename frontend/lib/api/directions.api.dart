import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/directions_response.model.dart';
import 'package:medrush/models/route_info.model.dart';
import 'package:medrush/utils/loggers.dart';

class DirectionsApi {
  /// Obtiene direcciones con waypoints usando el endpoint del backend
  static Future<DirectionsResponse?> getDirectionsWithWaypoints({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    bool optimizeWaypoints = false,
  }) async {
    try {
      logInfo(
          '🔄 Obteniendo direcciones con waypoints vía backend: ${waypoints.length} waypoints');

      final url =
          EndpointManager.buildUrl(EndpointManager.directionsWithWaypoints);

      final response = await BaseApi.client.post(
        url,
        data: {
          'origen': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
          'destino': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
          'waypoints': waypoints
              .map((wp) => {
                    'latitude': wp.latitude,
                    'longitude': wp.longitude,
                  })
              .toList(),
          'optimize_waypoints': optimizeWaypoints,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        logError(
            '❌ Error en respuesta de Directions API: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        logError('Error en Directions API: ${data['message']}');
        return null;
      }

      final resultData = data['data'] as Map<String, dynamic>;
      final directionsResponse = DirectionsResponse.fromJson(resultData);

      logInfo(
          'Direcciones obtenidas vía backend: ${directionsResponse.legs.length} legs');
      return directionsResponse;
    } catch (e) {
      logError('Error obteniendo direcciones vía backend', e);
      return null;
    }
  }

  /// Obtiene información de ruta usando el endpoint del backend
  static Future<RouteInfo?> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
  }) async {
    try {
      logInfo(
          '🔄 Obteniendo información de ruta vía backend: ${waypoints.length} waypoints');

      final url = EndpointManager.buildUrl(EndpointManager.directionsRouteInfo);

      final response = await BaseApi.client.post(
        url,
        data: {
          'origen': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
          'destino': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
          'waypoints': waypoints
              .map((wp) => {
                    'latitude': wp.latitude,
                    'longitude': wp.longitude,
                  })
              .toList(),
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        logError(
            '❌ Error en respuesta de Route Info API: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        logError('Error en Route Info API: ${data['message']}');
        return null;
      }

      final resultData = data['data'] as Map<String, dynamic>;
      final routeInfo = RouteInfo.fromJson(resultData);

      logInfo(
          'Información de ruta obtenida vía backend: ${routeInfo.legs.length} legs');
      return routeInfo;
    } catch (e) {
      logError('Error obteniendo información de ruta vía backend', e);
      return null;
    }
  }
}

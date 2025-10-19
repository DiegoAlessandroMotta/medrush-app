import 'dart:math';

import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';

class UbicacionesRepartidorApi {
  /// Obtiene las ubicaciones de un repartidor para un pedido específico
  static Future<List<Map<String, dynamic>>> getUbicacionesRepartidor(
      String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          EndpointManager.ubicacionesRepartidor,
          queryParameters: {'pedido_id': pedidoId},
        );

        if (response.data?['status'] == 'success') {
          final List<dynamic> ubicacionesData = response.data?['data'] ?? [];
          return ubicacionesData
              .map((json) => json as Map<String, dynamic>)
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
      operationName:
          'Obteniendo ubicaciones del repartidor para pedido: $pedidoId',
    );
  }

  /// Registra una nueva ubicación del repartidor durante la entrega
  static Future<bool> registrarUbicacionRepartidor({
    required String pedidoId,
    required String repartidorId,
    required double latitud,
    required double longitud,
    double? precisionMetros,
    double? velocidadMs,
    double? direccionGrados,
    String? direccion,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
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
        if (direccion != null) {
          body['direccion_texto'] = direccion;
        }

        final response = await BaseApi.post<Map<String, dynamic>>(
          EndpointManager.ubicacionesRepartidor,
          data: {
            'pedido_id': pedidoId,
            ...body,
          },
        );

        return ApiHelper.isValidResponse(response.data);
      },
      operationName:
          'Registrando ubicación del repartidor para pedido: $pedidoId',
    );
  }

  /// Obtiene la última ubicación registrada de un repartidor para un pedido
  static Future<Map<String, dynamic>?> getUltimaUbicacionRepartidor(
      String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final ubicaciones = await getUbicacionesRepartidor(pedidoId);

        if (ubicaciones.isNotEmpty) {
          // Ordenar por fecha de creación descendente y tomar la primera
          ubicaciones.sort((a, b) {
            final fechaA = DateTime.tryParse(a['created_at'] ?? '');
            final fechaB = DateTime.tryParse(b['created_at'] ?? '');

            if (fechaA == null || fechaB == null) {
              return 0;
            }
            return fechaB.compareTo(fechaA);
          });

          return ubicaciones.first;
        }

        return null;
      },
      operationName:
          'Obteniendo última ubicación del repartidor para pedido: $pedidoId',
    );
  }

  /// Obtiene el historial de ubicaciones de un repartidor en un rango de tiempo
  static Future<List<Map<String, dynamic>>> getHistorialUbicaciones({
    required String pedidoId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? limite,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final ubicaciones = await getUbicacionesRepartidor(pedidoId);

        // Filtrar por rango de fechas si se especifica
        List<Map<String, dynamic>> ubicacionesFiltradas = ubicaciones;

        if (fechaInicio != null || fechaFin != null) {
          ubicacionesFiltradas = ubicaciones.where((ubicacion) {
            final fechaCreacion =
                DateTime.tryParse(ubicacion['created_at'] ?? '');
            if (fechaCreacion == null) {
              return false;
            }

            if (fechaInicio != null && fechaCreacion.isBefore(fechaInicio)) {
              return false;
            }
            if (fechaFin != null && fechaCreacion.isAfter(fechaFin)) {
              return false;
            }

            return true;
          }).toList();
        }

        // Ordenar por fecha de creación descendente
        ubicacionesFiltradas.sort((a, b) {
          final fechaA = DateTime.tryParse(a['created_at'] ?? '');
          final fechaB = DateTime.tryParse(b['created_at'] ?? '');

          if (fechaA == null || fechaB == null) {
            return 0;
          }
          return fechaB.compareTo(fechaA);
        });

        // Aplicar límite si se especifica
        if (limite != null && limite > 0) {
          ubicacionesFiltradas = ubicacionesFiltradas.take(limite).toList();
        }

        return ubicacionesFiltradas;
      },
      operationName:
          'Obteniendo historial de ubicaciones para pedido: $pedidoId',
    );
  }

  /// Calcula la distancia total recorrida por un repartidor en un pedido
  static Future<double> calcularDistanciaTotalRecorrida(String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final ubicaciones = await getUbicacionesRepartidor(pedidoId);

        if (ubicaciones.length < 2) {
          return 0.0;
        }

        // Ordenar ubicaciones por fecha de creación
        ubicaciones.sort((a, b) {
          final fechaA = DateTime.tryParse(a['created_at'] ?? '');
          final fechaB = DateTime.tryParse(b['created_at'] ?? '');

          if (fechaA == null || fechaB == null) {
            return 0;
          }
          return fechaA.compareTo(fechaB);
        });

        double distanciaTotal = 0.0;

        for (int i = 1; i < ubicaciones.length; i++) {
          final ubicacionAnterior = ubicaciones[i - 1];
          final ubicacionActual = ubicaciones[i];

          final lat1 = ubicacionAnterior['ubicacion']?['latitude'] as double?;
          final lon1 = ubicacionAnterior['ubicacion']?['longitude'] as double?;
          final lat2 = ubicacionActual['ubicacion']?['latitude'] as double?;
          final lon2 = ubicacionActual['ubicacion']?['longitude'] as double?;

          if (lat1 != null && lon1 != null && lat2 != null && lon2 != null) {
            final distancia =
                _calcularDistanciaHaversine(lat1, lon1, lat2, lon2);
            distanciaTotal += distancia;
          }
        }

        return distanciaTotal;
      },
      operationName:
          'Calculando distancia total recorrida para pedido: $pedidoId',
    );
  }

  /// Calcula la velocidad promedio de un repartidor en un pedido
  static Future<double> calcularVelocidadPromedio(String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final ubicaciones = await getUbicacionesRepartidor(pedidoId);

        if (ubicaciones.length < 2) {
          return 0.0;
        }

        // Ordenar ubicaciones por fecha de creación
        ubicaciones.sort((a, b) {
          final fechaA = DateTime.tryParse(a['created_at'] ?? '');
          final fechaB = DateTime.tryParse(b['created_at'] ?? '');

          if (fechaA == null || fechaB == null) {
            return 0;
          }
          return fechaA.compareTo(fechaB);
        });

        double velocidadTotal = 0.0;
        int medicionesValidas = 0;

        for (final ubicacion in ubicaciones) {
          final velocidad = ubicacion['velocidad_ms'] as double?;
          if (velocidad != null && velocidad > 0) {
            velocidadTotal += velocidad;
            medicionesValidas++;
          }
        }

        if (medicionesValidas == 0) {
          return 0.0;
        }

        return velocidadTotal / medicionesValidas;
      },
      operationName: 'Calculando velocidad promedio para pedido: $pedidoId',
    );
  }

  /// Obtiene estadísticas de ubicaciones para un pedido
  static Future<Map<String, dynamic>> getEstadisticasUbicaciones(
      String pedidoId) {
    return ApiHelper.executeWithLogging(
      () async {
        final ubicaciones = await getUbicacionesRepartidor(pedidoId);
        final distanciaTotal = await calcularDistanciaTotalRecorrida(pedidoId);
        final velocidadPromedio = await calcularVelocidadPromedio(pedidoId);

        return <String, dynamic>{
          'total_ubicaciones': ubicaciones.length,
          'distancia_total_km': distanciaTotal,
          'velocidad_promedio_ms': velocidadPromedio,
          'velocidad_promedio_kmh':
              velocidadPromedio * 3.6, // Convertir m/s a km/h
          'fecha_primera_ubicacion':
              ubicaciones.isNotEmpty ? ubicaciones.first['created_at'] : null,
          'fecha_ultima_ubicacion':
              ubicaciones.isNotEmpty ? ubicaciones.last['created_at'] : null,
          'precision_promedio_m': ubicaciones.isNotEmpty
              ? ubicaciones
                      .where((u) => u['precision_m'] != null)
                      .map((u) => u['precision_m'] as double)
                      .reduce((a, b) => a + b) /
                  ubicaciones.length
              : null,
        };
      },
      operationName:
          'Obteniendo estadísticas de ubicaciones para pedido: $pedidoId',
    );
  }

  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  static double _calcularDistanciaHaversine(
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
  static double _gradosARadianes(double grados) {
    return grados * (3.14159265359 / 180);
  }
}

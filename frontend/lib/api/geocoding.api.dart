import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/geocoding_result.model.dart';
import 'package:medrush/utils/loggers.dart';

class GeocodingApi {
  /// Realiza geocodificación inversa usando el endpoint del backend
  static Future<GeocodingResult?> reverseGeocode(
      double latitude, double longitude) async {
    try {
      logInfo(
          '🔄 Realizando geocodificación inversa vía backend: $latitude, $longitude');

      final url = EndpointManager.buildUrl(EndpointManager.geocodingReverse);

      final requestData = {
        'ubicacion': {
          'latitude': latitude,
          'longitude': longitude,
        }
      };

      logInfo('Enviando datos a backend: $requestData');

      final response = await BaseApi.client.post(
        url,
        data: requestData,
      );

      if (response.statusCode != 200 || response.data == null) {
        logError(
            '❌ Error en respuesta de Geocoding API: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'success') {
        logError('Error en Geocoding API: ${data['message']}');
        return null;
      }

      final resultData = data['data'] as Map<String, dynamic>;
      final geocodingResult = GeocodingResult.fromJson(resultData);

      logInfo(
          'Geocodificación exitosa vía backend: ${geocodingResult.formattedAddress}');
      return geocodingResult;
    } catch (e) {
      logError('Error en geocodificación inversa vía backend', e);

      // Log adicional para debugging
      if (e.toString().contains('500')) {
        logError('Error 500 del servidor - posible problema en el backend');
      }

      return null;
    }
  }
}

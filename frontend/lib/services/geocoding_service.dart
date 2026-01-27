import 'package:medrush/api/geocoding.api.dart';
import 'package:medrush/models/geocoding_result.model.dart';
import 'package:medrush/utils/loggers.dart';

class GeocodingService {
  /// Realiza geocodificación inversa para obtener información de dirección desde coordenadas
  /// Ahora usa el endpoint del backend que centraliza las llamadas a Google APIs
  static Future<GeocodingResult?> reverseGeocode(
      double latitude, double longitude) async {
    try {
      logInfo(
          '🔄 Realizando geocodificación inversa vía backend para: $latitude, $longitude');

      final result = await GeocodingApi.reverseGeocode(latitude, longitude);

      if (result != null) {
        logInfo(
            '✅ Geocodificación exitosa vía backend: ${result.formattedAddress}');
        logInfo(
            '📍 Componentes extraídos - Dirección: "${result.addressLine1}", Ciudad: "${result.city}", Estado: "${result.state}", Código Postal: "${result.postalCode}"');
      } else {
        logWarning(
            '⚠️ No se pudo obtener resultado de geocodificación vía backend');
      }

      return result;
    } catch (e) {
      logError('❌ Error en geocodificación inversa vía backend', e);

      // Fallback: retornar información básica basada en coordenadas
      if (e.toString().contains('500')) {
        logWarning('⚠️ Backend con error 500, usando fallback de coordenadas');
        return GeocodingResult(
          addressLine1:
              'Coordenadas: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          city: '',
          state: '',
          postalCode: '',
          country: 'United States',
          formattedAddress:
              'Coordenadas: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
        );
      }

      return null;
    }
  }
}

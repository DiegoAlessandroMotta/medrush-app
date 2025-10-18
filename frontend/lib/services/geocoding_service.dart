import 'package:dio/dio.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/utils/loggers.dart';

class GeocodingService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static final Dio _dio = Dio();

  /// Realiza geocodificación inversa para obtener información de dirección desde coordenadas
  static Future<GeocodingResult?> reverseGeocode(
      double latitude, double longitude) async {
    try {
      logInfo(
          '🔄 Realizando geocodificación inversa para: $latitude, $longitude');

      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': EndpointManager.googleMapsApiKey,
          'language': 'es', // Español para Perú
          'region': 'pe', // Región Perú
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        logError(
            '❌ Error en respuesta de Geocoding API: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 'OK') {
        logError(
            '❌ Error en Geocoding API: ${data['status']} - ${data['error_message']}');
        return null;
      }

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        logError('❌ No se encontraron resultados de geocodificación');
        return null;
      }

      // Usar el primer resultado (más preciso)
      final result = results.first as Map<String, dynamic>;
      final addressComponents =
          result['address_components'] as List<dynamic>? ?? [];

      final geocodingResult =
          _parseAddressComponents(addressComponents, result);

      logInfo('✅ Geocodificación exitosa: ${geocodingResult.formattedAddress}');
      logInfo(
          '📍 Componentes extraídos - Dirección: "${geocodingResult.addressLine1}", Ciudad: "${geocodingResult.city}", Estado: "${geocodingResult.state}", Código Postal: "${geocodingResult.postalCode}"');
      return geocodingResult;
    } catch (e) {
      logError('❌ Error en geocodificación inversa', e);
      return null;
    }
  }

  /// Parsea los componentes de dirección de la respuesta de Google
  static GeocodingResult _parseAddressComponents(
      List<dynamic> components, Map<String, dynamic> result) {
    String streetNumber = '';
    String route = '';
    String sublocality = '';
    String locality = '';
    String administrativeAreaLevel1 = '';
    String administrativeAreaLevel2 = '';
    String country = '';
    String postalCode = '';
    String formattedAddress = result['formatted_address'] as String? ?? '';

    for (final component in components) {
      final types = (component['types'] as List<dynamic>?) ?? [];
      final longName = component['long_name'] as String? ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        sublocality = longName;
      } else if (types.contains('locality')) {
        locality = longName;
      } else if (types.contains('administrative_area_level_1')) {
        administrativeAreaLevel1 = longName;
      } else if (types.contains('administrative_area_level_2')) {
        administrativeAreaLevel2 = longName;
      } else if (types.contains('country')) {
        country = longName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      }
    }

    // Construir dirección línea 1
    String addressLine1 = '';
    if (streetNumber.isNotEmpty && route.isNotEmpty) {
      addressLine1 = '$streetNumber $route';
    } else if (route.isNotEmpty) {
      addressLine1 = route;
    } else if (streetNumber.isNotEmpty) {
      addressLine1 = streetNumber;
    }

    // Determinar ciudad (prioridad: locality > sublocality > administrative_area_level_2)
    String city = '';
    if (locality.isNotEmpty) {
      city = locality;
    } else if (sublocality.isNotEmpty) {
      city = sublocality;
    } else if (administrativeAreaLevel2.isNotEmpty) {
      city = administrativeAreaLevel2;
    }

    // Determinar estado/región
    String state = administrativeAreaLevel1;

    return GeocodingResult(
      addressLine1: addressLine1,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      formattedAddress: formattedAddress,
    );
  }
}

class GeocodingResult {
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String formattedAddress;

  const GeocodingResult({
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.formattedAddress,
  });

  @override
  String toString() {
    return 'GeocodingResult(addressLine1: $addressLine1, city: $city, state: $state, postalCode: $postalCode, country: $country)';
  }
}

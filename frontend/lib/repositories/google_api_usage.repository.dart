import 'package:medrush/api/base.api.dart';
import 'package:medrush/models/google_api_usage.model.dart';

class GoogleApiUsageRepository {
  static const String _basePath = '/google-api-usage';

  /// Obtiene las estadísticas de uso de Google API
  ///
  /// [year] - Año para las estadísticas (opcional, por defecto año actual)
  /// [month] - Mes para las estadísticas (opcional, por defecto mes actual)
  /// [serviceType] - Tipo de servicio específico (opcional)
  static Future<GoogleApiUsageStats> getUsageStats({
    int? year,
    int? month,
    String? serviceType,
  }) async {
    final queryParams = <String, String>{};

    if (year != null) {
      queryParams['year'] = year.toString();
    }
    if (month != null) {
      queryParams['month'] = month.toString();
    }
    if (serviceType != null) {
      queryParams['service_type'] = serviceType;
    }

    final response = await BaseApi.get(
      '$_basePath/stats',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return GoogleApiUsageStats.fromJson(response.data['data']);
  }

  /// Obtiene las estadísticas del mes actual
  static Future<GoogleApiUsageStats> getCurrentMonthStats() {
    return getUsageStats();
  }

  /// Obtiene las estadísticas de un mes específico
  static Future<GoogleApiUsageStats> getMonthStats(int year, int month) {
    return getUsageStats(year: year, month: month);
  }

  /// Obtiene las estadísticas de un servicio específico
  static Future<GoogleApiUsageStats> getServiceStats(String serviceType) {
    return getUsageStats(serviceType: serviceType);
  }
}

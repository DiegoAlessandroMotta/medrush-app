import 'package:medrush/api/base.api.dart';

/// DTO para período de uso de Google API
class GoogleApiUsagePeriodDto {
  final DateTime startDate;
  final DateTime endDate;

  GoogleApiUsagePeriodDto({
    required this.startDate,
    required this.endDate,
  });

  factory GoogleApiUsagePeriodDto.fromJson(Map<String, dynamic> json) {
    return GoogleApiUsagePeriodDto(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  String get formattedPeriod {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }
}

/// DTO para resumen de uso de Google API
class GoogleApiUsageSummaryDto {
  final int totalRequests;
  final double totalEstimatedCost;
  final String currency;

  GoogleApiUsageSummaryDto({
    required this.totalRequests,
    required this.totalEstimatedCost,
    required this.currency,
  });

  factory GoogleApiUsageSummaryDto.fromJson(Map<String, dynamic> json) {
    return GoogleApiUsageSummaryDto(
      totalRequests: json['total_requests'],
      totalEstimatedCost: (json['total_estimated_cost'] as num).toDouble(),
      currency: json['currency'],
    );
  }
}

/// DTO para servicio de Google API
class GoogleApiServiceDto {
  final String type;
  final String serviceName;
  final int totalRequests;
  final double costPerRequest;
  final double estimatedCost;

  GoogleApiServiceDto({
    required this.type,
    required this.serviceName,
    required this.totalRequests,
    required this.costPerRequest,
    required this.estimatedCost,
  });

  factory GoogleApiServiceDto.fromJson(Map<String, dynamic> json) {
    return GoogleApiServiceDto(
      type: json['type'],
      serviceName: json['service_name'],
      totalRequests: json['total_requests'],
      costPerRequest: (json['cost_per_request'] as num).toDouble(),
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
    );
  }

  String get formattedCostPerRequest {
    return '\$${costPerRequest.toStringAsFixed(3)}';
  }

  String get formattedCost {
    return '\$${estimatedCost.toStringAsFixed(2)}';
  }
}

/// DTO para estadísticas de uso de Google API
class GoogleApiUsageStatsDto {
  final GoogleApiUsagePeriodDto period;
  final GoogleApiUsageSummaryDto summary;
  final List<GoogleApiServiceDto> services;

  GoogleApiUsageStatsDto({
    required this.period,
    required this.summary,
    required this.services,
  });

  factory GoogleApiUsageStatsDto.fromJson(Map<String, dynamic> json) {
    return GoogleApiUsageStatsDto(
      period: GoogleApiUsagePeriodDto.fromJson(json['period']),
      summary: GoogleApiUsageSummaryDto.fromJson(json['summary']),
      services: (json['services'] as List)
          .map((service) => GoogleApiServiceDto.fromJson(service))
          .toList(),
    );
  }
}

class GoogleApiUsageRepository {
  static const String _basePath = '/google-api-usage';

  /// Obtiene las estadísticas de uso de Google API
  ///
  /// [year] - Año para las estadísticas (opcional, por defecto año actual)
  /// [month] - Mes para las estadísticas (opcional, por defecto mes actual)
  /// [serviceType] - Tipo de servicio específico (opcional)
  static Future<GoogleApiUsageStatsDto> getUsageStats({
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

    return GoogleApiUsageStatsDto.fromJson(response.data['data']);
  }

  /// Obtiene las estadísticas del mes actual
  static Future<GoogleApiUsageStatsDto> getCurrentMonthStats() {
    return getUsageStats();
  }

  /// Obtiene las estadísticas de un mes específico
  static Future<GoogleApiUsageStatsDto> getMonthStats(int year, int month) {
    return getUsageStats(year: year, month: month);
  }

  /// Obtiene las estadísticas de un servicio específico
  static Future<GoogleApiUsageStatsDto> getServiceStats(String serviceType) {
    return getUsageStats(serviceType: serviceType);
  }
}

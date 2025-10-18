class GoogleApiUsageStats {
  final GoogleApiUsagePeriod period;
  final GoogleApiUsageSummary summary;
  final List<GoogleApiService> services;

  GoogleApiUsageStats({
    required this.period,
    required this.summary,
    required this.services,
  });

  factory GoogleApiUsageStats.fromJson(Map<String, dynamic> json) {
    return GoogleApiUsageStats(
      period: GoogleApiUsagePeriod.fromJson(json['period']),
      summary: GoogleApiUsageSummary.fromJson(json['summary']),
      services: (json['services'] as List)
          .map((service) => GoogleApiService.fromJson(service))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period.toJson(),
      'summary': summary.toJson(),
      'services': services.map((service) => service.toJson()).toList(),
    };
  }
}

class GoogleApiUsagePeriod {
  final DateTime startDate;
  final DateTime endDate;

  GoogleApiUsagePeriod({
    required this.startDate,
    required this.endDate,
  });

  factory GoogleApiUsagePeriod.fromJson(Map<String, dynamic> json) {
    return GoogleApiUsagePeriod(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  String get formattedPeriod {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }
}

class GoogleApiUsageSummary {
  final int totalRequests;
  final double totalEstimatedCost;
  final String currency;

  GoogleApiUsageSummary({
    required this.totalRequests,
    required this.totalEstimatedCost,
    required this.currency,
  });

  factory GoogleApiUsageSummary.fromJson(Map<String, dynamic> json) {
    return GoogleApiUsageSummary(
      totalRequests: json['total_requests'],
      totalEstimatedCost: (json['total_estimated_cost'] as num).toDouble(),
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_requests': totalRequests,
      'total_estimated_cost': totalEstimatedCost,
      'currency': currency,
    };
  }

  String get formattedCost {
    return '\$${totalEstimatedCost.toStringAsFixed(2)} $currency';
  }
}

class GoogleApiService {
  final String type;
  final String serviceName;
  final int totalRequests;
  final double costPerRequest;
  final double estimatedCost;

  GoogleApiService({
    required this.type,
    required this.serviceName,
    required this.totalRequests,
    required this.costPerRequest,
    required this.estimatedCost,
  });

  factory GoogleApiService.fromJson(Map<String, dynamic> json) {
    return GoogleApiService(
      type: json['type'],
      serviceName: json['service_name'],
      totalRequests: json['total_requests'],
      costPerRequest: (json['cost_per_request'] as num).toDouble(),
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'service_name': serviceName,
      'total_requests': totalRequests,
      'cost_per_request': costPerRequest,
      'estimated_cost': estimatedCost,
    };
  }

  String get formattedCost {
    return '\$${estimatedCost.toStringAsFixed(2)}';
  }

  String get formattedCostPerRequest {
    return '\$${costPerRequest.toStringAsFixed(2)}';
  }
}

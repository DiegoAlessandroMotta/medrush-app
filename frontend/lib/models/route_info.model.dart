import 'package:medrush/models/leg_info.model.dart';

class RouteInfo {
  final List<LegInfo> legs;
  final int totalDistanceMeters;
  final int totalDurationSeconds;

  const RouteInfo({
    required this.legs,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    final legsData = json['legs'] as List<dynamic>? ?? [];
    final legs = legsData
        .map((leg) => LegInfo.fromJson(leg as Map<String, dynamic>))
        .toList();

    return RouteInfo(
      legs: legs,
      totalDistanceMeters: json['total_distance_meters'] as int? ?? 0,
      totalDurationSeconds: json['total_duration_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legs': legs.map((leg) => leg.toJson()).toList(),
      'total_distance_meters': totalDistanceMeters,
      'total_duration_seconds': totalDurationSeconds,
    };
  }

  @override
  String toString() {
    return 'RouteInfo(legs: ${legs.length}, totalDistanceMeters: $totalDistanceMeters, totalDurationSeconds: $totalDurationSeconds)';
  }
}

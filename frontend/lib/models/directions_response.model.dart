import 'package:medrush/models/leg_info.model.dart';

class DirectionsResponse {
  final String encodedPolyline;
  final List<LegInfo> legs;
  final int totalDistanceMeters;
  final int totalDurationSeconds;

  const DirectionsResponse({
    required this.encodedPolyline,
    required this.legs,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  factory DirectionsResponse.fromJson(Map<String, dynamic> json) {
    final legsData = json['legs'] as List<dynamic>? ?? [];
    final legs = legsData
        .map((leg) => LegInfo.fromJson(leg as Map<String, dynamic>))
        .toList();

    return DirectionsResponse(
      encodedPolyline: json['encoded_polyline'] as String? ?? '',
      legs: legs,
      totalDistanceMeters: json['total_distance_meters'] as int? ?? 0,
      totalDurationSeconds: json['total_duration_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encoded_polyline': encodedPolyline,
      'legs': legs.map((leg) => leg.toJson()).toList(),
      'total_distance_meters': totalDistanceMeters,
      'total_duration_seconds': totalDurationSeconds,
    };
  }

  @override
  String toString() {
    return 'DirectionsResponse(encodedPolyline: ${encodedPolyline.length} chars, legs: ${legs.length}, totalDistanceMeters: $totalDistanceMeters, totalDurationSeconds: $totalDurationSeconds)';
  }
}

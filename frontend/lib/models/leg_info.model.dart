class LegInfo {
  final String distanceText;
  final String durationText;
  final int distanceMeters;
  final int durationSeconds;
  final int cumulativeDistanceMeters;
  final int cumulativeDurationSeconds;

  const LegInfo({
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.cumulativeDistanceMeters,
    required this.cumulativeDurationSeconds,
  });

  factory LegInfo.fromJson(Map<String, dynamic> json) {
    return LegInfo(
      distanceText: json['distance_text'] as String? ?? '',
      durationText: json['duration_text'] as String? ?? '',
      distanceMeters: json['distance_meters'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      cumulativeDistanceMeters: json['cumulative_distance_meters'] as int? ?? 0,
      cumulativeDurationSeconds:
          json['cumulative_duration_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance_text': distanceText,
      'duration_text': durationText,
      'distance_meters': distanceMeters,
      'duration_seconds': durationSeconds,
      'cumulative_distance_meters': cumulativeDistanceMeters,
      'cumulative_duration_seconds': cumulativeDurationSeconds,
    };
  }

  @override
  String toString() {
    return 'LegInfo(distanceText: $distanceText, durationText: $durationText, durationSeconds: $durationSeconds)';
  }
}

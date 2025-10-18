<?php

namespace App\DTOs;

class LegInfoDTO
{
  public function __construct(
    public readonly string $distanceText,
    public readonly string $durationText,
    public readonly int $distanceMeters,
    public readonly int $durationSeconds,
    public readonly int $cumulativeDurationSeconds,
    public readonly int $cumulativeDistanceMeters,
  ) {}

  public function toArray(): array
  {
    return [
      'distance_text' => $this->distanceText,
      'duration_text' => $this->durationText,
      'distance_meters' => $this->distanceMeters,
      'duration_seconds' => $this->durationSeconds,
      'cumulative_distance_meters' => $this->cumulativeDistanceMeters,
      'cumulative_duration_seconds' => $this->cumulativeDurationSeconds,
    ];
  }

  public static function fromArray(array $data): self
  {
    return new self(
      distanceText: $data['distance_text'] ?? '',
      durationText: $data['duration_text'] ?? '',
      distanceMeters: $data['distance_meters'] ?? 0,
      durationSeconds: $data['duration_seconds'] ?? 0,
      cumulativeDistanceMeters: $data['cumulative_distance_meters'] ?? 0,
      cumulativeDurationSeconds: $data['cumulative_duration_seconds'] ?? 0,
    );
  }
}

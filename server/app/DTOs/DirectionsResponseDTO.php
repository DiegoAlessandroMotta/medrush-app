<?php

namespace App\DTOs;

class DirectionsResponseDTO
{
  /**
   * @param string $encodedPolyline
   * @param LegInfoDTO[] $legs
   * @param int $totalDistanceMeters
   * @param int $totalDurationSeconds
   * @param string $totalDistanceText
   * @param string $totalDurationText
   */
  public function __construct(
    public readonly string $encodedPolyline,
    public readonly array $legs,
    public readonly int $totalDistanceMeters,
    public readonly int $totalDurationSeconds,
  ) {}

  public function toArray(): array
  {
    return [
      'encoded_polyline' => $this->encodedPolyline,
      'legs' => array_map(fn(LegInfoDTO $leg) => $leg->toArray(), $this->legs),
      'total_distance_meters' => $this->totalDistanceMeters,
      'total_duration_seconds' => $this->totalDurationSeconds,
    ];
  }

  public static function fromArray(array $data): self
  {
    $legs = array_map(
      fn(array $legData) => LegInfoDTO::fromArray($legData),
      $data['legs'] ?? []
    );

    return new self(
      encodedPolyline: $data['encoded_polyline'] ?? '',
      legs: $legs,
      totalDistanceMeters: $data['total_distance_meters'] ?? 0,
      totalDurationSeconds: $data['total_duration_seconds'] ?? 0,
    );
  }
}

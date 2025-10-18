<?php

namespace App\Services\Directions;

use App\DTOs\DirectionsResponseDTO;
use App\DTOs\LegInfoDTO;
use App\DTOs\RouteInfoDTO;
use App\Enums\GoogleApiServiceType;
use App\Models\GoogleApiUsage;
use Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class DirectionsService
{
  private const API_BASE_ENDPOINT = 'https://maps.googleapis.com/maps/api/directions/json';
  private string $apiKey;

  public function __construct()
  {
    $this->apiKey = config('services.google.directions.api_key', '');
  }

  private function isServiceAvailable(): bool
  {
    return !empty($this->apiKey);
  }

  public function getDirectionsWithWaypoints(
    array $origin,
    array $destination,
    array $waypoints = [],
    bool $optimizeWaypoints = false
  ): ?DirectionsResponseDTO {
    if (!$this->isServiceAvailable()) {
      return null;
    }

    try {
      $params = [
        'origin' => "{$origin['latitude']},{$origin['longitude']}",
        'destination' => "{$destination['latitude']},{$destination['longitude']}",
        'mode' => 'driving',
        'units' => 'metric',
        'departure_time' => 'now',
        'key' => $this->apiKey,
      ];

      if (!empty($waypoints)) {
        $waypointsParam = implode('|', array_map(
          fn($wp) => "{$wp['latitude']},{$wp['longitude']}",
          $waypoints
        ));

        if ($optimizeWaypoints) {
          $params['waypoints'] = "optimize:true|{$waypointsParam}";
        } else {
          $params['waypoints'] = $waypointsParam;
        }
      }

      $response = Http::get(self::API_BASE_ENDPOINT, $params);

      GoogleApiUsage::create([
        'user_id' => Auth::user()?->id,
        'type' => GoogleApiServiceType::DIRECTIONS,
      ]);

      if (!$response->successful()) {
        Log::error("Error en respuesta de Directions API: {$response->status()}");
        return null;
      }

      $data = $response->json();

      if ($data['status'] !== 'OK') {
        Log::error("Error en Directions API: {$data['status']} - " . ($data['error_message'] ?? ''));
        return null;
      }

      $routes = $data['routes'] ?? [];
      if (empty($routes)) {
        Log::error('No se encontraron rutas');
        return null;
      }

      $route = $routes[0];

      $directionsResponse = $this->parseDirectionsResponse($route);

      return $directionsResponse;
    } catch (\Exception $e) {
      Log::error('Error en Directions API', ['error' => $e->getMessage()]);
      return null;
    }
  }

  public function getRouteInfo(
    array $origin,
    array $destination,
    array $waypoints = []
  ): ?RouteInfoDTO {
    if (!$this->isServiceAvailable()) {
      return null;
    }

    try {
      $params = [
        'origin' => "{$origin['latitude']},{$origin['longitude']}",
        'destination' => "{$destination['latitude']},{$destination['longitude']}",
        'mode' => 'driving',
        'units' => 'metric',
        'departure_time' => 'now',
        'key' => $this->apiKey,
      ];

      if (!empty($waypoints)) {
        $waypointsParam = implode('|', array_map(
          fn($wp) => "{$wp['latitude']},{$wp['longitude']}",
          $waypoints
        ));
        $params['waypoints'] = $waypointsParam;
      }

      $response = Http::get(self::API_BASE_ENDPOINT, $params);

      GoogleApiUsage::create([
        'user_id' => Auth::user()?->id,
        'type' => GoogleApiServiceType::DIRECTIONS,
      ]);

      if (!$response->successful() || $response->json()['status'] !== 'OK') {
        Log::error("Error obteniendo información de ruta");
        return null;
      }

      $data = $response->json();
      $route = $data['routes'][0] ?? null;

      if (!$route) {
        return null;
      }

      return $this->parseRouteInfo($route);
    } catch (\Exception $e) {
      Log::error('Error obteniendo información de ruta', ['error' => $e->getMessage()]);
      return null;
    }
  }

  /**
   * @return array{latitude: float, longitude: float}
   */
  public function decodePolyline(string $encoded): array
  {
    if (empty($encoded)) {
      return [];
    }

    $points = [];
    $index = 0;
    $len = strlen($encoded);
    $lat = 0;
    $lng = 0;

    $divisor = 100000.0;

    while ($index < $len) {
      $shift = 0;
      $result = 0;
      do {
        $b = ord($encoded[$index++]) - 63;
        $result |= ($b & 0x1f) << $shift;
        $shift += 5;
      } while ($b >= 0x20);
      $dlat = (($result & 1) != 0) ? ~($result >> 1) : ($result >> 1);
      $lat += $dlat;

      $shift = 0;
      $result = 0;
      do {
        $b = ord($encoded[$index++]) - 63;
        $result |= ($b & 0x1f) << $shift;
        $shift += 5;
      } while ($b >= 0x20);
      $dlng = (($result & 1) != 0) ? ~($result >> 1) : ($result >> 1);
      $lng += $dlng;

      $points[] = [
        'latitude' => $lat / $divisor,
        'longitude' => $lng / $divisor
      ];
    }

    return $points;
  }

  private function parseDirectionsResponse(array $route): DirectionsResponseDTO
  {
    $overviewPolyline = $route['overview_polyline']['points'] ?? '';

    $legs = $route['legs'] ?? [];
    $legInfos = [];
    $cumulativeDurationSeconds = 0;
    $cumulativeDistanceMeters = 0;

    Log::info($route);

    foreach ($legs as $index => $leg) {
      $distanceMeters = $leg['distance']['value'] ?? 0;
      $cumulativeDistanceMeters += $distanceMeters;

      $durationSeconds = $leg['duration']['value'] ?? 0;
      $cumulativeDurationSeconds += $durationSeconds;

      $legInfos[] = new LegInfoDTO(
        distanceText: $leg['distance']['text'] ?? '',
        durationText: $leg['duration']['text'] ?? '',
        distanceMeters: $distanceMeters,
        durationSeconds: $durationSeconds,
        cumulativeDistanceMeters: $cumulativeDistanceMeters,
        cumulativeDurationSeconds: $cumulativeDurationSeconds,
      );
    }

    $totalDistanceMeters = $cumulativeDistanceMeters;
    $totalDurationSeconds = $cumulativeDurationSeconds;

    return new DirectionsResponseDTO(
      encodedPolyline: $overviewPolyline,
      legs: $legInfos,
      totalDistanceMeters: $totalDistanceMeters,
      totalDurationSeconds: $totalDurationSeconds,
    );
  }

  private function parseRouteInfo(array $route): RouteInfoDTO
  {
    $legs = $route['legs'] ?? [];
    $legInfos = [];
    $cumulativeDurationSeconds = 0;
    $cumulativeDistanceMeters = 0;

    foreach ($legs as $leg) {
      $durationSeconds = $leg['duration']['value'] ?? 0;
      $cumulativeDurationSeconds += $durationSeconds;

      $distanceMeters = $leg['distance']['value'] ?? 0;
      $cumulativeDistanceMeters += $distanceMeters;

      $legInfos[] = new LegInfoDTO(
        distanceText: $leg['distance']['text'] ?? '',
        durationText: $leg['duration']['text'] ?? '',
        distanceMeters: $leg['distance']['value'] ?? 0,
        durationSeconds: $durationSeconds,
        cumulativeDurationSeconds: $cumulativeDurationSeconds,
        cumulativeDistanceMeters: $cumulativeDistanceMeters,
      );
    }

    $totalDistanceMeters = $cumulativeDistanceMeters;
    $totalDurationSeconds = $cumulativeDurationSeconds;

    return new RouteInfoDTO(
      legs: $legInfos,
      totalDistanceMeters: $totalDistanceMeters,
      totalDurationSeconds: $totalDurationSeconds,
    );
  }
}

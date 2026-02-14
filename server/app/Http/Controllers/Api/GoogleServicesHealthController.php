<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Google\Maps\RouteOptimization\V1\Client\RouteOptimizationClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;

/**
 * Health check para servicios de Google (Geocoding, Directions + polyline, Route Optimization).
 * Útil para verificar en producción que todas las APIs responden correctamente.
 */
class GoogleServicesHealthController extends Controller
{
  private const GEOCODE_URL = 'https://maps.googleapis.com/maps/api/geocode/json';
  private const DIRECTIONS_URL = 'https://maps.googleapis.com/maps/api/directions/json';

  /** Coordenadas de prueba: Lima, Perú */
  private const TEST_LAT = -12.046374;
  private const TEST_LNG = -77.042793;

  /** Origen y destino para probar Directions (ruta corta en Lima) */
  private const ORIGIN = '-12.046374,-77.042793';
  private const DESTINATION = '-12.070750,-77.085504';

  public function __invoke(): JsonResponse
  {
    $checks = [
      'geocoding' => $this->checkGeocoding(),
      'directions' => $this->checkDirections(),
      'directions_polyline' => $this->checkDirectionsPolyline(),
      'route_optimization' => $this->checkRouteOptimization(),
    ];

    $allOk = collect($checks)->every(fn ($c) => $c['ok'] === true);

    return response()->json([
      'ok' => $allOk,
      'message' => $allOk
        ? 'Todos los servicios de Google responden correctamente.'
        : 'Uno o más servicios presentan fallos.',
      'checks' => $checks,
      'timestamp' => now()->toIso8601String(),
    ], $allOk ? 200 : 503);
  }

  private function checkGeocoding(): array
  {
    $apiKey = config('services.google.geocoding.api_key', '');
    if ($apiKey === '') {
      return ['ok' => false, 'message' => 'GOOGLE_MAPS_API_KEY o GOOGLE_GEOCODING_API_KEY no configurada.'];
    }

    try {
      $response = Http::get(self::GEOCODE_URL, [
        'latlng' => self::TEST_LAT . ',' . self::TEST_LNG,
        'key' => $apiKey,
        'language' => 'es',
      ]);

      if (!$response->successful()) {
        return ['ok' => false, 'message' => 'HTTP ' . $response->status()];
      }

      $data = $response->json();
      $status = $data['status'] ?? '';
      if ($status !== 'OK') {
        return ['ok' => false, 'message' => $data['error_message'] ?? $status];
      }

      $results = $data['results'] ?? [];
      if (empty($results)) {
        return ['ok' => false, 'message' => 'Sin resultados de geocodificación.'];
      }

      return ['ok' => true, 'message' => 'Geocoding API operativa.'];
    } catch (\Throwable $e) {
      return ['ok' => false, 'message' => $e->getMessage()];
    }
  }

  private function checkDirections(): array
  {
    $apiKey = config('services.google.directions.api_key', '');
    if ($apiKey === '') {
      return ['ok' => false, 'message' => 'GOOGLE_MAPS_API_KEY o GOOGLE_DIRECTIONS_API_KEY no configurada.'];
    }

    try {
      $response = Http::get(self::DIRECTIONS_URL, [
        'origin' => self::ORIGIN,
        'destination' => self::DESTINATION,
        'mode' => 'driving',
        'key' => $apiKey,
      ]);

      if (!$response->successful()) {
        return ['ok' => false, 'message' => 'HTTP ' . $response->status()];
      }

      $data = $response->json();
      $status = $data['status'] ?? '';
      if ($status !== 'OK') {
        return ['ok' => false, 'message' => $data['error_message'] ?? $status];
      }

      $routes = $data['routes'] ?? [];
      if (empty($routes)) {
        return ['ok' => false, 'message' => 'Directions sin rutas.'];
      }

      return ['ok' => true, 'message' => 'Directions API operativa.'];
    } catch (\Throwable $e) {
      return ['ok' => false, 'message' => $e->getMessage()];
    }
  }

  private function checkDirectionsPolyline(): array
  {
    $apiKey = config('services.google.directions.api_key', '');
    if ($apiKey === '') {
      return ['ok' => false, 'message' => 'Clave de Directions no configurada.'];
    }

    try {
      $response = Http::get(self::DIRECTIONS_URL, [
        'origin' => self::ORIGIN,
        'destination' => self::DESTINATION,
        'mode' => 'driving',
        'key' => $apiKey,
      ]);

      $data = $response->json();
      if (($data['status'] ?? '') !== 'OK') {
        return ['ok' => false, 'message' => $data['error_message'] ?? 'Directions no OK.'];
      }

      $route = $data['routes'][0] ?? null;
      if (!$route) {
        return ['ok' => false, 'message' => 'No hay ruta en la respuesta.'];
      }

      $polyline = $route['overview_polyline']['points'] ?? null;
      if ($polyline === null || $polyline === '') {
        return ['ok' => false, 'message' => 'La ruta no incluye overview_polyline (polylines no disponibles).'];
      }

      $length = strlen($polyline);
      return [
        'ok' => true,
        'message' => 'Polylines operativos.',
        'polyline_length' => $length,
      ];
    } catch (\Throwable $e) {
      return ['ok' => false, 'message' => $e->getMessage()];
    }
  }

  private function checkRouteOptimization(): array
  {
    $credentialsPath = config('services.google.route_optimization.credentials');
    $projectId = config('services.google.route_optimization.project_id');

    if (empty($projectId)) {
      return ['ok' => false, 'message' => 'GOOGLE_ROUTE_OPTIMIZATION_PROJECT_ID no configurado.'];
    }

    $fullPath = $credentialsPath ? base_path($credentialsPath) : null;
    if (!$fullPath || !is_readable($fullPath)) {
      return ['ok' => false, 'message' => 'Archivo de credenciales (service account) no encontrado o no legible: ' . ($credentialsPath ?: 'no definido')];
    }

    try {
      new RouteOptimizationClient([
        'credentials' => $fullPath,
      ]);
      return ['ok' => true, 'message' => 'Credenciales de Route Optimization válidas (cliente instanciado).'];
    } catch (\Throwable $e) {
      return ['ok' => false, 'message' => $e->getMessage()];
    }
  }
}

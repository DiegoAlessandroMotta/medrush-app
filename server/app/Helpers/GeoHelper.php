<?php

namespace App\Helpers;

class GeoHelper
{
  const LOCATION_LIMA = [
    'latitude' => -12.0468674443,
    'longitude' => -77.0430064768,
  ];

  const LOCATION_ORLANDO = [
    'latitude' => 28.542425054147497,
    'longitude' => -81.38308292989419,
  ];

  const EARTH_RADIUS_KM = 6371;
  const DEFAULT_MIN_CORRELATED_DISTANCE_KM = 0.05;
  const DEFAULT_MAX_CORRELATED_DISTANCE_KM = 0.20;
  const DEFAULT_MIN_CORRELATED_ANGLE_CHANGE_DEG = -45;
  const DEFAULT_MAX_CORRELATED_ANGLE_CHANGE_DEG = 45;
  const DECIMAL_PRECISION = 10;

  /**
   * Genera un punto de destino dada una latitud/longitud de origen, una distancia y un rumbo.
   * Utiliza la fórmula de la Tierra Esférica para cálculos de geodésica.
   *
   * @param array{latitude: float, longitude: float} $point Punto de origen.
   * @param float $distance Distancia a moverse en kilómetros.
   * @param float $bearing Rumbo (ángulo) en grados (0-360, Norte=0, Este=90).
   * @return array{latitude: float, longitude: float}
   */
  public static function calculateDestinationPoint(
    array $point,
    float $distance,
    float $bearing
  ): array {
    $lat1Rad = deg2rad($point['latitude']);
    $lon1Rad = deg2rad($point['longitude']);
    $bearingRad = deg2rad($bearing);

    $lat2Rad = asin(
      sin($lat1Rad) * cos($distance / self::EARTH_RADIUS_KM) +
        cos($lat1Rad) * sin($distance / self::EARTH_RADIUS_KM) * cos($bearingRad)
    );

    $lon2Rad = $lon1Rad + atan2(
      sin($bearingRad) * sin($distance / self::EARTH_RADIUS_KM) * cos($lat1Rad),
      cos($distance / self::EARTH_RADIUS_KM) - sin($lat1Rad) * sin($lat2Rad)
    );

    $lat2 = rad2deg($lat2Rad);
    $lon2 = rad2deg($lon2Rad);

    return [
      'latitude' => self::truncateDecimals($lat2, self::DECIMAL_PRECISION),
      'longitude' => self::truncateDecimals($lon2, self::DECIMAL_PRECISION),
    ];
  }

  /**
   * Genera una ubicación aleatoria dentro de un radio máximo de un punto de origen.
   *
   * @param array{latitude: float, longitude: float} $point Punto de origen en grados.
   * @param float|null $maxRadiusKm Radio máximo en kilómetros.
   * @return array{latitude: float, longitude: float}
   */
  public static function generateRandomPointInRadius(
    array $point = self::LOCATION_LIMA,
    ?float $maxRadiusKm = 5
  ): array {
    $bearing = self::getRandomBearing();

    $distance = sqrt(mt_rand() / mt_getrandmax()) * $maxRadiusKm;

    $destinationPoint = self::calculateDestinationPoint($point, $distance, $bearing);

    return $destinationPoint;
  }

  /**
   * Genera el siguiente punto geográfico correlacionado basándose en un punto actual
   * y un rumbo previo. Esto es útil para simular un movimiento secuencial.
   *
   * @param array{latitude: float, longitude: float} $currentPoint
   * @param float $previousBearing
   * @param float $minCorrelatedDistanceKm
   * @param float $maxCorrelatedDistanceKm
   * @param float $minCorrelatedAngleChangeDeg
   * @param float $maxCorrelatedAngleChangeDeg
   * @return array{latitude: float, longitude: float, bearing: float}
   */
  public static function generateNextCorrelatedPoint(
    array $currentPoint,
    float $previousBearing,
    float $minCorrelatedDistanceKm = self::DEFAULT_MIN_CORRELATED_DISTANCE_KM,
    float $maxCorrelatedDistanceKm = self::DEFAULT_MAX_CORRELATED_DISTANCE_KM,
    float $minCorrelatedAngleChangeDeg = self::DEFAULT_MIN_CORRELATED_ANGLE_CHANGE_DEG,
    float $maxCorrelatedAngleChangeDeg = self::DEFAULT_MAX_CORRELATED_ANGLE_CHANGE_DEG
  ): array {
    $distance = self::getRandomFloat($minCorrelatedDistanceKm, $maxCorrelatedDistanceKm);
    $angleChange = self::getRandomFloat($minCorrelatedAngleChangeDeg, $maxCorrelatedAngleChangeDeg);
    $newBearing = ($previousBearing + $angleChange + 360) % 360;

    $nextPoint = self::calculateDestinationPoint($currentPoint, $distance, $newBearing);

    return array_merge($nextPoint, [
      'bearing' => self::truncateDecimals($newBearing, self::DECIMAL_PRECISION),
    ]);
  }

  /**
   * Genera una serie de puntos geográficos correlacionados, simulando un movimiento.
   * El primer punto se genera aleatoriamente en un radio, y los subsiguientes
   * se generan a partir del último punto con una distancia y un cambio de rumbo aleatorios.
   *
   * @param int $numberOfPoints Número de puntos a generar.
   * @param array{latitude: float, longitude: float} $initialLocation
   * @param float $initialRadiusKm
   * @param float $minCorrelatedDistanceKm
   * @param float $maxCorrelatedDistanceKm
   * @param float $minCorrelatedAngleChangeDeg
   * @param float $maxCorrelatedAngleChangeDeg
   * @return array<array{latitude: float, longitude: float}>
   */
  public static function generateCorrelatedPoints(
    int $numberOfPoints,
    array $initialLocation = self::LOCATION_LIMA,
    float $initialRadiusKm = 5,
    float $minCorrelatedDistanceKm = self::DEFAULT_MIN_CORRELATED_DISTANCE_KM,
    float $maxCorrelatedDistanceKm = self::DEFAULT_MAX_CORRELATED_DISTANCE_KM,
    float $minCorrelatedAngleChangeDeg = self::DEFAULT_MIN_CORRELATED_ANGLE_CHANGE_DEG,
    float $maxCorrelatedAngleChangeDeg = self::DEFAULT_MAX_CORRELATED_ANGLE_CHANGE_DEG
  ): array {
    if ($numberOfPoints <= 0) {
      return [];
    }

    $points = [];
    $lastPoint = [];
    $currentBearing = self::getRandomBearing();

    $lastPoint = self::generateRandomPointInRadius($initialLocation, $initialRadiusKm);
    $points[] = $lastPoint;

    for ($i = 1; $i < $numberOfPoints; $i++) {
      $nextData = self::generateNextCorrelatedPoint(
        $lastPoint,
        $currentBearing,
        $minCorrelatedDistanceKm,
        $maxCorrelatedDistanceKm,
        $minCorrelatedAngleChangeDeg,
        $maxCorrelatedAngleChangeDeg
      );

      $currentBearing = $nextData['bearing'];
      unset($nextData['bearing']);

      $points[] = $nextData;
      $lastPoint = $nextData;
    }

    return $points;
  }

  /**
   * Genera un número flotante aleatorio entre un mínimo y un máximo.
   *
   * @param float $min
   * @param float $max
   * @return float
   */
  private static function getRandomFloat(float $min, float $max): float
  {
    return $min + mt_rand() / mt_getrandmax() * ($max - $min);
  }

  /**
   * Genera un rumbo aleatorio.
   *
   * @return float
   */
  public static function getRandomBearing(): float
  {
    return mt_rand(0, 35999) / 100;
  }

  /**
   * Trunca un número flotante a una cantidad específica de decimales.
   *
   * @param float $value El valor a truncar.
   * @param int $precision La cantidad de decimales a mantener.
   * @return float El valor truncado.
   */
  private static function truncateDecimals(float $value, int $precision): float
  {
    return round($value, $precision, PHP_ROUND_HALF_DOWN);
  }
}

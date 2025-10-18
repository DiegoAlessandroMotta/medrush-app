<?php

namespace App\Helpers;

final class PrepareData
{
  /**
   * @return array{latitude: float, longitude: float}
   */
  public static function location(mixed $locationData): ?array
  {
    if (is_string($locationData)) {
      $valuesArray = explode(',', $locationData);

      if (count($valuesArray) < 2) {
        return null;
      }

      $latitudeString = trim($valuesArray[0]);
      $longitudeString = trim($valuesArray[1]);

      if (!is_numeric($latitudeString) || !is_numeric($longitudeString)) {
        return null;
      }

      $latitude = (float) trim($latitudeString);
      $longitude = (float) trim($longitudeString);

      return [
        'latitude' => $latitude,
        'longitude' => $longitude
      ];
    }

    if (is_array($locationData)) {
      $latitude = isset($locationData['latitude']) ? $locationData['latitude'] : null;
      $longitude = isset($locationData['longitude']) ? $locationData['longitude'] : null;

      return [
        'latitude' => $latitude,
        'longitude' => $longitude
      ];
    }

    return null;
  }

  public static function boolean(mixed $value): bool
  {
    if (is_bool($value)) {
      return $value;
    }

    if (is_string($value)) {
      $value = strtolower(trim($value));

      $trueValues = ['true', 'yes', 'si', 'sí', 's', '1', 'verdadero', 'on', 'active', 'activo'];

      return in_array($value, $trueValues);
    }

    if (is_numeric($value)) {
      return $value === 1;
    }

    return false;
  }
}

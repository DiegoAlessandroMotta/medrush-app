<?php

namespace App\Services\Geocoding;

use App\DTOs\GeocodingResultDTO;
use App\Exceptions\CustomException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeocodingService
{
  private const API_BASE_ENDPOINT = 'https://maps.googleapis.com/maps/api/geocode/json';
  private string $apiKey;

  public function __construct()
  {
    $this->apiKey = config('services.google.geocoding.api_key', '');

    if (empty($this->apiKey)) {
      throw CustomException::serviceUnavailable();
    }
  }

  public function reverseGeocode(float $latitude, float $longitude): ?GeocodingResultDTO
  {
    $cacheKey = $this->generateCacheKey($latitude, $longitude);

    $cachedResult = Cache::get($cacheKey);
    if ($cachedResult !== null) {
      return $cachedResult;
    }

    try {
      $response = Http::get(self::API_BASE_ENDPOINT, [
        'latlng' => "{$latitude},{$longitude}",
        'key' => $this->apiKey,
        'language' => 'es',
        'region' => 'pe',
      ]);

      if (!$response->successful() || !$response->json()) {
        Log::error("Error en respuesta de Geocoding API", [
          'status' => $response->status()
        ]);
        return null;
      }

      $data = $response->json();

      if ($data['status'] !== 'OK') {
        Log::error("Error en Geocoding API: {$data['status']} - " . ($data['error_message'] ?? ''));
        return null;
      }

      $results = $data['results'] ?? [];
      if (empty($results)) {
        Log::error('No se encontraron resultados de geocodificación');
        return null;
      }

      $result = $results[0];
      $addressComponents = $result['address_components'] ?? [];
      Log::info($results);

      $geocodingResult = $this->parseAddressComponents($addressComponents, $result);

      Cache::put($cacheKey, $geocodingResult, now()->addHours(24));

      return $geocodingResult;
    } catch (\Exception $e) {
      Log::error('Error en geocodificación inversa', ['error' => $e->getMessage()]);
      return null;
    }
  }

  private function generateCacheKey(float $latitude, float $longitude): string
  {
    $roundedLat = round($latitude, 6);
    $roundedLng = round($longitude, 6);

    return "geocoding:reverse:{$roundedLat}:{$roundedLng}";
  }

  private function parseAddressComponents(array $components, array $result): GeocodingResultDTO
  {
    $streetNumber = '';
    $route = '';
    $sublocality = '';
    $locality = '';
    $administrativeAreaLevel1 = '';
    $administrativeAreaLevel2 = '';
    $country = '';
    $postalCode = '';
    $formattedAddress = $result['formatted_address'] ?? '';

    foreach ($components as $component) {
      $types = $component['types'] ?? [];
      $longName = $component['long_name'] ?? '';

      if (in_array('street_number', $types)) {
        $streetNumber = $longName;
      } elseif (in_array('route', $types)) {
        $route = $longName;
      } elseif (in_array('sublocality', $types) || in_array('sublocality_level_1', $types)) {
        $sublocality = $longName;
      } elseif (in_array('locality', $types)) {
        $locality = $longName;
      } elseif (in_array('administrative_area_level_1', $types)) {
        $administrativeAreaLevel1 = $longName;
      } elseif (in_array('administrative_area_level_2', $types)) {
        $administrativeAreaLevel2 = $longName;
      } elseif (in_array('country', $types)) {
        $country = $longName;
      } elseif (in_array('postal_code', $types)) {
        $postalCode = $longName;
      }
    }

    $addressLine1 = '';
    if (!empty($streetNumber) && !empty($route)) {
      $addressLine1 = "{$streetNumber} {$route}";
    } elseif (!empty($route)) {
      $addressLine1 = $route;
    } elseif (!empty($streetNumber)) {
      $addressLine1 = $streetNumber;
    }

    $city = '';
    if (!empty($locality)) {
      $city = $locality;
    } elseif (!empty($sublocality)) {
      $city = $sublocality;
    } elseif (!empty($administrativeAreaLevel2)) {
      $city = $administrativeAreaLevel2;
    }

    $state = $administrativeAreaLevel1;

    return new GeocodingResultDTO(
      addressLine1: $addressLine1,
      city: $city,
      state: $state,
      postalCode: $postalCode,
      country: $country,
      formattedAddress: $formattedAddress
    );
  }
}

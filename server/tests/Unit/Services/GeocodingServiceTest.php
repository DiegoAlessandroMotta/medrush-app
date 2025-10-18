<?php

namespace Tests\Unit\Services;

use App\DTOs\GeocodingResultDTO;
use App\Services\Geocoding\GeocodingService;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GeocodingServiceTest extends TestCase
{
  public function testReverseGeocodeSuccess()
  {
    // Arrange
    $latitude = -12.0464;
    $longitude = -77.0428;

    $mockResponse = [
      'status' => 'OK',
      'results' => [
        [
          'formatted_address' => 'Av. Javier Prado Este 4200, San Isidro 15036, Perú',
          'address_components' => [
            [
              'long_name' => '4200',
              'types' => ['street_number']
            ],
            [
              'long_name' => 'Avenida Javier Prado Este',
              'types' => ['route']
            ],
            [
              'long_name' => 'San Isidro',
              'types' => ['locality']
            ],
            [
              'long_name' => 'Lima',
              'types' => ['administrative_area_level_1']
            ],
            [
              'long_name' => 'Perú',
              'types' => ['country']
            ],
            [
              'long_name' => '15036',
              'types' => ['postal_code']
            ]
          ]
        ]
      ]
    ];

    Http::fake([
      'maps.googleapis.com/*' => Http::response($mockResponse, 200)
    ]);

    // Act
    $service = new GeocodingService();
    $result = $service->reverseGeocode($latitude, $longitude);

    // Assert
    $this->assertInstanceOf(GeocodingResultDTO::class, $result);
    $this->assertEquals('4200 Avenida Javier Prado Este', $result->addressLine1);
    $this->assertEquals('San Isidro', $result->city);
    $this->assertEquals('Lima', $result->state);
    $this->assertEquals('15036', $result->postalCode);
    $this->assertEquals('Perú', $result->country);
    $this->assertEquals('Av. Javier Prado Este 4200, San Isidro 15036, Perú', $result->formattedAddress);
  }

  public function testReverseGeocodeFailure()
  {
    // Arrange
    $latitude = -12.0464;
    $longitude = -77.0428;

    Http::fake([
      'maps.googleapis.com/*' => Http::response(['status' => 'ZERO_RESULTS'], 200)
    ]);

    // Act
    $service = new GeocodingService();
    $result = $service->reverseGeocode($latitude, $longitude);

    // Assert
    $this->assertNull($result);
  }

  public function testReverseGeocodeApiError()
  {
    // Arrange
    $latitude = -12.0464;
    $longitude = -77.0428;

    Http::fake([
      'maps.googleapis.com/*' => Http::response(['error' => 'API Error'], 500)
    ]);

    // Act
    $service = new GeocodingService();
    $result = $service->reverseGeocode($latitude, $longitude);

    // Assert
    $this->assertNull($result);
  }
}

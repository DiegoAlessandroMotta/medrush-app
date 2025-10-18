<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GeocodingControllerTest extends TestCase
{
  use RefreshDatabase;

  private User $user;

  protected function setUp(): void
  {
    parent::setUp();

    $this->user = User::factory()->create();
  }

  public function testReverseGeocodeSuccess()
  {
    // Arrange
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
    $token = $this->user->createToken('test-token')->plainTextToken;

    $response = $this->withHeaders([
      'Authorization' => 'Bearer ' . $token,
    ])->postJson('/api/geocoding/reverse', [
      'latitude' => -12.0464,
      'longitude' => -77.0428,
    ]);    // Assert
    $response->assertStatus(200)
      ->assertJson([
        'success' => true,
        'message' => 'Geocodificación exitosa',
        'data' => [
          'address_line_1' => '4200 Avenida Javier Prado Este',
          'city' => 'San Isidro',
          'state' => 'Lima',
          'postal_code' => '15036',
          'country' => 'Perú',
          'formatted_address' => 'Av. Javier Prado Este 4200, San Isidro 15036, Perú'
        ]
      ]);
  }

  public function testReverseGeocodeValidationError()
  {
    // Act
    $token = $this->user->createToken('test-token')->plainTextToken;

    $response = $this->withHeaders([
      'Authorization' => 'Bearer ' . $token,
    ])->postJson('/api/geocoding/reverse', [
      'latitude' => 'invalid',
      'longitude' => -77.0428,
    ]);    // Assert
    $response->assertStatus(400)
      ->assertJson([
        'success' => false,
        'message' => 'Datos de entrada inválidos',
      ]);
  }

  public function testReverseGeocodeUnauthorized()
  {
    // Act
    $response = $this->postJson('/api/geocoding/reverse', [
      'latitude' => -12.0464,
      'longitude' => -77.0428,
    ]);

    // Assert
    $response->assertStatus(401);
  }

  public function testReverseGeocodeMissingParameters()
  {
    // Act
    $token = $this->user->createToken('test-token')->plainTextToken;

    $response = $this->withHeaders([
      'Authorization' => 'Bearer ' . $token,
    ])->postJson('/api/geocoding/reverse', [
      'latitude' => -12.0464,
      // Missing longitude
    ]);    // Assert
    $response->assertStatus(400)
      ->assertJson([
        'success' => false,
        'message' => 'Datos de entrada inválidos',
      ]);
  }

  public function testReverseGeocodeOutOfRangeCoordinates()
  {
    // Act
    $token = $this->user->createToken('test-token')->plainTextToken;

    $response = $this->withHeaders([
      'Authorization' => 'Bearer ' . $token,
    ])->postJson('/api/geocoding/reverse', [
      'latitude' => 200, // Out of range
      'longitude' => -77.0428,
    ]);    // Assert
    $response->assertStatus(400)
      ->assertJson([
        'success' => false,
        'message' => 'Datos de entrada inválidos',
      ]);
  }
}

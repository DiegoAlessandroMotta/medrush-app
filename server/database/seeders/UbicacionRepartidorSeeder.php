<?php

namespace Database\Seeders;

use App\Helpers\GeoHelper;
use App\Models\UbicacionRepartidor;
use App\Models\User;
use Illuminate\Database\Seeder;
use MatanYadaev\EloquentSpatial\Objects\Point;
use MatanYadaev\EloquentSpatial\Enums\Srid;

class UbicacionRepartidorSeeder extends Seeder
{
  public function run(): void
  {
    $repartidores = User::factory(2)->repartidor()->create();

    foreach ($repartidores as $repartidor) {
      $initialPoint = GeoHelper::generateRandomPointInRadius();
      $points = GeoHelper::generateCorrelatedPoints(
        numberOfPoints: 100,
        initialLocation: $initialPoint,
        initialRadiusKm: 2,
        minCorrelatedDistanceKm: 0.1,
        maxCorrelatedDistanceKm: 0.3
      );

      foreach ($points as $index => $point) {
        UbicacionRepartidor::create([
          'repartidor_id' => $repartidor->id,
          'ubicacion' => new Point($point['latitude'], $point['longitude'], Srid::WGS84),
          'precision_m' => fake()->randomFloat(2, 5, 50),
          'velocidad_ms' => fake()->randomFloat(2, 0, 15),
          'direccion' => fake()->randomFloat(2, 0, 360),
          'fecha_registro' => now()->subMinutes(20 - $index),
        ]);
      }
    }
  }
}

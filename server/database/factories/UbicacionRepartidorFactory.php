<?php

namespace Database\Factories;

use App\Casts\AsPoint;
use App\Helpers\GeoHelper;
use App\Models\PerfilRepartidor;
use App\Models\UbicacionRepartidor;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\UbicacionRepartidor>
 */
class UbicacionRepartidorFactory extends Factory
{
  protected $model = UbicacionRepartidor::class;

  public function definition(): array
  {
    $point = GeoHelper::generateRandomPointInRadius();
    $bearing = GeoHelper::getRandomBearing();

    return [
      'repartidor_id' => PerfilRepartidor::factory(),
      'pedido_id' => null,
      'ruta_id' => null,
      'ubicacion' => AsPoint::pointFromArray($point),
      'precision_m' => $this->faker->randomFloat(2, 5, 50),
      'velocidad_ms' => $this->faker->randomFloat(2, 0, 15),
      'direccion' => $bearing,
      'fecha_registro' => now(),
    ];
  }
}

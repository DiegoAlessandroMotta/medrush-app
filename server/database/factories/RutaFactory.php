<?php

namespace Database\Factories;

use App\Casts\AsPoint;
use App\Helpers\GeoHelper;
use App\Models\PerfilRepartidor;
use App\Models\Ruta;
use Faker\Factory as FakerFactory;
use MatanYadaev\EloquentSpatial\Enums\Srid;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Ruta>
 */
class RutaFactory extends Factory
{
  protected $model = Ruta::class;

  public function definition(): array
  {
    $faker = FakerFactory::create('es_PE');

    /** @var PerfilRepartidor $repartidor */
    $repartidor = PerfilRepartidor::first() ?? PerfilRepartidor::factory()->create();

    $startLocation = GeoHelper::generateRandomPointInRadius();
    $endLocation = GeoHelper::generateRandomPointInRadius();

    return [
      'repartidor_id' => $repartidor->id,
      'nombre' => 'Ruta ' . $faker->city . ' - ' . $faker->dayOfWeek,
      'punto_inicio' => AsPoint::fromArray($startLocation, Srid::WGS84),
      'punto_final' => AsPoint::fromArray($endLocation, Srid::WGS84),
      'polyline_encoded' => null,
      'distancia_total_estimada' => $faker->numberBetween(12000, 30000),
      'tiempo_total_estimado' => $faker->numberBetween(3600 * 2, 3600 * 6),
      'cantidad_pedidos' => null,
      'fecha_hora_calculo' => null,
      'fecha_inicio' => null,
      'fecha_completado' => null,
    ];
  }

  public function forRepartidor(PerfilRepartidor $repartidor): static
  {
    return $this->state(fn(array $attributes) => [
      'repartidor_id' => $repartidor->id,
    ]);
  }

  public function iniciada(): static
  {
    return $this->state(fn(array $attributes) => [
      'fecha_inicio' => now()->subHours(fake()->numberBetween(1, 5)),
    ]);
  }

  public function completada(): static
  {
    return $this->state(function (array $attributes) {
      $fechaInicio = $attributes['fecha_inicio'] ?? now()->subHours(fake()->numberBetween(5, 10));
      return [
        'fecha_inicio' => $fechaInicio,
        'fecha_completado' => $fechaInicio->addMinutes(fake()->numberBetween(60, 240)),
      ];
    });
  }
}

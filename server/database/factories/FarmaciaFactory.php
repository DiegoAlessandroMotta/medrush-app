<?php

namespace Database\Factories;

use App\Casts\AsPoint;
use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosFarmaciaEnum;
use App\Helpers\GeoHelper;
use App\Models\Farmacia;
use Faker\Factory as FakerFactory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Farmacia>
 */
class FarmaciaFactory extends Factory
{
  protected $model = Farmacia::class;

  public function definition(): array
  {
    $faker = FakerFactory::create('es_PE');
    $companyName = $this->faker->company;
    $randomLocation = GeoHelper::generateRandomPointInRadius();

    return [
      'nombre' => $companyName,
      'razon_social' => $companyName . ' S.A.C.',
      'ruc_ein' => $faker->unique()->numerify('20#########'),
      'direccion_linea_1' => $faker->streetAddress,
      'direccion_linea_2' => $this->faker->boolean(30) ? $faker->secondaryAddress : null,
      'ciudad' => $faker->city,
      'estado_region' => $faker->state,
      'codigo_postal' => $faker->numberBetween(1, 51),
      'codigo_iso_pais' => CodigosIsoPaisEnum::PERU,
      'ubicacion' => AsPoint::fromArray($randomLocation, \MatanYadaev\EloquentSpatial\Enums\Srid::WGS84),
      'telefono' => '+51' . $faker->numerify('#########'),
      'email' => $this->faker->unique()->companyEmail,
      'contacto_responsable' => $faker->name,
      'telefono_responsable' => '+51' . $faker->numerify('#########'),
      'cadena' => $this->faker->randomElement(['Inkafarma', 'Mifarma', 'Boticas & Salud', 'Boticas Felicidad', null]),
      'horario_atencion' => $this->faker->randomElement([
        '08:00-22:00',
        '07:00-23:00',
        '24/7',
        '09:00-21:00',
      ]),
      'delivery_24h' => $this->faker->boolean(30),
      'estado' => $this->faker->randomElement(EstadosFarmaciaEnum::cases()),
    ];
  }
}

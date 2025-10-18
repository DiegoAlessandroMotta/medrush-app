<?php

namespace Database\Factories;

use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosRepartidorEnum;
use App\Enums\RolesEnum;
use App\Models\Farmacia;
use App\Models\PerfilFarmacia;
use App\Models\PerfilRepartidor;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
  protected static ?string $password;
  protected $model = User::class;

  public function definition(): array
  {
    $originalEmail = fake()->unique()->safeEmail();
    $parts = explode('@', $originalEmail);
    $localPart = $parts[0];
    $domainPart = $parts[1];

    $modifiedLocalPart = str_replace('.', '_', $localPart);

    $email = $modifiedLocalPart . '@' . $domainPart;

    return [
      'name' => fake()->name(),
      'email' => $email,
      'email_verified_at' => now(),
      'password' => static::$password ??= Hash::make('password'),
      'remember_token' => Str::random(10),
      'is_active' => true
    ];
  }

  public function unverified(): static
  {
    return $this->state(fn(array $attributes) => [
      'email_verified_at' => null,
    ]);
  }

  public function administrador(): static
  {
    return $this->state([])
      ->afterCreating(function (User $user) {
        $user->assignRole(RolesEnum::ADMINISTRADOR);
      });
  }

  public function repartidor(): static
  {
    return $this->state([])
      ->afterCreating(function (User $user) {
        $faker = \Faker\Factory::create('es_PE');
        $marcasVehiculo = ['Toyota', 'Honda', 'Yamaha', 'Suzuki', 'Bajaj', 'Hero', 'TVS', 'KTM', 'Royal Enfield'];
        $modelosVehiculo = ['Wave', 'CG', 'GL', 'XR', 'NXR', 'YBR', 'FZ', 'Pulsar', 'Apache', 'Duke'];

        PerfilRepartidor::create([
          'id' => $user->id,
          'farmacia_id' => null,
          'codigo_iso_pais' => CodigosIsoPaisEnum::PERU,
          'dni_id_numero' => $faker->numerify('########'),
          // 'dni_id_imagen_url' => $faker->imageUrl(640, 480, 'document'),
          'telefono' => '+51' . $faker->numerify('#########'),
          'licencia_numero' => 'Q' . $faker->numerify('#######'),
          'licencia_vencimiento' => $faker->dateTimeBetween('+1 year', '+5 years'),
          // 'licencia_imagen_url' => $faker->imageUrl(640, 480, 'license'),
          // 'seguro_vehiculo_url' => $faker->imageUrl(640, 480, 'insurance'),
          'vehiculo_placa' => fake()->unique()->regexify('[A-Z]{3}-[0-9]{3}'),
          'vehiculo_marca' => $faker->randomElement($marcasVehiculo),
          'vehiculo_modelo' => $faker->randomElement($modelosVehiculo) . ' ' . $faker->numberBetween(110, 250),
          'estado' => EstadosRepartidorEnum::DISPONIBLE,
          'verificado' => false,
        ]);

        $user->assignRole(RolesEnum::REPARTIDOR);
      });
  }

  public function farmacia(): static
  {
    return $this->state([])
      ->afterCreating(function (User $user) {
        $farmacia = Farmacia::first();
        if (!$farmacia) {
          $farmacia = Farmacia::factory()->create();
        }

        PerfilFarmacia::create([
          'id' => $user->id,
          'farmacia_id' => $farmacia->id,
        ]);

        $user->assignRole(RolesEnum::FARMACIA);
      });
  }
}

<?php

namespace Database\Seeders;

use App;
use App\Enums\RolesEnum;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
  /**
   * Run the database seeds.
   */
  public function run(): void
  {
    $email = config('custom.admin.email');
    /** @var User $user */
    $user = User::firstOrCreate(
      ['email' => $email],
      [
        'name' => 'Administrador',
        'password' => Hash::make(config('custom.admin.password')),
      ]
    );

    if (!$user->hasRole(RolesEnum::ADMINISTRADOR)) {
      $user->assignRole(RolesEnum::ADMINISTRADOR);
    }

    if (!App::isProduction()) {
      User::factory()
        ->repartidor()
        ->create([
          'name' => 'Repartidor',
          'email' => 'repartidor@example.com',
          'password' => Hash::make('password')
        ]);

      User::factory()
        ->repartidor()
        ->count(10)
        ->create();

      User::factory()
        ->farmacia()
        ->create([
          'name' => 'Farmacia',
          'email' => 'farmacia@example.com',
          'password' => Hash::make('password')
        ]);

      User::factory()
        ->farmacia()
        ->count(5)
        ->create();
    }
  }
}

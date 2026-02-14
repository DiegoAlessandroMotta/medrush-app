<?php

namespace Database\Seeders;

use App;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
  /**
   * Seed the application's database.
   */
  public function run(): void
  {
    $this->call([
      RolesPermissionSeeder::class,
      UserSeeder::class,
    ]);

    if (!App::isProduction()) {
      $this->call([
        FarmaciaSeeder::class,
        UbicacionRepartidorSeeder::class,
      ]);
    }
  }
}

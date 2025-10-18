<?php

namespace Database\Seeders;

use App\Enums\GoogleApiServiceType;
use App\Models\GoogleApiUsage;
use App\Models\User;
use Illuminate\Database\Seeder;

class GoogleApiUsageSeeder extends Seeder
{
  public function run(): void
  {
    if (User::count() === 0) {
      User::factory()->count(5)->create();
    }

    GoogleApiUsage::factory()
      ->withType(GoogleApiServiceType::ROUTE_OPTIMIZATION_FLEETROUTING)
      ->currentMonth()
      ->count(rand(50, 150))
      ->create();

    $lastMonth = now()->subMonth();
    GoogleApiUsage::factory()
      ->withType(GoogleApiServiceType::ROUTE_OPTIMIZATION_FLEETROUTING)
      ->forMonth($lastMonth->year, $lastMonth->month)
      ->count(rand(80, 200))
      ->create();

    $twoMonthsAgo = now()->subMonths(2);
    GoogleApiUsage::factory()
      ->withType(GoogleApiServiceType::ROUTE_OPTIMIZATION_FLEETROUTING)
      ->forMonth($twoMonthsAgo->year, $twoMonthsAgo->month)
      ->count(rand(30, 100))
      ->create();

    $this->command->info('Generando datos históricos para el último año...');
    for ($i = 3; $i <= 12; $i++) {
      $historicalDate = now()->subMonths($i);
      GoogleApiUsage::factory()
        ->forMonth($historicalDate->year, $historicalDate->month)
        ->count(rand(20, 80))
        ->create();
    }

    $firstUser = User::first();
    if ($firstUser) {
      $this->command->info("Generando datos específicos para el usuario: {$firstUser->email}...");
      GoogleApiUsage::factory()
        ->forUser($firstUser)
        ->withType(GoogleApiServiceType::ROUTE_OPTIMIZATION_FLEETROUTING)
        ->currentMonth()
        ->count(rand(10, 25))
        ->create();
    }
  }
}

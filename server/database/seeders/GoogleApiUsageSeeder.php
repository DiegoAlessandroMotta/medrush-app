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
    foreach (GoogleApiServiceType::cases() as $serviceType) {
      GoogleApiUsage::factory()
        ->withType($serviceType)
        ->currentMonth()
        ->count(rand(50, 150))
        ->create();

      $lastMonth = now()->subMonth();
      GoogleApiUsage::factory()
        ->withType($serviceType)
        ->forMonth($lastMonth->year, $lastMonth->month)
        ->count(rand(80, 200))
        ->create();

      $twoMonthsAgo = now()->subMonths(2);
      GoogleApiUsage::factory()
        ->withType($serviceType)
        ->forMonth($twoMonthsAgo->year, $twoMonthsAgo->month)
        ->count(rand(30, 100))
        ->create();

      for ($i = 3; $i <= 12; $i++) {
        $historicalDate = now()->subMonths($i);
        GoogleApiUsage::factory()
          ->forMonth($historicalDate->year, $historicalDate->month)
          ->count(rand(20, 80))
          ->create();
      }
    }
  }
}

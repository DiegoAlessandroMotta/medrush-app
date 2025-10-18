<?php

namespace Database\Seeders;

use App\Models\Farmacia;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class FarmaciaSeeder extends Seeder
{
  /**
   * Run the database seeds.
   */
  public function run(): void
  {
    Farmacia::factory()->count(3)->create();
  }
}

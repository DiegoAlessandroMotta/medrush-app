<?php

namespace Database\Factories;

use App\Enums\GoogleApiServiceType;
use App\Models\GoogleApiUsage;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\GoogleApiUsage>
 */
class GoogleApiUsageFactory extends Factory
{
  protected $model = GoogleApiUsage::class;

  public function definition(): array
  {
    return [
      'user_id' => User::inRandomOrder()->first()?->id ?? User::factory(),
      'type' => fake()->randomElement(GoogleApiServiceType::cases()),
      'created_at' => fake()->dateTimeBetween('-1 year', 'now'),
      'updated_at' => now(),
    ];
  }

  public function withType(GoogleApiServiceType $type): static
  {
    return $this->state(fn(array $attributes) => [
      'type' => $type,
    ]);
  }

  public function currentMonth(): static
  {
    return $this->state(fn(array $attributes) => [
      'created_at' => fake()->dateTimeBetween(now()->startOfMonth(), now()),
    ]);
  }

  public function forMonth(int $year, int $month): static
  {
    $startDate = Carbon::create($year, $month, 1)->startOfMonth();
    $endDate = Carbon::create($year, $month, 1)->endOfMonth();

    return $this->state(fn(array $attributes) => [
      'created_at' => fake()->dateTimeBetween($startDate, $endDate),
    ]);
  }

  public function forUser(User $user): static
  {
    return $this->state(fn(array $attributes) => [
      'user_id' => $user->id,
    ]);
  }
}

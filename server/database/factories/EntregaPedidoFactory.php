<?php

namespace Database\Factories;

use App\Models\EntregaPedido;
use App\Models\Pedido;
use App\Models\Ruta;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\EntregaPedido>
 */
class EntregaPedidoFactory extends Factory
{
  protected $model = EntregaPedido::class;

  public function definition(): array
  {
    return [
      'ruta_id' => null,
      'pedido_id' => null,
      'orden_optimizado' => $this->faker->numberBetween(1, 10),
      'orden_personalizado' => null,
    ];
  }

  public function forPedido(Pedido $pedido): static
  {
    return $this->state(fn(array $attributes) => [
      'pedido_id' => $pedido->id,
    ]);
  }

  public function forRuta(Ruta $ruta): static
  {
    return $this->state(fn(array $attributes) => [
      'ruta_id' => $ruta->id,
    ]);
  }
}

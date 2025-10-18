<?php

namespace Database\Seeders;

use App\Enums\EstadosPedidoEnum;
use App\Models\EntregaPedido;
use App\Models\Pedido;
use App\Models\Ruta;
use Illuminate\Database\Seeder;

class PedidoRutaSeeder extends Seeder
{
  public function run(): void
  {
    Pedido::factory()->pendiente()->count(500)->create();

    Pedido::factory()->asignado()->count(150)->create();

    $rutas = Ruta::factory()->count(3)->create();

    foreach ($rutas as $ruta) {
      /** @var PerfilRepartidor $repartidor */
      $repartidor = $ruta->repartidor;

      $pedidosDisponibles = Pedido::whereNull('repartidor_id')
        ->orWhere('repartidor_id', $repartidor->id)
        ->whereDoesntHave('entregaPedido')
        ->inRandomOrder()
        ->limit(rand(50, 60))
        ->get();

      $distanciaAcumulada = 0;
      $tiempoAcumulado = 0;
      $numeroPedido = 1;
      foreach ($pedidosDisponibles as $pedido) {
        if ($pedido->repartidor_id !== $repartidor->id) {
          $pedido->repartidor_id = $repartidor->id;
          $pedido->fecha_asignacion = now()->subMinutes(rand(0, 10));
          $pedido->estado = EstadosPedidoEnum::ASIGNADO;
          $pedido->save();
        }

        EntregaPedido::factory()
          ->forPedido($pedido)
          ->forRuta($ruta)
          ->create([
            'orden_personalizado' => $numeroPedido,
            'orden_optimizado' => $numeroPedido,
          ]);

        $numeroPedido++;
        $distanciaEntrega = rand(100, 1500);
        $distanciaAcumulada += $distanciaEntrega;
        $tiempoViaje = round($distanciaEntrega / 12); // 12 m/s ~ 43 km/h
        $tiempoEntrega = rand(3, 7) * 60;
        $tiempoAcumulado += $tiempoViaje + $tiempoEntrega;
      }

      $firstPedido = $pedidosDisponibles->first();
      $lastPedido = $pedidosDisponibles->last();

      $ruta->cantidad_pedidos = $numeroPedido;
      $ruta->distancia_total_estimada = $distanciaAcumulada;
      $ruta->tiempo_total_estimado = $tiempoAcumulado;
      $ruta->punto_inicio = $firstPedido->ubicacion_recojo;
      $ruta->punto_final = $lastPedido->ubicacion_entrega;
      $ruta->save();
    }

    Pedido::factory()->enRuta()->count(20)->create();
    Pedido::factory()->recogido()->count(20)->create();
    Pedido::factory()->entregado()->count(20)->create();
    Pedido::factory()->fallido()->count(10)->create();
  }
}

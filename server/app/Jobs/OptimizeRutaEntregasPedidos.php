<?php

namespace App\Jobs;

use App\Enums\EstadosPedidoEnum;
use App\Models\EntregaPedido;
use App\Models\Ruta;
use App\Services\RouteOptimization\OptimizationResponse;
use App\Services\RouteOptimization\RouteOptimizationService;
use Carbon\Carbon;
use DateTimeImmutable;
use DB;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Collection;
use Log;
use Str;

class OptimizeRutaEntregasPedidos implements ShouldQueue
{
  use Dispatchable, Queueable;

  public $tries = 2;

  private string $userId;
  private string $rutaId;
  private string $inicioJornada;
  private string $finJornada;
  private int $chunkSize = 512;

  public function __construct(
    string $userId,
    string $rutaId,
    string $inicioJornada,
    string $finJornada,
  ) {
    $this->userId = $userId;
    $this->rutaId = $rutaId;
    $this->inicioJornada = $inicioJornada;
    $this->finJornada = $finJornada;
  }

  public function handle(): void
  {
    /** @var Ruta|null $ruta */
    $ruta = Ruta::find($this->rutaId);

    if ($ruta === null) {
      Log::error("Ruta no encontrada {$this->rutaId}. Abortando re-optimización.");
      throw new \Exception("Ruta no encontrada.");
    }

    /** @var \App\Models\PerfilRepartidor|null $repartidorRuta */
    $repartidorRuta = $ruta->repartidor()->first();
    if ($repartidorRuta === null) {
      Log::error("Repartidor no encontrado para la ruta {$this->rutaId}. Abortando re-optimización.");
      throw new \Exception("Repartidor no encontrado para la ruta existente.");
    }

    /** @var \Illuminate\Database\Eloquent\Collection<int, \App\Models\Pedido> $pedidosRuta */
    $pedidosRuta = $ruta
      ->pedidos()
      ->select([
        'pedidos.id',
        'pedidos.ubicacion_recojo',
        'pedidos.ubicacion_entrega',
        'pedidos.estado',
        'entregas_pedido.id as entrega_pedido_id',
        'entregas_pedido.orden_optimizado',
        'entregas_pedido.orden_personalizado',
        'entregas_pedido.orden_recojo',
        'entregas_pedido.optimizado',
      ])
      ->get()
      ->keyBy('id');

    $pedidosRutaAsignados = $pedidosRuta->filter(fn($pedido) => $pedido->estado === EstadosPedidoEnum::ASIGNADO);

    $otrosPedidosRuta = $pedidosRuta->filter(fn($pedido) => $pedido->estado !== EstadosPedidoEnum::ASIGNADO);

    if ($pedidosRutaAsignados->isEmpty()) {
      Log::warning("La ruta {$this->rutaId} no tiene pedidos disponibles para optimizar.");
      return;
    }

    $globalStartTime = new DateTimeImmutable($this->inicioJornada);
    $globalEndTime = new DateTimeImmutable($this->finJornada);

    $routeOptimizationService = new RouteOptimizationService();

    try {
      $optimizationResult = $routeOptimizationService->optimize(
        new EloquentCollection([$repartidorRuta]),
        $pedidosRutaAsignados->values(),
        $globalStartTime,
        $globalEndTime
      );

      $jsonResult = json_decode($optimizationResult->serializeToJsonString(), true);

      $optimizationResponse = new OptimizationResponse($jsonResult);

      if ($optimizationResponse->validationErrors->isNotEmpty()) {
        Log::warning(
          'Errores de validación de Google Route Optimization: ' .
            $optimizationResponse->validationErrors->implode(', ')
        );
      }

      $optimizedRouteData = $optimizationResponse->optimizedRoutes->firstWhere(
        'vehicleLabel',
        $repartidorRuta->id
      );

      if ($optimizedRouteData === null) {
        Log::warning("El servicio de optimización no devolvió una ruta para el repartidor {$repartidorRuta->id} de la ruta {$this->rutaId}. Puede que los pedidos no fueran óptimos o no se pudieron rutear.");
        return;
      }

      $optimizedUniqueShipments = $optimizedRouteData->uniqueShipments;

      if ($optimizedUniqueShipments->isEmpty()) {
        Log::warning("La ruta optimizada no contiene pedidos únicos (entregas/recojos) para la ruta {$this->rutaId}. No se actualizará el orden.");
        return;
      }

      $entregasPedidoToUpdate = new Collection();
      $currentOrder = 1;

      $optimizedPedidoIds = $optimizedUniqueShipments->pluck('shipmentLabel');

      foreach ($optimizedUniqueShipments as $uniqueShipment) {
        $pedidoId = $uniqueShipment->shipmentLabel;

        if ($uniqueShipment->optimizedDeliveryOrder === null) {
          continue;
        }

        if (!$pedidosRutaAsignados->has($pedidoId)) {
          Log::warning("Pedido {$pedidoId} en respuesta de Google no se encontró en pedidos asignados de la ruta original. Saltando.");
          continue;
        }

        $entregaPedidoId = $pedidosRutaAsignados->get($pedidoId)->entrega_pedido_id;

        $entregasPedidoToUpdate->push([
          'id' => $entregaPedidoId,
          'ruta_id' => $ruta->id,
          'pedido_id' => $pedidoId,
          'orden_optimizado' => $uniqueShipment->optimizedDeliveryOrder,
          'orden_personalizado' => $uniqueShipment->optimizedDeliveryOrder,
          'orden_recojo' => $uniqueShipment->optimizedPickupOrder,
          'optimizado' => true,
        ]);

        $currentOrder++;
      }

      $unoptimizedAssignedPedidos = $pedidosRutaAsignados->reject(fn($pedido) => $optimizedPedidoIds->contains($pedido->id));

      foreach ($unoptimizedAssignedPedidos as $pedido) {
        $entregasPedidoToUpdate->push([
          'id' => $pedido->entrega_pedido_id,
          'ruta_id' => $ruta->id,
          'pedido_id' => $pedido->id,
          'orden_optimizado' => null,
          'orden_personalizado' => $currentOrder,
          'orden_recojo' => null,
          'optimizado' => false,
        ]);

        $currentOrder++;
      }

      foreach ($otrosPedidosRuta as $pedido) {
        $entregasPedidoToUpdate->push([
          'id' => $pedido->entrega_pedido_id,
          'ruta_id' => $ruta->id,
          'pedido_id' => $pedido->id,
          'orden_optimizado' => null,
          'orden_personalizado' => $currentOrder,
          'orden_recojo' => null,
          'optimizado' => false,
        ]);

        $currentOrder++;
      }

      $firstVisit = $optimizedRouteData->visits->first();
      $lastVisit = $optimizedRouteData->visits->last();

      $firstPedido = $pedidosRutaAsignados->get($firstVisit->shipmentLabel);
      $lastPedido = $pedidosRutaAsignados->get($lastVisit->shipmentLabel);

      $puntoInicioRuta = $firstVisit->isPickup ? $firstPedido->ubicacion_recojo : $firstPedido->ubicacion_entrega;
      $puntoFinalRuta = $lastVisit->isPickup ? $lastPedido->ubicacion_recojo : $lastPedido->ubicacion_entrega;

      $distanciaTotalEstimada = $optimizedRouteData->totalTravelDistanceMeters;
      $tiempoTotalEstimado = $optimizedRouteData->totalTravelDurationSeconds;
      $polylineEncoded = $optimizedRouteData->routePolyline;

      DB::transaction(function () use (
        $ruta,
        $entregasPedidoToUpdate,
        $puntoInicioRuta,
        $puntoFinalRuta,
        $distanciaTotalEstimada,
        $tiempoTotalEstimado,
        $polylineEncoded
      ) {
        if ($entregasPedidoToUpdate->isNotEmpty()) {
          $entregasPedidoToUpdate
            ->chunk($this->chunkSize)
            ->each(function ($chunk) {
              EntregaPedido::massUpdate(values: $chunk->toArray());
            });

          Log::info('Actualizadas ' . $entregasPedidoToUpdate->count() . ' entregas de pedido en chunks para la ruta ' . $ruta->id . ' usando massUpdate.');
        }

        $ruta->punto_inicio = $puntoInicioRuta;
        $ruta->punto_final = $puntoFinalRuta;
        $ruta->distancia_total_estimada = $distanciaTotalEstimada;
        $ruta->tiempo_total_estimado = $tiempoTotalEstimado;
        $ruta->fecha_hora_calculo = Carbon::now();
        $ruta->polyline_encoded = $polylineEncoded;
        $ruta->cantidad_pedidos = $entregasPedidoToUpdate->count();
        $ruta->save();

        Log::info("Ruta {$ruta->id} actualizada con nuevas métricas y orden de pedidos.");
      });

      Log::info('Re-optimización de órdenes para la ruta ' . $this->rutaId . ' completada y guardada con éxito.');
    } catch (\Exception $e) {
      Log::error('Error en la optimización de rutas: ' . $e->getMessage());
      throw $e;
    }
  }
}

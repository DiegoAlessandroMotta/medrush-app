<?php

namespace App\Jobs;

use App\Casts\AsPoint;
use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosPedidoEnum;
use App\Models\EntregaPedido;
use App\Models\Pedido;
use App\Models\PerfilRepartidor;
use App\Models\Ruta;
use App\Services\RouteOptimization\OptimizationResponse;
use App\Services\RouteOptimization\RouteOptimizationService;
use Carbon\Carbon;
use DateTimeImmutable;
use DB;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Collection;
use Log;
use Str;

class OptimizeEntregasPedidos implements ShouldQueue
{
  use Dispatchable, Queueable;

  public $tries = 2;

  private string $userId;
  private CodigosIsoPaisEnum $codigoIsoPais;
  private string $inicioJornada;
  private string $finJornada;
  private ?string $codigoPostal;
  private int $chunkSize = 512;
  private int $pedidosMinPorRepartidor = 130;
  private int $pedidosMaxPorRepartidor = 200;

  public function __construct(
    string $userId,
    string $codigoIsoPais,
    string $inicioJornada,
    string $finJornada,
    ?string $codigoPostal = null,
    int $pedidosMinPorRepartidor = 120,
    int $pedidosMaxPorRepartidor = 150,
  ) {
    $this->userId = $userId;
    $this->codigoIsoPais = CodigosIsoPaisEnum::tryFrom($codigoIsoPais);
    $this->inicioJornada = $inicioJornada;
    $this->finJornada = $finJornada;
    $this->codigoPostal = $codigoPostal;
    $this->pedidosMinPorRepartidor = $pedidosMinPorRepartidor;
    $this->pedidosMaxPorRepartidor = $pedidosMaxPorRepartidor;
  }

  public function handle(): void
  {
    Log::info("Asignando pedidos y rutas automaticamente", [
      'userId' => $this->userId,
      'codigoIsoPais' => $this->codigoIsoPais,
      'inicioJornada' => $this->inicioJornada,
      'finJornada' => $this->finJornada,
      'codigoPostal' => $this->codigoPostal,
      'pedidosMinPorRepartidor' => $this->pedidosMinPorRepartidor,
      'pedidosMaxPorRepartidor' => $this->pedidosMaxPorRepartidor,
    ]);

    $pedidosParaOptimizar = Pedido::query()
      ->select('id', 'ubicacion_recojo', 'ubicacion_entrega')
      ->whereCodigoIsoPaisEntrega($this->codigoIsoPais)
      ->whereRepartidorId(null)
      ->whereEstado(EstadosPedidoEnum::PENDIENTE);

    if ($this->codigoPostal !== null) {
      $pedidosParaOptimizar->where('codigo_postal_entrega', '=', $this->codigoPostal);
    }

    $pedidosParaOptimizar = $pedidosParaOptimizar->get()->keyBy('id');
    $totalPedidos = $pedidosParaOptimizar->count();

    if ($totalPedidos === 0) {
      Log::info('No hay pedidos pendientes para optimizar.');
      return;
    }

    $repartidoresNecesarios = $this->calcularRepartidoresNecesarios($totalPedidos);

    $repartidores = PerfilRepartidor::query()
      ->select('id')
      ->whereCodigoIsoPais($this->codigoIsoPais)
      ->limit($repartidoresNecesarios)
      ->get();

    Log::info("Optimizando {$totalPedidos} pedidos con {$repartidores->count()} repartidores seleccionados (promedio: " . round($totalPedidos / max($repartidores->count(), 1)) . " pedidos por repartidor).");

    $globalStartTime = new DateTimeImmutable($this->inicioJornada);
    $globalEndTime = new DateTimeImmutable(Carbon::parse($this->finJornada)->addHours(2)->toISOString());

    $credentialsPath = base_path(config('services.google.route_optimization.credentials'));

    if (!file_exists($credentialsPath)) {
      Log::error("Archivo de credenciales de Google no encontrado en: {$credentialsPath}.");
      throw new \Exception("Falta configurar las credenciales de Google Route Optimization API. Verifica que el archivo service-account.json exista en {$credentialsPath} y la variable GOOGLE_ROUTE_OPTIMIZATION_CREDENTIALS en el .env sea correcta.");
    }

    $routeOptimizationService = new RouteOptimizationService();

    try {
      $optimizationResult = $routeOptimizationService->optimize(
        $repartidores,
        $pedidosParaOptimizar->values(),
        $globalStartTime,
        $globalEndTime
      );

      $jsonResult = json_decode($optimizationResult->serializeToJsonString(), true);

      $optimizationResponse = new OptimizationResponse($jsonResult);

      if ($optimizationResponse->validationErrors->isNotEmpty()) {
        Log::warning('Errores de validación de Google Route Optimization: ' . $optimizationResponse->validationErrors->implode(', '));
      }

      $rutasToInsert = new Collection();
      $entregasPedidoToInsert = new Collection();
      $pedidosIdsByRepartidor = new Collection();
      $repartidorIds = $repartidores->pluck('id');

      foreach ($optimizationResponse->optimizedRoutes as $optimizedRouteData) {
        if (!$repartidorIds->contains($optimizedRouteData->vehicleLabel)) {
          Log::error("Repartidor con ID {$optimizedRouteData->vehicleLabel} no encontrado. Abortando optimización de rutas.");

          throw new \Exception("Repartidor con ID {$optimizedRouteData->vehicleLabel} no encontrado.");
        }

        $cantidadPedidosEnRuta = $optimizedRouteData->uniqueShipments->count();

        if ($cantidadPedidosEnRuta === 0) {
          continue;
        }

        $firstVisit = $optimizedRouteData->visits->first();
        $lastVisit = $optimizedRouteData->visits->last();

        $firstPedido = $pedidosParaOptimizar->get($firstVisit->shipmentLabel);
        $lastPedido = $pedidosParaOptimizar->get($lastVisit->shipmentLabel);

        $puntoInicioRuta = $firstVisit->isPickup ? $firstPedido->ubicacion_recojo : $firstPedido->ubicacion_entrega;
        $puntoFinalRuta = $lastVisit->isPickup ? $lastPedido->ubicacion_recojo : $lastPedido->ubicacion_entrega;

        $polylineEncoded = $optimizedRouteData->routePolyline;
        $rutaId = Str::uuid()->toString();

        $rutasToInsert->push([
          'id' => $rutaId,
          'repartidor_id' => $optimizedRouteData->vehicleLabel,
          'nombre' => 'Ruta ' . Carbon::now()->format('Y-m-d H:i'),
          'punto_inicio' => AsPoint::toRawExpression($puntoInicioRuta),
          'punto_final' => AsPoint::toRawExpression($puntoFinalRuta),
          'polyline_encoded' => $polylineEncoded,
          'distancia_total_estimada' => $optimizedRouteData->totalTravelDistanceMeters,
          'tiempo_total_estimado' => $optimizedRouteData->totalTravelDurationSeconds,
          'cantidad_pedidos' => $cantidadPedidosEnRuta,
          'fecha_hora_calculo' => Carbon::now(),
          'polyline_encoded' => $polylineEncoded,
          'fecha_inicio' => null,
          'fecha_completado' => null,
          'created_at' => Carbon::now(),
          'updated_at' => Carbon::now(),
        ]);

        $currentRoutePedidoIds = [];

        foreach ($optimizedRouteData->uniqueShipments as $uniqueShipment) {
          $pedidoId = $uniqueShipment->shipmentLabel;

          if ($uniqueShipment->optimizedDeliveryOrder === null) {
            continue;
          }

          if (!$pedidosParaOptimizar->has($pedidoId)) {
            Log::warning("Pedido con ID {$pedidoId} no encontrado en la lista original. Se saltará para la ruta {$rutaId}.");
            continue;
          }

          $entregasPedidoToInsert->push([
            'ruta_id' => $rutaId,
            'pedido_id' => $pedidoId,
            'orden_optimizado' => $uniqueShipment->optimizedDeliveryOrder,
            'orden_personalizado' => $uniqueShipment->optimizedDeliveryOrder,
            'orden_recojo' => $uniqueShipment->optimizedPickupOrder,
            'optimizado' => true,
          ]);

          $currentRoutePedidoIds[] = $pedidoId;
        }

        if (!empty($currentRoutePedidoIds)) {
          $pedidosIdsByRepartidor->put(
            $optimizedRouteData->vehicleLabel,
            $currentRoutePedidoIds
          );
        }
      }

      DB::transaction(function () use (
        $rutasToInsert,
        $entregasPedidoToInsert,
        $pedidosIdsByRepartidor
      ) {
        if ($rutasToInsert->isNotEmpty()) {
          Ruta::insert($rutasToInsert->toArray());

          Log::info('Insertadas ' . $rutasToInsert->count() . ' rutas.');
        }

        foreach ($pedidosIdsByRepartidor as $repartidorId => $pedidoIds) {
          if (!empty($pedidoIds)) {
            Pedido::whereIn('id', $pedidoIds)->update([
              'repartidor_id' => $repartidorId,
              'estado' => EstadosPedidoEnum::ASIGNADO,
              'fecha_asignacion' => Carbon::now(),
              'updated_at' => Carbon::now(),
            ]);

            Log::info('Actualizados ' . count($pedidoIds) . " pedidos para el repartidor {$repartidorId}.");
          }
        }

        if ($entregasPedidoToInsert->isNotEmpty()) {
          $entregasPedidoToInsert->chunk($this->chunkSize)
            ->each(function ($chunk) {
              EntregaPedido::insert($chunk->toArray());
            });

          Log::info('Insertadas ' . $entregasPedidoToInsert->count() . ' entregas de pedido en chunks.');
        }
      });

      Log::info('Optimización de rutas completada y guardada con éxito.');
    } catch (\Exception $e) {
      Log::error('Error en la optimización de rutas: ' . $e->getMessage());
      throw $e;
    }
  }

  private function calcularRepartidoresNecesarios(int $totalPedidos): int
  {
    $pedidosObjetivoPorRepartidor = ($this->pedidosMinPorRepartidor + $this->pedidosMaxPorRepartidor) / 2;

    $repartidoresNecesarios = max(1, (int) ceil($totalPedidos / $pedidosObjetivoPorRepartidor));

    return $repartidoresNecesarios;
  }


}

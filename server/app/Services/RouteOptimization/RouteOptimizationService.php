<?php

namespace App\Services\RouteOptimization;

use App\Enums\GoogleApiServiceType;
use App\Exceptions\CustomException;
use App\Models\GoogleApiUsage;
use Auth;
use DateTimeImmutable;
use Exception;
use Google\Maps\RouteOptimization\V1\Client\RouteOptimizationClient;
use Google\Maps\RouteOptimization\V1\OptimizeToursRequest;
use Google\Maps\RouteOptimization\V1\OptimizeToursResponse;
use Google\Maps\RouteOptimization\V1\Shipment;
use Google\Maps\RouteOptimization\V1\Shipment\VisitRequest;
use Google\Maps\RouteOptimization\V1\ShipmentModel;
use Google\Maps\RouteOptimization\V1\Vehicle;
use Google\Maps\RouteOptimization\V1\Vehicle\TravelMode;
use Google\Protobuf\Duration;
use Google\Protobuf\Timestamp;
use Google\Type\LatLng;
use Illuminate\Database\Eloquent\Collection;

class RouteOptimizationService
{
  protected RouteOptimizationClient $client;
  protected string $parent;

  public function __construct()
  {
    $this->client = new RouteOptimizationClient([
      'credentials' =>  base_path(config('services.google.route_optimization.credentials'))
    ]);
    $this->parent = config('services.google.route_optimization.project_id');
  }

  /**
   * Optimiza las rutas para un conjunto de repartidores y pedidos.
   *
   * @param \Illuminate\Database\Eloquent\Collection<int, PerfilRepartidor> $repartidores
   * @param \Illuminate\Database\Eloquent\Collection<int, Pedido> $pedidos
   * @param \DateTimeImmutable $globalStartTime
   * @param \DateTimeImmutable $globalEndTime
   * @return OptimizeToursResponse
   * @throws \Exception
   */
  public function optimize(
    Collection $repartidores,
    Collection $pedidos,
    DateTimeImmutable $globalStartTime,
    DateTimeImmutable $globalEndTime
  ): OptimizeToursResponse {
    if ($repartidores->isEmpty() || $pedidos->isEmpty()) {
      throw CustomException::internalServer('Se requieren repartidores y pedidos para optimizar las rutas.');
    }

    $shipmentModel = new ShipmentModel([
      'vehicles' => $this->buildVehicles($repartidores),
      'shipments' => $this->buildShipments($pedidos),
      'global_start_time' => $this->createTimestamp($globalStartTime),
      'global_end_time' => $this->createTimestamp($globalEndTime),
    ]);

    $req = new OptimizeToursRequest([
      'parent' => $this->parent,
      'model' => $shipmentModel,
      'populate_polylines' => true,
    ]);

    $req->setParent($this->parent);

    try {
      $res = $this->client->optimizeTours($req);

      GoogleApiUsage::create([
        'user_id' => Auth::user()?->id,
        'type' => GoogleApiServiceType::ROUTE_OPTIMIZATION_FLEETROUTING,
      ]);

      return $res;
    } catch (\Exception $e) {
      throw CustomException::serviceUnavailable();
    }
  }

  /**
   * Construye el array de vehículos para la solicitud de optimización.
   *
   * @param \Illuminate\Database\Eloquent\Collection<int, PerfilRepartidor> $repartidores
   * @return array<int, Vehicle>
   * @throws \Exception
   */
  protected function buildVehicles(\Illuminate\Database\Eloquent\Collection $repartidores): array
  {
    $vehicles = [];

    foreach ($repartidores as $repartidor) {
      // /** @var \App\Models\Farmacia  */
      // $farmacia = $repartidor->farmacia;

      // $startLocation = $farmacia?->ubicacion !== null ?
      //   $this->createLatLng($farmacia->ubicacion->latitude, $farmacia->ubicacion->longitude)
      //   : null;

      $vehicles[] = new Vehicle([
        'label' => $repartidor->id,
        'travel_mode' => TravelMode::DRIVING,
        // 'start_location' => $startLocation,
      ]);
    }

    return $vehicles;
  }

  /**
   * Construye el array de envíos para la solicitud de optimización.
   *
   * @param \Illuminate\Database\Eloquent\Collection<int, Pedido> $pedidos
   * @return array<int, Shipment>
   * @throws \Exception
   */
  protected function buildShipments(Collection $pedidos): array
  {
    $shipments = [];

    foreach ($pedidos as $pedido) {
      $pickupLocation = $this->createLatLng(
        latitude: $pedido->ubicacion_recojo->latitude,
        longitude: $pedido->ubicacion_recojo->longitude,
      );

      if ($pedido->ubicacion_entrega === null) {
        throw CustomException::internalServer("La ubicación de entrega no está disponible para el pedido: {$pedido->id}");
      }

      $deliveryLocation = $this->createLatLng(
        latitude: $pedido->ubicacion_entrega->latitude,
        longitude: $pedido->ubicacion_entrega->longitude,
      );

      $shipments[] = new Shipment([
        'label' => $pedido->id,
        'pickups' => [
          new VisitRequest([
            'arrival_location' => $pickupLocation,
            // 'duration' => new Duration(['seconds' => 300]),
          ]),
        ],
        'deliveries' => [
          new VisitRequest([
            'arrival_location' => $deliveryLocation,
            'duration' => new Duration(['seconds' => 120]),
          ]),
        ],
      ]);
    }

    return $shipments;
  }

  /**
   * Crea un objeto LatLng a partir de latitud y longitud.
   *
   * @param float $latitude
   * @param float $longitude
   * @return LatLng
   */
  protected function createLatLng(float $latitude, float $longitude): LatLng
  {
    return new LatLng([
      'latitude' => $latitude,
      'longitude' => $longitude,
    ]);
  }

  /**
   * Crea un objeto Timestamp a partir de un objeto DateTimeImmutable.
   *
   * @param \DateTimeImmutable $dateTime
   * @return Timestamp
   */
  protected function createTimestamp(\DateTimeImmutable $dateTime): Timestamp
  {
    return new Timestamp([
      'seconds' => $dateTime->getTimestamp(),
    ]);
  }
}

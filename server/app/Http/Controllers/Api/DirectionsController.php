<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\DirectionsWithWaypointsRequest;
use App\Http\Requests\Api\RouteInfoRequest;
use App\Services\Directions\DirectionsService;

class DirectionsController extends Controller
{
  private DirectionsService $directionsService;

  public function __construct(DirectionsService $directionsService)
  {
    $this->directionsService = $directionsService;
  }

  public function getDirectionsWithWaypoints(DirectionsWithWaypointsRequest $request)
  {
    $origen = $request->getOrigen();
    $destino = $request->getDestino();
    $waypoints = $request->getWaypoints();
    $optimizeWaypoints = $request->getOptimizeWaypoints();

    $result = $this->directionsService->getDirectionsWithWaypoints(
      origin: $origen,
      destination: $destino,
      waypoints: $waypoints,
      optimizeWaypoints: $optimizeWaypoints
    );

    if ($result === null) {
      throw CustomException::serviceUnavailable();
    }

    return ApiResponder::success(
      message: 'Directions obtenido exitosamente',
      data: $result->toArray(),
    );
  }

  public function getRouteInfo(RouteInfoRequest $request)
  {
    $origen = $request->getOrigen();
    $destino = $request->getDestino();
    $waypoints = $request->getWaypoints();

    $result = $this->directionsService->getRouteInfo(
      origin: $origen,
      destination: $destino,
      waypoints: $waypoints
    );

    if ($result === null) {
      throw CustomException::serviceUnavailable();
    }
    return ApiResponder::success(
      message: 'Información de ruta obtenida exitosamente',
      data: $result->toArray(),
    );
  }
}

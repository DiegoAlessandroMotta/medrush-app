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

  /**
   * @OA\Get(
   *     path="/api/directions",
   *     operationId="directionsGetWithWaypoints",
   *     tags={"Maps","Directions"},
   *     summary="Obtener direcciones con puntos intermedios",
   *     description="Calcula la ruta optimizada entre un origen y destino, pasando por múltiples waypoints (puntos intermedios). Utiliza Google Maps Directions API internamente.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="origen",
   *         in="query",
   *         required=true,
   *         description="Ubicación de origen en formato 'latitude,longitude'",
   *         @OA\Schema(type="string", example="4.7110,-74.0087"),
   *     ),
   *     @OA\Parameter(
   *         name="destino",
   *         in="query",
   *         required=true,
   *         description="Ubicación de destino en formato 'latitude,longitude'",
   *         @OA\Schema(type="string", example="4.7169,-74.0072"),
   *     ),
   *     @OA\Parameter(
   *         name="waypoints",
   *         in="query",
   *         required=false,
   *         description="Puntos intermedios separados por '|', cada uno en formato 'latitude,longitude'",
   *         @OA\Schema(type="string", example="4.7120,-74.0080|4.7140,-74.0075"),
   *     ),
   *     @OA\Parameter(
   *         name="optimize_waypoints",
   *         in="query",
   *         required=false,
   *         description="Si es true, optimiza el orden de los waypoints para distancia mínima",
   *         @OA\Schema(type="boolean", example=true),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Direcciones obtenidas exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Directions obtenido exitosamente"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="encoded_polyline", type="string", description="Polilínea codificada de la ruta", example="_p~iF~ps|U_ulLnnqC_mqNvxq`@"),
   *                 @OA\Property(property="legs", type="array", description="Array de tramos de la ruta",
   *                     items=@OA\Items(type="object",
   *                         @OA\Property(property="distance_text", type="string", example="5.2 km"),
   *                         @OA\Property(property="duration_text", type="string", example="12 mins"),
   *                         @OA\Property(property="distance_meters", type="integer", example=5200),
   *                         @OA\Property(property="duration_seconds", type="integer", example=720),
   *                         @OA\Property(property="cumulative_distance_meters", type="integer", example=5200),
   *                         @OA\Property(property="cumulative_duration_seconds", type="integer", example=720),
   *                     )
   *                 ),
   *                 @OA\Property(property="total_distance_meters", type="integer", example=5200),
   *                 @OA\Property(property="total_duration_seconds", type="integer", example=720),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación - Parámetros inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=503,
   *         description="Servicio de mapas no disponible",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     ),
   * )
   */
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

    $response = ApiResponder::success(
      message: 'Directions obtenido exitosamente',
      data: $result->toArray(),
    );

    return $response;
  }

  /**
   * @OA\Get(
   *     path="/api/routes",
   *     operationId="directionsGetRouteInfo",
   *     tags={"Maps","Directions"},
   *     summary="Obtener información detallada de ruta",
   *     description="Obtiene información detallada sobre una ruta entre origen y destino, incluyendo distancia y duración total. Versión simplificada sin waypoints.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="origen",
   *         in="query",
   *         required=true,
   *         description="Ubicación de origen en formato 'latitude,longitude'",
   *         @OA\Schema(type="string", example="4.7110,-74.0087"),
   *     ),
   *     @OA\Parameter(
   *         name="destino",
   *         in="query",
   *         required=true,
   *         description="Ubicación de destino en formato 'latitude,longitude'",
   *         @OA\Schema(type="string", example="4.7169,-74.0072"),
   *     ),
   *     @OA\Parameter(
   *         name="waypoints",
   *         in="query",
   *         required=false,
   *         description="Puntos intermedios separados por '|', cada uno en formato 'latitude,longitude'",
   *         @OA\Schema(type="string", example="4.7120,-74.0080|4.7140,-74.0075"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Información de ruta obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Información de ruta obtenida exitosamente"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="legs", type="array", description="Array de tramos de la ruta",
   *                     items=@OA\Items(type="object",
   *                         @OA\Property(property="distance_text", type="string", example="5.2 km"),
   *                         @OA\Property(property="duration_text", type="string", example="12 mins"),
   *                         @OA\Property(property="distance_meters", type="integer", example=5200),
   *                         @OA\Property(property="duration_seconds", type="integer", example=720),
   *                         @OA\Property(property="cumulative_distance_meters", type="integer", example=5200),
   *                         @OA\Property(property="cumulative_duration_seconds", type="integer", example=720),
   *                     )
   *                 ),
   *                 @OA\Property(property="total_distance_meters", type="integer", example=5200),
   *                 @OA\Property(property="total_duration_seconds", type="integer", example=720),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación - Parámetros inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=503,
   *         description="Servicio de mapas no disponible",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     ),
   * )
   */
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

    $response = ApiResponder::success(
      message: 'Información de ruta obtenida exitosamente',
      data: $result->toArray(),
    );

    return $response;
  }
}

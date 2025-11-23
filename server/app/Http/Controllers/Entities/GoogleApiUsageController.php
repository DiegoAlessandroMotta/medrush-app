<?php

namespace App\Http\Controllers\Entities;

use App\Enums\GoogleApiServiceType;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Models\GoogleApiUsage;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class GoogleApiUsageController extends Controller
{
  /**
   * Obtener estadísticas de uso de Google APIs.
   *
   * @OA\Get(
   *     path="/api/google-api-usage/stats",
   *     operationId="googleApiUsageStats",
   *     tags={"Maps","Google APIs"},
   *     summary="Obtener estadísticas de uso de Google APIs",
   *     description="Obtiene estadísticas detalladas de uso de servicios de Google APIs (Geocoding, Directions, Route Optimization) para un período específico. Incluye el costo estimado por servicio basado en la tarifa actual de Google.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="year",
   *         in="query",
   *         required=false,
   *         description="Año para filtrar estadísticas (2020-2030, por defecto año actual)",
   *         @OA\Schema(type="integer", example=2024)
   *     ),
   *     @OA\Parameter(
   *         name="month",
   *         in="query",
   *         required=false,
   *         description="Mes para filtrar estadísticas (1-12, por defecto mes actual)",
   *         @OA\Schema(type="integer", example=11)
   *     ),
   *     @OA\Parameter(
   *         name="service_type",
   *         in="query",
   *         required=false,
   *         description="Tipo de servicio para filtrar (route_optimization_fleetrouting, geocoding, directions)",
   *         @OA\Schema(type="string", enum={"route_optimization_fleetrouting","geocoding","directions"}, example="geocoding")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Estadísticas obtenidas exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Estadísticas de uso de Google API"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="period", type="object",
   *                     @OA\Property(property="start_date", type="string", format="date-time", example="2024-11-01T00:00:00.000000Z"),
   *                     @OA\Property(property="end_date", type="string", format="date-time", example="2024-11-30T23:59:59.000000Z")
   *                 ),
   *                 @OA\Property(property="summary", type="object",
   *                     @OA\Property(property="total_requests", type="integer", example=1250),
   *                     @OA\Property(property="total_estimated_cost", type="number", format="float", example=7.5),
   *                     @OA\Property(property="currency", type="string", example="USD")
   *                 ),
   *                 @OA\Property(property="services", type="array",
   *                     items=@OA\Items(type="object",
   *                         @OA\Property(property="type", type="string", example="geocoding"),
   *                         @OA\Property(property="service_name", type="string", example="Geocoding"),
   *                         @OA\Property(property="total_requests", type="integer", example=500),
   *                         @OA\Property(property="cost_per_request", type="number", format="float", example=0.005),
   *                         @OA\Property(property="estimated_cost", type="number", format="float", example=2.5)
   *                     )
   *                 )
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación en los parámetros",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function getUsageStats(Request $request)
  {
    $request->validate([
      'year' => ['sometimes', 'integer', 'min:2020', 'max:2030'],
      'month' => ['sometimes', 'integer', 'min:1', 'max:12'],
      'service_type' => ['sometimes', 'string', Rule::enum(GoogleApiServiceType::class)],
    ]);

    $year = (int) $request->get('year', Carbon::now()->year);
    $month = (int) $request->get('month', Carbon::now()->month);
    $specificServiceType = $request->get('service_type');

    $startOfMonth = Carbon::createFromDate($year, $month, 1)->startOfMonth();
    $endOfMonth = Carbon::createFromDate($year, $month, 1)->endOfMonth();

    $query = GoogleApiUsage::whereBetween('created_at', [
      $startOfMonth,
      $endOfMonth
    ]);

    if ($specificServiceType) {
      $query->where('type', $specificServiceType);
    }

    /** @var \Illuminate\Database\Eloquent\Collection<int, GoogleApiUsage> $results  */
    $results = $query
      ->selectRaw('type, count(*) as total_requests')
      ->groupBy('type')
      ->get();

    $usageByType = $results
      ->map(function ($usage) {
        return (object) [
          'type' => $usage->type->value,
          'total_requests' => $usage->total_requests,
        ];
      })
      ->keyBy('type');

    $serviceDetails = [];
    $totalRequests = 0;
    $totalEstimatedCost = 0;

    foreach (GoogleApiServiceType::cases() as $serviceEnum) {
      $serviceValue = $serviceEnum->value;
      $requests = $usageByType->has($serviceValue) ? $usageByType[$serviceValue]->total_requests : 0;

      $costPerRequest = $serviceEnum->costPerRequest();

      $estimatedCost = $requests * $costPerRequest;

      $serviceDetails[] = [
        'type' => $serviceValue,
        'service_name' => str_replace('_', ' ', ucwords($serviceValue)),
        'total_requests' => $requests,
        'cost_per_request' => $costPerRequest,
        'estimated_cost' => round($estimatedCost, 2),
      ];

      $totalRequests += $requests;
      $totalEstimatedCost += $estimatedCost;
    }

    $statistics = [
      'period' => [
        'start_date' => $startOfMonth,
        'end_date' => $endOfMonth,
      ],
      'summary' => [
        'total_requests' => $totalRequests,
        'total_estimated_cost' => round($totalEstimatedCost, 2),
        'currency' => 'USD',
      ],
      'services' => $serviceDetails,
    ];

    $message = 'Estadísticas de uso de Google API';
    if ($specificServiceType) {
      $message .= " (Tipo de servicio: " . str_replace('_', ' ', ucwords($specificServiceType)) . ")";
    }

    return ApiResponder::success(
      message: $message,
      data: $statistics
    );
  }
}

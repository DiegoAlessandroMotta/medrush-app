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

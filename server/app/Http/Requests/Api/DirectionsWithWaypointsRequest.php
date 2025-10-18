<?php

namespace App\Http\Requests\Api;

use App\Helpers\PrepareData;
use App\Rules\LocationArray;
use Illuminate\Foundation\Http\FormRequest;

class DirectionsWithWaypointsRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'origen' => ['required', new LocationArray],
      'destino' => ['required', new LocationArray],
      'waypoints' => ['sometimes', 'array'],
      'waypoints.*' => [new LocationArray],
      'optimize_waypoints' => ['sometimes', 'boolean'],
    ];
  }

  /**
   * @return array{latitude: float, longitude: float}
   */
  public function getOrigen(): array
  {
    return PrepareData::location($this->validated('origen'));
  }

  /**
   * @return array{latitude: float, longitude: float}
   */
  public function getDestino(): array
  {
    return PrepareData::location($this->validated('destino'));
  }

  /**
   * @return array<array{latitude: float, longitude: float}>
   */
  public function getWaypoints(): array
  {
    $waypoints = $this->validated('waypoints', []);
    return array_map(fn($waypoint) => PrepareData::location($waypoint), $waypoints);
  }

  public function getOptimizeWaypoints(): bool
  {
    return $this->validated('optimize_waypoints', false);
  }
}

<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\ReverseGeocodeRequest;
use App\Services\Geocoding\GeocodingService;

class GeocodingController extends Controller
{
  private GeocodingService $geocodingService;

  public function __construct(GeocodingService $geocodingService)
  {
    $this->geocodingService = $geocodingService;
  }

  public function reverseGeocode(ReverseGeocodeRequest $request)
  {
    $ubicacion = $request->getUbicacion();

    $result = $this->geocodingService->reverseGeocode(
      latitude: $ubicacion['latitude'],
      longitude: $ubicacion['longitude'],
    );

    if ($result === null) {
      throw CustomException::internalServer();
    }

    return ApiResponder::success(
      message: 'Geocodificación exitosa',
      data: $result->toArray(),
    );
  }
}

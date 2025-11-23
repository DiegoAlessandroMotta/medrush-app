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

  /**
   * @OA\Post(
   *     path="/api/geocoding/reverse",
   *     operationId="geocodingReverse",
   *     tags={"Maps","Geocoding"},
   *     summary="Geocodificación inversa - Obtener dirección desde coordenadas",
   *     description="Convierte coordenadas geográficas (latitud, longitud) a dirección legible. Utiliza Google Maps Reverse Geocoding API para obtener componentes de dirección (línea 1, ciudad, estado, código postal, país).",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Coordenadas a geocodificar",
   *         @OA\JsonContent(
   *             required={"location"},
   *             @OA\Property(property="location", type="object", required={"latitude","longitude"},
   *                 @OA\Property(property="latitude", type="number", format="float", example=4.7110, description="Latitud de la ubicación"),
   *                 @OA\Property(property="longitude", type="number", format="float", example=-74.0087, description="Longitud de la ubicación"),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Geocodificación realizada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Geocodificación exitosa"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="address_line_1", type="string", example="Carrera 7 #72-41", description="Primera línea de la dirección"),
   *                 @OA\Property(property="city", type="string", example="Bogotá", description="Ciudad"),
   *                 @OA\Property(property="state", type="string", example="Bogotá D.C.", description="Departamento o estado"),
   *                 @OA\Property(property="postal_code", type="string", example="110221", description="Código postal"),
   *                 @OA\Property(property="country", type="string", example="Colombia", description="País"),
   *                 @OA\Property(property="formatted_address", type="string", example="Carrera 7 #72-41, Bogotá, Bogotá D.C., 110221, Colombia", description="Dirección formateada completa"),
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
   *         description="Error de validación - Coordenadas inválidas",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor - Servicio de geocodificación no disponible",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     ),
   * )
   */
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

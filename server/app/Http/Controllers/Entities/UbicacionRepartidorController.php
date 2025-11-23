<?php

namespace App\Http\Controllers\Entities;

use App\DTOs\CursorItemDto;
use App\DTOs\CursorPaginationDto;
use App\Enums\EstadosPedidoEnum;
use App\Events\UbicacionRepartidor\UbicacionRepartidorUpdatedEvent;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\UbicacionRepartidor\IndexUbicacionRepartidor;
use App\Http\Requests\UbicacionRepartidor\StoreUbicacionRepartidor;
use App\Http\Resources\UbicacionRepartidorResource;
use App\Models\Pedido;
use App\Models\UbicacionRepartidor;
use Auth;
use Illuminate\Database\Eloquent\Builder;

class UbicacionRepartidorController extends Controller
{
  /**
   * Obtener lista de ubicaciones de repartidores con paginación por cursor.
   *
   * @OA\Get(
   *     path="/api/ubicaciones-repartidor",
   *     operationId="ubicacionesRepartidorIndex",
   *     tags={"Entities","Ubicaciones Repartidor"},
   *     summary="Listar ubicaciones de repartidores",
   *     description="Obtiene una lista de ubicaciones registradas de repartidores con soporte para paginación por cursor y filtros. Los administradores pueden ver ubicaciones de cualquier repartidor, mientras que los repartidores solo ven sus propias ubicaciones.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="limit",
   *         in="query",
   *         required=false,
   *         description="Número máximo de ubicaciones a retornar (1-500)",
   *         @OA\Schema(type="integer", example=100)
   *     ),
   *     @OA\Parameter(
   *         name="cursor",
   *         in="query",
   *         required=false,
   *         description="Cursor codificado en base64 para la siguiente página de resultados",
   *         @OA\Schema(type="string", example="eyJmZWNoYV9yZWdpc3RybyI6IjIwMjQtMDItMDZUMDg6MzA6MzAuMDAwMDAwWiIsImlkIjoiNTUwZTg0MzMtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAwIiwib3JkZXJfZGlyZWN0aW9uIjoiYXNjIiwib3JkZXJfYnkiOiJmZWNoYV9yZWdpc3RybyJ9")
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="asc")
   *     ),
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo por el cual ordenar",
   *         @OA\Schema(type="string", enum={"created_at","fecha_registro"}, example="fecha_registro")
   *     ),
   *     @OA\Parameter(
   *         name="start_ts",
   *         in="query",
   *         required=false,
   *         description="Fecha y hora de inicio para filtrar ubicaciones",
   *         @OA\Schema(type="string", format="date", example="2024-02-06")
   *     ),
   *     @OA\Parameter(
   *         name="end_ts",
   *         in="query",
   *         required=false,
   *         description="Fecha y hora de fin para filtrar ubicaciones",
   *         @OA\Schema(type="string", format="date", example="2024-02-08")
   *     ),
   *     @OA\Parameter(
   *         name="repartidor_id",
   *         in="query",
   *         required=false,
   *         description="UUID del repartidor para filtrar ubicaciones (requerido para administradores, se ignora para repartidores)",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Parameter(
   *         name="pedido_id",
   *         in="query",
   *         required=false,
   *         description="UUID del pedido para filtrar ubicaciones",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440001")
   *     ),
   *     @OA\Parameter(
   *         name="ruta_id",
   *         in="query",
   *         required=false,
   *         description="UUID de la ruta para filtrar ubicaciones",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440002")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de ubicaciones obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando las ubicaciones de los repartidores"),
   *             @OA\Property(property="data", type="array",
   *                 items=@OA\Items(type="object",
   *                     @OA\Property(property="id", type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440003"),
   *                     @OA\Property(property="repartidor_id", type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000"),
   *                     @OA\Property(property="pedido_id", type="string", format="uuid", nullable=true, example="550e8400-e29b-41d4-a716-446655440001"),
   *                     @OA\Property(property="ruta_id", type="string", format="uuid", nullable=true, example="550e8400-e29b-41d4-a716-446655440002"),
   *                     @OA\Property(property="ubicacion", type="object",
   *                         @OA\Property(property="latitude", type="number", example=4.7110, description="Latitud"),
   *                         @OA\Property(property="longitude", type="number", example=-74.0087, description="Longitud")
   *                     ),
   *                     @OA\Property(property="precision_m", type="number", nullable=true, description="Precisión de la ubicación en metros", example=5.5),
   *                     @OA\Property(property="velocidad_ms", type="number", nullable=true, description="Velocidad en metros por segundo", example=15.3),
   *                     @OA\Property(property="direccion", type="number", nullable=true, description="Dirección en grados (0-360)", example=45.5),
   *                     @OA\Property(property="fecha_registro", type="string", format="date-time", example="2024-02-06T08:30:00.000000Z"),
   *                     @OA\Property(property="created_at", type="string", format="date-time", example="2024-02-06T08:30:00.000000Z")
   *                 )
   *             ),
   *             @OA\Property(property="cursor_pagination", type="object",
   *                 @OA\Property(property="limit", type="integer", example=100),
   *                 @OA\Property(property="has_more", type="boolean", example=false),
   *                 @OA\Property(property="next_cursor", type="string", nullable=true),
   *                 @OA\Property(property="last_item", type="object", nullable=true,
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="key", type="string"),
   *                     @OA\Property(property="value", type="string")
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
   *         description="Error de validación",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function index(IndexUbicacionRepartidor $request)
  {
    $limit = $request->getLimit();
    $orderDirection = $request->getOrderDirection();
    $primaryOrderByField = $request->getOrderBy();
    $tieBreakerOrderByField = $request->getTieBreakerOrderByField();
    $decodedCursor = $request->getDecodedCursor();

    $ubicacionesRepartidor = UbicacionRepartidor::query();

    $user = Auth::user();
    if ($user->esAdmin()) {
      if ($request->getRepartidorId()) {
        $ubicacionesRepartidor->where('repartidor_id', $request->getRepartidorId());
      }
    } elseif ($user->esRepartidor()) {
      $ubicacionesRepartidor->where('repartidor_id', $user->id);
    }

    if ($request->getPedidoId()) {
      $ubicacionesRepartidor->where('pedido_id', $request->getPedidoId());
    }

    if ($request->getRutaId()) {
      $ubicacionesRepartidor->where('ruta_id', $request->getRutaId());
    }

    if ($request->getStartTimestamp()) {
      $ubicacionesRepartidor->where($primaryOrderByField, '>=', $request->getStartTimestamp());
    }

    if ($request->getEndTimestamp()) {
      $ubicacionesRepartidor->where($primaryOrderByField, '<=', $request->getEndTimestamp());
    }

    if ($decodedCursor) {
      $cursorPrimaryFieldUsed = array_keys($decodedCursor)[0] ?? null;
      $cursorTieBreakerFieldUsed = array_keys($decodedCursor)[1] ?? null;

      $primaryCursorValue = $decodedCursor[$cursorPrimaryFieldUsed] ?? null;
      $tieBreakerCursorValue = $decodedCursor[$cursorTieBreakerFieldUsed] ?? null;
      $cursorOrderDirection = $decodedCursor['order_direction'] ?? $orderDirection;

      if ($primaryCursorValue !== null && $tieBreakerCursorValue !== null && $cursorPrimaryFieldUsed && $cursorTieBreakerFieldUsed) {
        $operator = ($cursorOrderDirection === 'asc') ? '>' : '<';

        $ubicacionesRepartidor->where(function (Builder $query) use (
          $cursorPrimaryFieldUsed,
          $primaryCursorValue,
          $cursorTieBreakerFieldUsed,
          $tieBreakerCursorValue,
          $operator
        ) {
          $query->where($cursorPrimaryFieldUsed, $operator, $primaryCursorValue)
            ->orWhere(function (Builder $q) use (
              $cursorPrimaryFieldUsed,
              $primaryCursorValue,
              $cursorTieBreakerFieldUsed,
              $tieBreakerCursorValue,
              $operator
            ) {
              $q->where($cursorPrimaryFieldUsed, $primaryCursorValue)
                ->where($cursorTieBreakerFieldUsed, $operator, $tieBreakerCursorValue);
            });
        });

        $primaryOrderByField = $cursorPrimaryFieldUsed;
        $orderDirection = $cursorOrderDirection;
      }
    }

    $ubicacionesRepartidor->orderBy($primaryOrderByField, $orderDirection);
    $ubicacionesRepartidor->orderBy($tieBreakerOrderByField, $orderDirection);

    $results = $ubicacionesRepartidor->limit($limit + 1)->get();

    $hasMorePages = false;
    if ($results->count() > $limit) {
      $hasMorePages = true;
      $results = $results->take($limit);
    }

    $nextCursor = null;
    $lastItem = null;
    if ($hasMorePages) {
      $lastItem = $results->last();
      if ($lastItem) {
        $cursorData = [
          $primaryOrderByField => $lastItem->{$primaryOrderByField}->toIso8601String(),
          $tieBreakerOrderByField => $lastItem->{$tieBreakerOrderByField},
          'order_direction' => $orderDirection,
          'order_by' => $primaryOrderByField,
        ];

        $lastItem = new CursorItemDto(
          id: $lastItem->id,
          key: $primaryOrderByField,
          value: $lastItem->{$primaryOrderByField}->toIso8601String(),
        );

        $nextCursor = base64_encode(json_encode($cursorData));
      }
    }

    $cursorPagination = new CursorPaginationDto(
      limit: $limit,
      hasMore: $hasMorePages,
      nextCursor: $nextCursor,
      lastItem: $lastItem,
    );

    return ApiResponder::success(
      message: 'Mostrando las ubicaciones de los repartidores',
      data: UbicacionRepartidorResource::collection($results),
      cursorPagination: $cursorPagination,
    );
  }

  /**
   * Registrar nueva ubicación de repartidor.
   *
   * @OA\Post(
   *     path="/api/ubicaciones-repartidor",
   *     operationId="ubicacionesRepartidorStore",
   *     tags={"Entities","Ubicaciones Repartidor"},
   *     summary="Registrar ubicación de repartidor",
   *     description="Registra una nueva ubicación para un repartidor. Si se proporciona un pedido_id, valida que el repartidor esté asignado al pedido y que éste se encuentre en estado 'EN_RUTA'. La ubicación se registra como un punto GIS (latitud, longitud).",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos de la ubicación a registrar",
   *         @OA\JsonContent(
   *             required={"repartidor_id","ubicacion"},
   *             @OA\Property(
   *                 property="repartidor_id",
   *                 type="string",
   *                 format="uuid",
   *                 example="550e8400-e29b-41d4-a716-446655440000",
   *                 description="UUID del repartidor"
   *             ),
   *             @OA\Property(
   *                 property="pedido_id",
   *                 type="string",
   *                 format="uuid",
   *                 nullable=true,
   *                 example="550e8400-e29b-41d4-a716-446655440001",
   *                 description="UUID del pedido asociado (opcional)"
   *             ),
   *             @OA\Property(
   *                 property="ubicacion",
   *                 type="object",
   *                 description="Coordenadas del repartidor",
   *                 @OA\Property(
   *                     property="latitude",
   *                     type="number",
   *                     example=4.7110,
   *                     description="Latitud"
   *                 ),
   *                 @OA\Property(
   *                     property="longitude",
   *                     type="number",
   *                     example=-74.0087,
   *                     description="Longitud"
   *                 )
   *             ),
   *             @OA\Property(
   *                 property="precision_m",
   *                 type="number",
   *                 nullable=true,
   *                 example=5.5,
   *                 description="Precisión de la ubicación en metros"
   *             ),
   *             @OA\Property(
   *                 property="velocidad_ms",
   *                 type="number",
   *                 nullable=true,
   *                 example=15.3,
   *                 description="Velocidad en metros por segundo"
   *             ),
   *             @OA\Property(
   *                 property="direccion",
   *                 type="number",
   *                 nullable=true,
   *                 example=45.5,
   *                 description="Dirección en grados (0-360)"
   *             ),
   *             @OA\Property(
   *                 property="fecha_registro",
   *                 type="string",
   *                 format="date-time",
   *                 nullable=true,
   *                 example="2024-02-06T08:30:00Z",
   *                 description="Fecha y hora del registro (debe ser anterior o igual a ahora)"
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Ubicación registrada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Ubicación del repartidor registrada exitosamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440003"),
   *                 @OA\Property(property="repartidor_id", type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000"),
   *                 @OA\Property(property="pedido_id", type="string", format="uuid", nullable=true, example="550e8400-e29b-41d4-a716-446655440001"),
   *                 @OA\Property(property="ruta_id", type="string", format="uuid", nullable=true, example="550e8400-e29b-41d4-a716-446655440002"),
   *                 @OA\Property(property="ubicacion", type="object",
   *                     @OA\Property(property="latitude", type="number", example=4.7110, description="Latitud"),
   *                     @OA\Property(property="longitude", type="number", example=-74.0087, description="Longitud")
   *                 ),
   *                 @OA\Property(property="precision_m", type="number", nullable=true, example=5.5),
   *                 @OA\Property(property="velocidad_ms", type="number", nullable=true, example=15.3),
   *                 @OA\Property(property="direccion", type="number", nullable=true, example=45.5),
   *                 @OA\Property(property="fecha_registro", type="string", format="date-time", example="2024-02-06T08:30:00.000000Z"),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2024-02-06T08:30:00.000000Z")
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
   *         description="Error de validación o validación de negocio",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function store(StoreUbicacionRepartidor $request)
  {
    $validatedData = $request->validated();

    $rutaId = null;
    if ($request->hasPedidoId()) {
      /** @var Pedido $pedido */
      $pedido = Pedido::findOrFail($request->getPedidoId());

      if ($pedido->repartidor_id !== $request->getRepartidorId()) {
        throw CustomException::validationException(
          message: 'El repartidor no está asignado a este pedido.',
          errors: ['repartidor_id' => 'El id del repartidor proporcionado no coincide con el repartidor asignado a este pedido.']
        );
      }

      if ($pedido->estado !== EstadosPedidoEnum::EN_RUTA) {
        throw CustomException::validationException(
          message: sprintf(
            'El pedido debe estar en estado "%s" para registrar ubicaciones. Estado actual: "%s".',
            EstadosPedidoEnum::EN_RUTA->value,
            $pedido->estado->value
          ),
        );
      }

      $rutaId = $pedido->ruta?->id;
    }

    $insertData = array_merge($validatedData, [
      'ruta_id' => $rutaId
    ]);

    $ubicacionRepartidor = UbicacionRepartidor::create($insertData);

    UbicacionRepartidorUpdatedEvent::dispatch($ubicacionRepartidor);

    return ApiResponder::success(
      message: 'Ubicación del repartidor registrada exitosamente.',
      data: UbicacionRepartidorResource::make($ubicacionRepartidor),
    );
  }
}

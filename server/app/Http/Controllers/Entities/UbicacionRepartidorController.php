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

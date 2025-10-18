<?php

namespace App\Http\Controllers\Entities;

use App\Enums\EstadosPedidoEnum;
use App\Enums\EventosPedidoEnum;
use App\Enums\PermissionsEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Helpers\CollectionOrderManager;
use App\Http\Controllers\Controller;
use App\Http\Requests\Ruta\AddPedidoRutaRequest;
use App\Http\Requests\Ruta\IndexPedidosRutaRequest;
use App\Http\Requests\Ruta\IndexRutaRequest;
use App\Http\Requests\Ruta\OptimizeAllRutaRequest;
use App\Http\Requests\Ruta\OptimizeRutaRequest;
use App\Http\Requests\Ruta\ReorderPedidosRutaRequest;
use App\Http\Requests\Ruta\StoreRutaRequest;
use App\Http\Requests\Ruta\UpdateRutaRequest;
use App\Http\Resources\Ruta\PedidoRutaResource;
use App\Http\Resources\Ruta\RutaResource;
use App\Http\Resources\Ruta\RutaSimpleResource;
use App\Jobs\OptimizeEntregasPedidos;
use App\Jobs\OptimizeRutaEntregasPedidos;
use App\Models\EntregaPedido;
use App\Models\Pedido;
use App\Models\Ruta;
use App\Services\PedidoEventService;
use Auth;
use DB;
use Illuminate\Http\Request;

class RutaController extends Controller
{
  public function index(IndexRutaRequest $request)
  {
    $user = Auth::user();

    if ($user === null) {
      throw CustomException::unauthorized();
    }

    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();

    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $query = Ruta::query()
      ->select([
        'id',
        'nombre',
        'repartidor_id',
        'distancia_total_estimada',
        'tiempo_total_estimado',
        'cantidad_pedidos',
        'fecha_hora_calculo',
        'fecha_inicio',
        'fecha_completado',
        'created_at',
        'updated_at',
      ]);

    $query->with([
      'repartidor.user:id,name'
    ]);

    if (!$user->hasPermissionTo(PermissionsEnum::RUTAS_VIEW_ANY) && $user->hasPermissionTo(PermissionsEnum::RUTAS_VIEW_RELATED)) {
      if ($user->esRepartidor()) {
        $query->where('repartidor_id', '=', $user->id);
      }
    }

    if ($request->hasRepartidorId() && !$user->esRepartidor()) {
      $query->where('repartidor_id', '=', $request->getRepartidorId());
    }

    $fechaDesde = $request->getFechaDesde();
    $fechaHasta = $request->getFechaHasta();
    if ($fechaDesde !== null && $fechaHasta !== null) {
      $query->whereBetween('created_at', [$fechaDesde, $fechaHasta]);
    } elseif ($fechaDesde !== null) {
      $query->where('created_at', '>=', $fechaDesde);
    } elseif ($fechaHasta !== null) {
      $query->where('created_at', '<=', $fechaHasta);
    }

    $search = $request->getSearch();
    if ($request->hasSearch() && $search !== null) {
      $query->where(function ($q) use ($search) {
        $q->where('rutas.nombre', 'like', "%{$search}%");
      });
    }

    $query->orderBy($orderBy, $orderDirection);

    $pagination = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Mostrando lista de rutas.',
      data: RutaSimpleResource::collection($pagination->items()),
      pagination: $pagination
    );
  }

  public function store(StoreRutaRequest $request)
  {
    $validatedData = $request->validated();

    /** @var Ruta $ruta  */
    $ruta = Ruta::create($validatedData);

    $ruta->refresh();
    $ruta->load([
      'repartidor.user:id,name'
    ]);

    return ApiResponder::created(
      message: 'Ruta creada exitosamente.',
      data: RutaResource::make($ruta),
    );
  }

  private function getPedidosRuta(
    Ruta $ruta,
    string $orderBy,
    string $orderDirection,
    ?string $estadoFilter,
    ?string $optimizadoFilter,
  ) {
    $query = $ruta->pedidos()->select([
      'pedidos.id',
      'pedidos.codigo_barra',
      'pedidos.ubicacion_recojo',
      'pedidos.ubicacion_entrega',
      'pedidos.direccion_entrega_linea_1',
      'pedidos.paciente_nombre',
      'pedidos.paciente_telefono',
      'pedidos.observaciones',
      'pedidos.tipo_pedido',
      'pedidos.estado',
      'entregas_pedido.orden_optimizado',
      'entregas_pedido.orden_personalizado',
      'entregas_pedido.orden_recojo',
      'entregas_pedido.optimizado',
    ]);

    if ($estadoFilter !== null) {
      $query->where('pedidos.estado', $estadoFilter);
    }

    if ($optimizadoFilter !== null) {
      $query->where('entregas_pedido.optimizado', $optimizadoFilter);
    }

    $query->orderBy($orderBy, $orderDirection);

    $pedidos = $query->get();

    return $pedidos;
  }

  public function show(IndexPedidosRutaRequest $request, Ruta $ruta)
  {
    $user = Auth::user();

    if (!$user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_ANY) && $user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_RELATED)) {
      if ($user->esRepartidor()) {
        if ($user->id !== $ruta->repartidor_id) {
          throw CustomException::forbidden();
        }
      }
    }

    $pedidos = $this->getPedidosRuta(
      $ruta,
      $request->getOrderBy(),
      $request->getOrderDirection(),
      $request->getEstado(),
      $request->getOptimizado(),
    );

    $ruta->load([
      'repartidor.user:id,name'
    ]);

    return ApiResponder::success(
      message: 'Mostrando datos y lista de pedidos de la ruta.',
      data: [
        'ruta' => RutaResource::make($ruta),
        'pedidos' => PedidoRutaResource::collection($pedidos),
      ]
    );
  }

  public function miRuta(IndexPedidosRutaRequest $request)
  {
    $user = Auth::user();

    if ($user === null) {
      throw CustomException::unauthorized();
    }

    if (!$user->esRepartidor()) {
      throw CustomException::forbidden("Solo los usuarios repartidores pueden ver su ruta actual");
    }

    $ruta = $user->perfilRepartidor?->rutas()->orderBy('created_at', 'desc')->first();

    if ($ruta === null) {
      throw CustomException::notFound('El repartidor todavía no tiene ninguna ruta asignada');
    }

    $pedidos = $this->getPedidosRuta(
      $ruta,
      $request->getOrderBy(),
      $request->getOrderDirection(),
      $request->getEstado(),
      $request->getOptimizado(),
    );

    $ruta->load([
      'repartidor.user:id,name'
    ]);

    return ApiResponder::success(
      message: 'Mostrando datos y lista de pedidos de la ruta.',
      data: [
        'ruta' => RutaResource::make($ruta),
        'pedidos' => PedidoRutaResource::collection($pedidos),
      ]
    );
  }

  public function update(UpdateRutaRequest $request, Ruta $ruta)
  {
    $validatedData = $request->validated();

    if (sizeof($validatedData) === 0) {
      throw CustomException::badRequest('No se recibió información para actualizar');
    }

    DB::transaction(function () use ($ruta, $validatedData, $request) {
      $ruta->update($validatedData);

      if ($request->hasRepartidorId()) {
        $repartidorId = $request->getRepartidorId();
        $pedidos = $ruta
          ->pedidos()
          ->where(function ($query) use ($repartidorId) {
            $query->where('repartidor_id', '<>', $repartidorId)
              ->orWhereNull('repartidor_id');
          })
          ->get('id')
          ->pluck('id');

        if (count($pedidos) > 0) {
          Pedido::whereIn('id', $pedidos)
            ->update(['repartidor_id' => $request->getRepartidorId()]);

          // TODO: registrar los eventos para los pedidos actualizados
        }
      }
    });

    $ruta->load([
      // 'pedidos',
      'repartidor.user:id,name'
    ]);

    return ApiResponder::success(
      message: 'Ruta actualizada exitosamente.',
      data: RutaResource::make($ruta),
    );
  }

  public function destroy(Ruta $ruta)
  {
    $ruta->delete();

    return ApiResponder::noContent('Ruta eliminada correctamente.');
  }

  public function optimizarRuta(OptimizeRutaRequest $request, Ruta $ruta)
  {
    $user = Auth::user();

    if ($user === null) {
      throw CustomException::unauthorized();
    }

    OptimizeRutaEntregasPedidos::dispatch(
      $user->id,
      $ruta->id,
      $request->input('inicio_jornada'),
      $request->input('fin_jornada'),
    );

    return ApiResponder::accepted(
      message: 'Su solicitud está siendo procesada. Recibirás una notificación cuando los pedidos de la ruta hayan sido optimizados.'
    );
  }

  public function optimizarAll(OptimizeAllRutaRequest $request)
  {
    $user = Auth::user();

    if ($user === null) {
      throw CustomException::unauthorized();
    }

    OptimizeEntregasPedidos::dispatch(
      $user->id,
      $request->input('codigo_iso_pais'),
      $request->input('inicio_jornada'),
      $request->input('fin_jornada'),
      $request->input('codigo_postal'),
    );

    return ApiResponder::accepted(
      message: 'Su solicitud está siendo procesada. Recibirás una notificación cuando las rutas y pedidos hayan sido optimizados y asignados a los repartidores adecuados.'
    );
  }

  public function listPedidos(IndexPedidosRutaRequest $request, Ruta $ruta)
  {
    $user = Auth::user();

    if (!$user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_ANY) && $user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_RELATED)) {
      if ($user->esRepartidor()) {
        if ($user->id !== $ruta->repartidor_id) {
          throw CustomException::forbidden();
        }
      }
    }

    $pedidos = $this->getPedidosRuta(
      $ruta,
      $request->getOrderBy(),
      $request->getOrderDirection(),
      $request->getEstado(),
      $request->getOptimizado(),
    );

    return ApiResponder::success(
      message: 'Mostrando lista de pedidos de la ruta.',
      data: PedidoRutaResource::collection($pedidos),
    );
  }

  public function addPedido(AddPedidoRutaRequest $request, Ruta $ruta)
  {
    /** @var Pedido|null $pedido  */
    $pedido = Pedido::find($request->getPedidoId());

    if ($pedido === null) {
      throw CustomException::validationException(
        errors: $request->pedidoIdNotFound()
      );
    }

    /** @var EntregaPedido|null $existingEntregaPedido */
    $existingEntregaPedido = EntregaPedido::where('pedido_id', $pedido->id)->first();

    if ($existingEntregaPedido !== null) {
      if ($existingEntregaPedido->ruta_id === $ruta->id) {
        throw CustomException::conflict('El pedido ya ha sido agregado a esta ruta.');
      } else {
        throw CustomException::conflict('El pedido ya está asignado a otra ruta.');
      }
    }

    if ($pedido->estado !== EstadosPedidoEnum::PENDIENTE && $pedido->estado !== EstadosPedidoEnum::ASIGNADO) {
      throw CustomException::conflict('Solo pedidos con estado `pendiente` o `asignado` pueden ser agregados a una ruta.');
    }

    DB::transaction(function () use ($ruta, $pedido) {
      $lastOrden = $ruta->entregasPedido()->max('orden_personalizado');

      $nextOrden = $lastOrden ?? 0;
      $nextOrden++;

      EntregaPedido::create([
        'ruta_id' => $ruta->id,
        'pedido_id' => $pedido->id,
        'orden_optimizado' => null,
        'orden_personalizado' => $nextOrden,
        'orden_recojo' => null,
        'optimizado' => false,
      ]);

      PedidoEventService::logEventoPedido(
        pedido: $pedido,
        tipoEvento: EventosPedidoEnum::PEDIDO_ASIGNADO,
        user: Auth::user(),
        repartidorId: $ruta->repartidor_id
      );

      $ruta->increment('cantidad_pedidos');
    });

    return ApiResponder::success(
      message: 'El pedido ha sido agregado a la ruta.',
    );
  }

  public function removePedido(Request $request, Ruta $ruta, Pedido $pedido)
  {
    /** @var EntregaPedido $entregaPedido  */
    $entregaPedido = $ruta
      ->entregasPedido()
      ->where('pedido_id', $pedido->id)
      ->first();

    if ($entregaPedido === null) {
      throw CustomException::notFound('El pedido no fue encontrado en la ruta especificada.');
    }

    $needsPersonalizedOrderRecalculation = $entregaPedido->orden_personalizado < $ruta->cantidad_pedidos;
    $needsRecojoOrderRecalculation = $entregaPedido->orden_recojo !== null && $entregaPedido->orden_recojo < $ruta->cantidad_pedidos;

    DB::transaction(function () use (
      $ruta,
      $entregaPedido,
      $needsPersonalizedOrderRecalculation,
      $needsRecojoOrderRecalculation
    ) {
      $entregaPedido->delete();
      $ruta->decrement('cantidad_pedidos');

      if ($needsPersonalizedOrderRecalculation) {
        $ruta->entregasPedido()
          ->where('orden_personalizado', '>', $entregaPedido->orden_personalizado)
          ->update([
            'orden_personalizado' => DB::raw('orden_personalizado - 1'),
          ]);
      }

      if ($needsRecojoOrderRecalculation) {
        $ruta->entregasPedido()
          ->whereNotNull('orden_recojo')
          ->where('orden_recojo', '>', $entregaPedido->orden_recojo)
          ->update([
            'orden_recojo' => DB::raw('orden_recojo - 1'),
          ]);
      }
    });

    return ApiResponder::success(
      message: 'El pedido ha sido removido de la ruta.',
    );
  }

  public function reordenarPedidos(ReorderPedidosRutaRequest $request, Ruta $ruta)
  {
    if (!$request->hasPedidosInRoute() && $request->getClientUpdatesMapped()->isEmpty()) {
      return ApiResponder::success('La ruta está vacía, no hay pedidos que reordenar.');
    }

    $existingEntregas = $request->getExistingEntregas();

    $clientUpdatesMap = $request->getClientUpdatesMapped();
    $changesMapForManager = $clientUpdatesMap->mapWithKeys(function ($updateData) {
      return [
        $updateData[ReorderPedidosRutaRequest::PEDIDO_ID_FIELD_KEY] => $updateData[ReorderPedidosRutaRequest::NEW_ORDER_FIELD_KEY]
      ];
    })->toArray();

    $calculatedOrdersCollection = CollectionOrderManager::calculateNewOrders(
      $existingEntregas,
      $changesMapForManager,
      fn($entrega) => $entrega->pedido_id,
      1
    );

    $existingEntregasByPedidoId = $existingEntregas->keyBy('pedido_id');

    $updatesToPerform = [];

    foreach ($calculatedOrdersCollection as $calculatedItem) {
      $pedidoId = $calculatedItem->id;
      $newOrder = $calculatedItem->newOrder;

      $originalEntrega = $existingEntregasByPedidoId->get($pedidoId);

      if ($originalEntrega !== null && $originalEntrega->orden_personalizado !== $newOrder) {
        $updatesToPerform[] = [
          'id' => $originalEntrega->id,
          'orden_personalizado' => $newOrder,
        ];
      }
    }

    $updatesCount = count($updatesToPerform);

    if ($updatesCount > 0) {
      EntregaPedido::massUpdate(
        values: $updatesToPerform
      );
    }

    return ApiResponder::success(
      message: 'El orden de la ruta ha sido actualizado exitosamente.',
    );
  }
}

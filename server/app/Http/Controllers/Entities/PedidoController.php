<?php

namespace App\Http\Controllers\Entities;

use App\Enums\EventosPedidoEnum;
use App\Enums\MotivosFalloPedidoEnum;
use App\Enums\PermissionsEnum;
use App\Events\Pedido\PedidoEntregadoEvent;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Helpers\OrderCodeGenerator;
use App\Helpers\PrepareData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Pedido\Evento\EntregarPedidoRequest;
use App\Http\Requests\Pedido\IndexPedidoRequest;
use App\Http\Requests\Pedido\StorePedidoRequest;
use App\Http\Requests\Pedido\UpdatePedidoRequest;
use App\Http\Requests\UploadCsvFileRequest;
use App\Http\Resources\Pedido\PedidoResource;
use App\Http\Resources\Pedido\PedidoSimpleResource;
use App\Jobs\ProcessPedidosCsv;
use App\Models\Pedido;
use App\Models\PerfilRepartidor;
use App\Rules\LocationArray;
use App\Services\Disk\PrivateUploadsDiskService;
use App\Services\PedidoEventService;
use DB;
use Illuminate\Support\Facades\Auth;
use Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Http\Request;

class PedidoController extends Controller
{
  public function index(IndexPedidoRequest $request)
  {
    $user = Auth::user();

    if ($user === null) {
      throw CustomException::unauthorized();
    }

    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();

    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $query = Pedido::query()->select([
      'pedidos.id',
      'pedidos.codigo_barra',
      'pedidos.paciente_nombre',
      'pedidos.paciente_telefono',
      'pedidos.direccion_entrega_linea_1',
      'pedidos.ciudad_entrega',
      'pedidos.estado_region_entrega',
      'pedidos.ubicacion_entrega',
      'pedidos.estado',
      'pedidos.fecha_asignacion',
      'pedidos.fecha_recogida',
      'pedidos.fecha_entrega',
      'pedidos.created_at',
      'pedidos.updated_at',
      // 'pedidos.farmacia_id',
      'pedidos.repartidor_id',
    ]);

    $query->with([
      //   'farmacia:id,nombre',
      'repartidor.user:id,name'
    ]);

    if (!$user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_ANY) && $user->hasPermissionTo(PermissionsEnum::PEDIDOS_VIEW_RELATED)) {
      if ($user->esFarmacia() && $user->perfilFarmacia?->farmacia_id !== null) {
        $farmaciaId = $user->perfilFarmacia->farmacia_id;
        $query->where('farmacia_id', $farmaciaId);
      } elseif ($user->esRepartidor()) {
        $repartidorId = $user->id;
        $query->where('repartidor_id', $repartidorId);
      }
    }

    $estadoFilter = $request->getEstadoFilter();
    if ($estadoFilter !== null) {
      $query->whereIn('estado', $estadoFilter);
    }

    if ($request->hasRepartidorId() && !$user->esRepartidor()) {
      $query->where('repartidor_id', $request->getRepartidorId());
    }

    if ($request->hasFarmaciaId() && !$user->esFarmacia()) {
      $query->where('farmacia_id', $request->getFarmaciaId());
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

    $searchTerm = $request->getSearch();
    if ($searchTerm !== null && $searchTerm !== '') {
      $query->where(function ($q) use ($searchTerm) {
        $q->where('paciente_nombre', 'LIKE', "%{$searchTerm}%")
          ->orWhere('codigo_barra', 'LIKE', "%{$searchTerm}%")
          ->orWhere('paciente_telefono', 'LIKE', "%{$searchTerm}%")
          ->orWhere('id', 'LIKE', "%{$searchTerm}%")
          ->orWhere('direccion_entrega_linea_1', 'LIKE', "%{$searchTerm}%")
          ->orWhere('ciudad_entrega', 'LIKE', "%{$searchTerm}%");
      });
    }

    $query->orderBy($orderBy, $orderDirection);

    $pagination = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Mostrando lista de pedidos.',
      data: PedidoSimpleResource::collection($pagination->items()),
      pagination: $pagination
    );
  }

  public function store(StorePedidoRequest $request)
  {
    $user = Auth::user();

    if (
      !$user->hasPermissionTo(PermissionsEnum::PEDIDOS_CREATE_ANY)
      && $user->hasPermissionTo(PermissionsEnum::PEDIDOS_CREATE_RELATED)
    ) {
      $userFarmaciaId  = $user->perfilFarmacia?->farmacia_id;
      if (!$user->esFarmacia() || $userFarmaciaId === null || $userFarmaciaId !== $request->getFarmaciaId()) {
        throw CustomException::forbidden();
      }
    }

    $validatedData = $request->validated();
    $farmacia = $request->getFarmacia();

    $pedidoData = array_merge($validatedData, [
      'codigo_iso_pais_entrega' => $farmacia?->codigo_iso_pais,
      'codigo_barra' => OrderCodeGenerator::generateOrderCode(),
    ]);

    /** @var Pedido $pedido  */
    $pedido = DB::transaction(function () use ($pedidoData) {
      /** @var Pedido $pedido  */
      $pedido = Pedido::create($pedidoData);

      PedidoEventService::logEventoPedido(
        pedido: $pedido,
        tipoEvento: EventosPedidoEnum::PEDIDO_CREADO,
        user: Auth::user(),
      );

      return $pedido;
    });

    $pedido->refresh();

    return ApiResponder::created(
      message: 'Pedido creado exitosamente.',
      data: PedidoResource::make($pedido)
    );
  }

  public function show(Pedido $pedido)
  {
    $pedido->load([
      'farmacia:id,nombre',
      'repartidor.user:id,name',
    ]);

    return ApiResponder::success(
      message: 'Mostrando datos del pedido',
      data: PedidoResource::make($pedido)
    );
  }

  public function update(UpdatePedidoRequest $request, Pedido $pedido)
  {
    $validatedData = $request->validated();

    // TODO: validate the status of the order, I guess that the order is not suposed to be updated in any state

    if (sizeof($validatedData) === 0) {
      throw CustomException::badRequest('No se recibió información para actualizar');
    }

    $pedido->update($validatedData);

    return ApiResponder::success(
      message: 'Pedido actualizado exitosamente.',
      data: PedidoResource::make($pedido)
    );
  }

  public function destroy(Pedido $pedido)
  {
    $pedido->delete();

    return ApiResponder::noContent('Pedido eliminado correctamente.');
  }

  public function uploadCsv(UploadCsvFileRequest $request)
  {
    $user = Auth::user();

    if ($user === null) {
      throw CustomException::unauthorized();
    }

    if (
      !$user->hasPermissionTo(PermissionsEnum::PEDIDOS_CREATE_ANY)
      && $user->hasPermissionTo(PermissionsEnum::PEDIDOS_CREATE_RELATED)
    ) {
      $userFarmaciaId  = $user->perfilFarmacia?->farmacia_id;
      if (!$user->esFarmacia() || $userFarmaciaId === null || $userFarmaciaId !== $request->getFarmaciaId()) {
        throw CustomException::forbidden();
      }
    }

    $file = $request->file('pedidos_csv');

    $filename = Str::uuid() . '.csv';
    $path = $file->storeAs('temp_csv_uploads', $filename);
    $fullPath = Storage::disk()->path($path);

    ProcessPedidosCsv::dispatch($fullPath, $user->id, $request->getFarmaciaId());

    return ApiResponder::accepted(
      message: 'El archivo CSV ha sido recibido y será procesado, recibirás una notificación cuando termine.',
    );
  }

  public function asignar(Request $request, Pedido $pedido)
  {
    $request->validate([
      'repartidor_id' => ['required', 'uuid', Rule::exists(PerfilRepartidor::class, 'id')],
    ]);

    $user = Auth::user();
    $repartidorId = $request->input('repartidor_id');

    if ($user->esRepartidor() && $user->id !== $repartidorId) {
      throw CustomException::forbidden();
    }

    // validate if delivery account is verified, only verified deliveries should be able receive orders

    $tipoEvento = $pedido->repartidor_id === null
      ? EventosPedidoEnum::PEDIDO_ASIGNADO
      : EventosPedidoEnum::PEDIDO_REASIGNADO;

    PedidoEventService::logEventoPedido(
      pedido: $pedido,
      tipoEvento: $tipoEvento,
      user: $user,
      metadata: [
        'repartidor_id' => $request->input('repartidor_id')
      ],
      repartidorId: $repartidorId,
    );

    $pedido->refresh();

    return ApiResponder::success(
      message: 'Pedido asignado exitosamente.',
      data: PedidoResource::make($pedido),
    );
  }

  public function retirarRepartidor(Request $request, Pedido $pedido)
  {
    $tipoEvento = EventosPedidoEnum::PEDIDO_ASIGNACION_RETIRADA;

    PedidoEventService::logEventoPedido(
      pedido: $pedido,
      tipoEvento: $tipoEvento,
      user: Auth::user(),
      clearRepartidor: true,
    );

    $pedido->refresh();

    return ApiResponder::success(
      message: 'La asignación del pedido ha sido retirada exitosamente.',
      data: PedidoResource::make($pedido),
    );
  }

  public function cancelar(Request $request, Pedido $pedido)
  {
    $tipoEvento = EventosPedidoEnum::PEDIDO_CANCELADO;

    PedidoEventService::logEventoPedido(
      pedido: $pedido,
      tipoEvento: $tipoEvento,
      user: Auth::user(),
    );

    $pedido->refresh();

    return ApiResponder::success(
      message: 'El pedido ha sido cancelado.',
      data: PedidoResource::make($pedido),
    );
  }

  public function recoger(Request $request, Pedido $pedido)
  {
    $ubicacionField = 'ubicacion';
    $ubicacion = $request->input($ubicacionField);
    if ($request->has($ubicacionField)) {
      $ubicacion = PrepareData::location($request->input($ubicacionField));
      if (!is_null($ubicacion)) {
        $request->merge([$ubicacionField => $ubicacion]);
      }
    }

    $request->validate([
      $ubicacionField => ['sometimes', new LocationArray],
    ]);

    $tipoEvento = EventosPedidoEnum::PEDIDO_RECOGIDO;

    PedidoEventService::logEventoPedido(
      pedido: $pedido,
      tipoEvento: $tipoEvento,
      user: Auth::user(),
      ubicacion: $ubicacion
    );

    $pedido->refresh();

    return ApiResponder::success(
      message: 'Se ha marcado el pedido como recogido.',
      data: PedidoResource::make($pedido),
    );
  }

  public function enRuta(Request $request, Pedido $pedido)
  {
    $tipoEvento = EventosPedidoEnum::PEDIDO_EN_RUTA;

    PedidoEventService::logEventoPedido(
      pedido: $pedido,
      tipoEvento: $tipoEvento,
      user: Auth::user(),
    );

    $pedido->refresh();

    return ApiResponder::success(
      message: 'Se ha marcado el pedido como en ruta.',
      data: PedidoResource::make($pedido),
    );
  }

  public function entregar(EntregarPedidoRequest $request, Pedido $pedido)
  {
    $tipoEvento = EventosPedidoEnum::PEDIDO_ENTREGADO;
    $pedidoData = $request->getPedidoData();
    $ubicacion = $request->getUbicacion();

    $fotoEntregaPath = null;

    try {
      if ($request->hasFile('foto_entrega')) {
        $fotoEntrega = $request->file('foto_entrega');

        $fotoEntregaPath = PrivateUploadsDiskService::saveImage(
          imgPath: $fotoEntrega->getRealPath(),
          prefix: 'p-f-',
          width: 2000,
          height: 2000,
        );
      }

      $pedidoData = array_merge($pedidoData, [
        'foto_entrega_path' => $fotoEntregaPath
      ]);

      $pedido = DB::transaction(function () use (
        $pedido,
        $tipoEvento,
        $pedidoData,
        $ubicacion,
      ) {
        $pedido->update($pedidoData);

        PedidoEventService::logEventoPedido(
          pedido: $pedido,
          tipoEvento: $tipoEvento,
          user: Auth::user(),
          ubicacion: $ubicacion,
        );

        return $pedido;
      });

      $pedido->refresh();

      PedidoEntregadoEvent::dispatch($pedido);

      return ApiResponder::success(
        message: 'El pedido ha sido marcado como entregado.',
        data: PedidoResource::make($pedido),
      );
    } catch (\Throwable $e) {
      if ($e instanceof CustomException) {
        throw $e;
      }

      if ($fotoEntregaPath !== null) {
        PrivateUploadsDiskService::delete($fotoEntregaPath);
      }

      throw CustomException::internalServer(
        'Error inesperado al intentar guardar la foto de entrega.',
        $e,
      );
    }
  }

  public function falloEntrega(Request $request, Pedido $pedido)
  {
    $ubicacionField = 'ubicacion';
    $ubicacion = $request->input($ubicacionField);
    if ($request->has($ubicacionField)) {
      $ubicacion = PrepareData::location($request->input($ubicacionField));
      if (!is_null($ubicacion)) {
        $request->merge([$ubicacionField => $ubicacion]);
      }
    }

    $request->validate([
      $ubicacionField => ['required', new LocationArray],
      'motivo_fallo' => ['required', 'string', Rule::in(MotivosFalloPedidoEnum::cases())],
      'observaciones_fallo' => ['sometimes', 'nullable', 'string', 'max:1000'],
    ]);

    $tipoEvento = EventosPedidoEnum::PEDIDO_ENTREGA_FALLIDA;

    PedidoEventService::logEventoPedido(
      pedido: $pedido,
      tipoEvento: $tipoEvento,
      user: Auth::user(),
      metadata: [
        'motivo_fallo' => $request->input('motivo_fallo'),
        'observaciones_fallo' => $request->input('observaciones_fallo'),
      ],
      ubicacion: $ubicacion
    );

    $pedido->refresh();

    return ApiResponder::success(
      message: 'El pedido ha sido marcado como fallido.',
      data: PedidoResource::make($pedido),
    );
  }
}

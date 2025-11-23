<?php

namespace App\Http\Controllers\Entities;

use App\Casts\AsPoint;
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
use App\Http\Resources\Pedido\PedidoRepartidorResource;
use App\Http\Resources\Pedido\PedidoResource;
use App\Http\Resources\Pedido\PedidoSimpleResource;
use App\Jobs\Pedido\DeleteOldPedidoFilesJob;
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
  /**
   * Listar pedidos.
   *
   * @OA\Get(
   *     path="/api/pedidos",
   *     operationId="pedidosIndex",
   *     tags={"Entities","Pedidos"},
   *     summary="Listar pedidos",
   *     description="Obtiene una lista paginada de pedidos. Las farmacias y repartidores solo ven sus propios pedidos.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="page",
   *         in="query",
   *         required=false,
   *         description="Número de página (por defecto: 1)",
   *         @OA\Schema(type="integer", example=1)
   *     ),
   *     @OA\Parameter(
   *         name="per_page",
   *         in="query",
   *         required=false,
   *         description="Cantidad de registros por página (por defecto: 15, máximo: 100)",
   *         @OA\Schema(type="integer", example=15)
   *     ),
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo para ordenamiento",
   *         @OA\Schema(type="string", enum={"created_at","updated_at","tipo_pedido","estado","fecha_asignacion","fecha_recogida","fecha_entrega","tiempo_entrega_estimado","distancia_estimada"}, example="updated_at")
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="desc")
   *     ),
   *     @OA\Parameter(
   *         name="estado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por estado(s), puede ser un estado o múltiples separados por coma",
   *         @OA\Schema(type="string", example="pendiente,asignado")
   *     ),
   *     @OA\Parameter(
   *         name="repartidor_id",
   *         in="query",
   *         required=false,
   *         description="Filtrar por UUID del repartidor (solo para administradores)",
   *         @OA\Schema(type="string", format="uuid")
   *     ),
   *     @OA\Parameter(
   *         name="farmacia_id",
   *         in="query",
   *         required=false,
   *         description="Filtrar por UUID de la farmacia (solo para administradores)",
   *         @OA\Schema(type="string", format="uuid")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_desde",
   *         in="query",
   *         required=false,
   *         description="Filtrar pedidos creados desde esta fecha",
   *         @OA\Schema(type="string", format="date", example="2024-01-01")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_hasta",
   *         in="query",
   *         required=false,
   *         description="Filtrar pedidos creados hasta esta fecha",
   *         @OA\Schema(type="string", format="date", example="2024-12-31")
   *     ),
   *     @OA\Parameter(
   *         name="search",
   *         in="query",
   *         required=false,
   *         description="Buscar por nombre del paciente, código de barra, teléfono, dirección o ciudad",
   *         @OA\Schema(type="string", example="Juan Pérez")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de pedidos obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando lista de pedidos."),
   *             @OA\Property(property="data", type="array",
   *                 items=@OA\Items(type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="codigo_barra", type="string"),
   *                     @OA\Property(property="paciente_nombre", type="string"),
   *                     @OA\Property(property="paciente_telefono", type="string"),
   *                     @OA\Property(property="direccion_entrega_linea_1", type="string"),
   *                     @OA\Property(property="ciudad_entrega", type="string"),
   *                     @OA\Property(property="estado", type="string", enum={"pendiente","asignado","en_ruta","entregado","rechazado"}),
   *                     @OA\Property(property="created_at", type="string", format="date-time"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time")
   *                 )
   *             ),
   *             @OA\Property(property="pagination", type="object", ref="#/components/schemas/PaginationInfo")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Crear un nuevo pedido.
   *
   * @OA\Post(
   *     path="/api/pedidos",
   *     operationId="pedidosStore",
   *     tags={"Entities","Pedidos"},
   *     summary="Crear pedido",
   *     description="Crea un nuevo pedido. Las farmacias solo pueden crear pedidos para sí mismas.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"paciente_nombre","paciente_telefono","direccion_entrega_linea_1","ciudad_entrega","tipo_pedido"},
   *             @OA\Property(property="farmacia_id", type="string", format="uuid", nullable=true, description="UUID de la farmacia"),
   *             @OA\Property(property="paciente_nombre", type="string", maxLength=255),
   *             @OA\Property(property="paciente_telefono", type="string", description="Formato E.164 (+país-número)"),
   *             @OA\Property(property="paciente_email", type="string", format="email", nullable=true),
   *             @OA\Property(property="codigo_iso_pais_entrega", type="string", example="PE", description="Requerido si no se especifica farmacia_id"),
   *             @OA\Property(property="direccion_entrega_linea_1", type="string", maxLength=255),
   *             @OA\Property(property="direccion_entrega_linea_2", type="string", nullable=true, maxLength=255),
   *             @OA\Property(property="ciudad_entrega", type="string", maxLength=255),
   *             @OA\Property(property="estado_region_entrega", type="string", nullable=true),
   *             @OA\Property(property="codigo_postal_entrega", type="string", nullable=true, maxLength=20),
   *             @OA\Property(property="ubicacion_recojo", type="object", nullable=true,
   *                 @OA\Property(property="latitude", type="number", format="float"),
   *                 @OA\Property(property="longitude", type="number", format="float")
   *             ),
   *             @OA\Property(property="ubicacion_entrega", type="object", nullable=true,
   *                 @OA\Property(property="latitude", type="number", format="float"),
   *                 @OA\Property(property="longitude", type="number", format="float")
   *             ),
   *             @OA\Property(property="codigo_acceso_edificio", type="string", nullable=true, maxLength=20),
   *             @OA\Property(property="medicamentos", type="string", nullable=true, maxLength=1000),
   *             @OA\Property(property="tipo_pedido", type="string", maxLength=255),
   *             @OA\Property(property="observaciones", type="string", nullable=true, maxLength=1000),
   *             @OA\Property(property="requiere_firma_especial", type="boolean", nullable=true),
   *             @OA\Property(property="tiempo_entrega_estimado", type="integer", nullable=true, minimum=1),
   *             @OA\Property(property="distancia_estimada", type="number", nullable=true, minimum=0)
   *         )
   *     ),
   *     @OA\Response(
   *         response=201,
   *         description="Pedido creado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Pedido creado exitosamente."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=403,
   *         description="Acceso prohibido",
   *         @OA\JsonContent(ref="#/components/schemas/ForbiddenResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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
      'codigo_iso_pais_entrega' => $request->getCodigoIsoPaisEntrega() ?? $farmacia?->codigo_iso_pais,
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

  /**
   * Obtener detalles de un pedido.
   *
   * @OA\Get(
   *     path="/api/pedidos/{pedido}",
   *     operationId="pedidosShow",
   *     tags={"Entities","Pedidos"},
   *     summary="Obtener detalles del pedido",
   *     description="Obtiene la información completa de un pedido. Los repartidores ven una vista diferente con información de entrega.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Detalles del pedido obtenidos exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando datos del pedido"),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function show(Pedido $pedido)
  {
    $pedido->load([
      'farmacia:id,nombre',
      'repartidor.user:id,name',
    ]);

    $user = Auth::user();

    if ($user === null) {
      throw CustomException::unauthorized();
    }

    $isDelivery = $user->esRepartidor();

    $pedidoResource = null;
    if ($isDelivery) {
      $pedidoResource = PedidoRepartidorResource::make($pedido);
    } else {
      $pedidoResource = PedidoResource::make($pedido);
    }

    return ApiResponder::success(
      message: 'Mostrando datos del pedido',
      data: $pedidoResource
    );
  }

  /**
   * Actualizar un pedido.
   *
   * @OA\Patch(
   *     path="/api/pedidos/{pedido}",
   *     operationId="pedidosUpdate",
   *     tags={"Entities","Pedidos"},
   *     summary="Actualizar pedido",
   *     description="Actualiza los datos de un pedido existente.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             @OA\Property(property="paciente_nombre", type="string", maxLength=255),
   *             @OA\Property(property="paciente_telefono", type="string"),
   *             @OA\Property(property="paciente_email", type="string", format="email", nullable=true),
   *             @OA\Property(property="direccion_entrega_linea_1", type="string", maxLength=255),
   *             @OA\Property(property="direccion_entrega_linea_2", type="string", nullable=true),
   *             @OA\Property(property="ciudad_entrega", type="string", maxLength=255),
   *             @OA\Property(property="estado_region_entrega", type="string", nullable=true),
   *             @OA\Property(property="codigo_postal_entrega", type="string", nullable=true, maxLength=20),
   *             @OA\Property(property="ubicacion_recojo", type="object", nullable=true),
   *             @OA\Property(property="ubicacion_entrega", type="object", nullable=true),
   *             @OA\Property(property="codigo_acceso_edificio", type="string", nullable=true, maxLength=20),
   *             @OA\Property(property="medicamentos", type="string", nullable=true, maxLength=1000),
   *             @OA\Property(property="tipo_pedido", type="string", maxLength=255),
   *             @OA\Property(property="observaciones", type="string", nullable=true, maxLength=1000),
   *             @OA\Property(property="requiere_firma_especial", type="boolean", nullable=true),
   *             @OA\Property(property="tiempo_entrega_estimado", type="integer", nullable=true, minimum=1),
   *             @OA\Property(property="distancia_estimada", type="number", nullable=true, minimum=0)
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido actualizado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Pedido actualizado exitosamente."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=400,
   *         description="Solicitud inválida",
   *         @OA\JsonContent(ref="#/components/schemas/BadRequestResponse")
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Eliminar un pedido.
   *
   * @OA\Delete(
   *     path="/api/pedidos/{pedido}",
   *     operationId="pedidosDestroy",
   *     tags={"Entities","Pedidos"},
   *     summary="Eliminar pedido",
   *     description="Elimina un pedido del sistema.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=204,
   *         description="Pedido eliminado exitosamente"
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function destroy(Pedido $pedido)
  {
    $pedido->delete();

    return ApiResponder::noContent('Pedido eliminado correctamente.');
  }

  /**
   * Cargar pedidos desde archivo CSV.
   *
   * @OA\Post(
   *     path="/api/pedidos/cargar-csv",
   *     operationId="pedidosUploadCsv",
   *     tags={"Entities","Pedidos"},
   *     summary="Cargar pedidos por CSV",
   *     description="Carga múltiples pedidos desde un archivo CSV. El procesamiento es asíncrono.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\MediaType(
   *             mediaType="multipart/form-data",
   *             @OA\Schema(
   *                 required={"pedidos_csv"},
   *                 @OA\Property(property="pedidos_csv", type="string", format="binary", description="Archivo CSV"),
   *                 @OA\Property(property="farmacia_id", type="string", format="uuid", nullable=true),
   *                 @OA\Property(property="codigo_iso_pais_entrega", type="string", example="PE", nullable=true)
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=202,
   *         description="Archivo CSV aceptado para procesamiento",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El archivo CSV ha sido recibido y será procesado, recibirás una notificación cuando termine."),
   *             @OA\Property(property="data", type="null")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=403,
   *         description="Acceso prohibido",
   *         @OA\JsonContent(ref="#/components/schemas/ForbiddenResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

    $farmacia = $request->getFarmacia();
    $farmaciaId = $farmacia?->id;
    $codigoIsoPaisEntrega = $farmacia?->codigo_iso_pais ?? $request->getCodigoIsoPaisEntrega();
    $ubicacionRecojo = AsPoint::serializeValue($farmacia?->ubicacion) ?? $request->getUbicacionRecojo();

    ProcessPedidosCsv::dispatch(
      $fullPath,
      $user->id,
      $farmaciaId,
      $codigoIsoPaisEntrega,
      $ubicacionRecojo,
    );

    return ApiResponder::accepted(
      message: 'El archivo CSV ha sido recibido y será procesado, recibirás una notificación cuando termine.',
    );
  }

  /**
   * Asignar un pedido a un repartidor.
   *
   * @OA\Patch(
   *     path="/api/pedidos/{pedido}/asignar",
   *     operationId="pedidosAsignar",
   *     tags={"Entities","Pedidos"},
   *     summary="Asignar pedido",
   *     description="Asigna un pedido a un repartidor. Si el pedido ya estaba asignado, se reasigna.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"repartidor_id"},
   *             @OA\Property(property="repartidor_id", type="string", format="uuid", description="UUID del perfil del repartidor")
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido asignado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Pedido asignado exitosamente."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=403,
   *         description="Acceso prohibido",
   *         @OA\JsonContent(ref="#/components/schemas/ForbiddenResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido o repartidor no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Retirar asignación de repartidor.
   *
   * @OA\Patch(
   *     path="/api/pedidos/{pedido}/retirar-repartidor",
   *     operationId="pedidosRetirarRepartidor",
   *     tags={"Entities","Pedidos"},
   *     summary="Retirar asignación",
   *     description="Retira la asignación de repartidor de un pedido, dejándolo sin asignar.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Asignación retirada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="La asignación del pedido ha sido retirada exitosamente."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Cancelar un pedido.
   *
   * @OA\Patch(
   *     path="/api/pedidos/{pedido}/cancelar",
   *     operationId="pedidosCancelar",
   *     tags={"Entities","Pedidos"},
   *     summary="Cancelar pedido",
   *     description="Marca un pedido como cancelado.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido cancelado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El pedido ha sido cancelado."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Marcar pedido como recogido.
   *
   * @OA\Patch(
   *     path="/api/pedidos/{pedido}/recoger",
   *     operationId="pedidosRecoger",
   *     tags={"Entities","Pedidos"},
   *     summary="Marcar como recogido",
   *     description="Marca un pedido como recogido en la farmacia, registrando la ubicación de recojo.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             @OA\Property(property="ubicacion", type="object", nullable=true,
   *                 @OA\Property(property="latitude", type="number", format="float"),
   *                 @OA\Property(property="longitude", type="number", format="float")
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido marcado como recogido",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Se ha marcado el pedido como recogido."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Marcar pedido como en ruta.
   *
   * @OA\Patch(
   *     path="/api/pedidos/{pedido}/en-ruta",
   *     operationId="pedidosEnRuta",
   *     tags={"Entities","Pedidos"},
   *     summary="Marcar como en ruta",
   *     description="Marca un pedido como en ruta para entrega.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido marcado como en ruta",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Se ha marcado el pedido como en ruta."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Marcar pedido como entregado.
   *
   * @OA\Post(
   *     path="/api/pedidos/{pedido}/entregar",
   *     operationId="pedidosEntregar",
   *     tags={"Entities","Pedidos"},
   *     summary="Marcar como entregado",
   *     description="Marca un pedido como entregado, incluyendo foto de entrega y firmas digitales opcionales.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\MediaType(
   *             mediaType="multipart/form-data",
   *             @OA\Schema(
   *                 required={"ubicacion"},
   *                 @OA\Property(property="ubicacion", type="object",
   *                     @OA\Property(property="latitude", type="number", format="float"),
   *                     @OA\Property(property="longitude", type="number", format="float")
   *                 ),
   *                 @OA\Property(property="foto_entrega", type="string", format="binary", description="Foto de la entrega (máx 5MB, JPEG/PNG/WEBP)"),
   *                 @OA\Property(property="firma_digital", type="string", nullable=true, description="Firma digital en SVG"),
   *                 @OA\Property(property="firma_documento_consentimiento", type="string", nullable=true, description="Firma de consentimiento en SVG")
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido marcado como entregado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El pedido ha sido marcado como entregado."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Marcar pedido con fallo de entrega.
   *
   * @OA\Patch(
   *     path="/api/pedidos/{pedido}/fallo-entrega",
   *     operationId="pedidosFalloEntrega",
   *     tags={"Entities","Pedidos"},
   *     summary="Marcar como fallo de entrega",
   *     description="Marca un pedido como no entregado, incluyendo ubicación, motivo del fallo y observaciones.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"ubicacion","motivo_fallo"},
   *             @OA\Property(property="ubicacion", type="object",
   *                 @OA\Property(property="latitude", type="number", format="float"),
   *                 @OA\Property(property="longitude", type="number", format="float")
   *             ),
   *             @OA\Property(property="motivo_fallo", type="string", enum={"puerta_cerrada","cliente_ausente","direccion_incorrecta","cliente_rechazo","otro"}, description="Razón del fallo de entrega"),
   *             @OA\Property(property="observaciones_fallo", type="string", nullable=true, maxLength=1000, description="Notas adicionales sobre el fallo")
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido marcado como fallo de entrega",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El pedido ha sido marcado como fallido."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Eliminar fotos y firmas de pedidos antiguos.
   *
   * @OA\Delete(
   *     path="/api/pedidos/antiguos",
   *     operationId="pedidosDeleteAntiguos",
   *     tags={"Entities","Pedidos"},
   *     summary="Eliminar archivos antiguos",
   *     description="Inicia un proceso asíncrono para eliminar fotos y firmas de pedidos antiguos (más de X semanas).",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="semanas",
   *         in="query",
   *         required=false,
   *         description="Número de semanas atrás para considerar 'antiguo' (por defecto: 3, máximo: 52)",
   *         @OA\Schema(type="integer", minimum=1, maximum=52, example=3)
   *     ),
   *     @OA\Response(
   *         response=202,
   *         description="Proceso de eliminación iniciado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="La eliminación de fotos y firmas de pedidos antiguos ha sido iniciada."),
   *             @OA\Property(property="data", type="null")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Datos de validación inválidos",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function deleteAntiguos(Request $request)
  {
    $request->validate([
      'semanas' => ['sometimes', 'integer', 'min:1', 'max:52'],
    ]);

    $semanas = (int) $request->input('semanas', 3);

    DeleteOldPedidoFilesJob::dispatch($semanas);

    return ApiResponder::accepted(
      message: 'La eliminación de fotos y firmas de pedidos antiguos ha sido iniciada.'
    );
  }
}

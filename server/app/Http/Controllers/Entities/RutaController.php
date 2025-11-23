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
  /**
   * Listar rutas de entrega.
   *
   * @OA\Get(
   *     path="/api/rutas",
   *     operationId="rutasIndex",
   *     tags={"Entities","Rutas"},
   *     summary="Listar rutas",
   *     description="Obtiene una lista paginada de rutas de entrega. Los repartidores solo pueden ver sus propias rutas.",
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
   *         description="Cantidad de registros por página (por defecto: 15)",
   *         @OA\Schema(type="integer", example=15)
   *     ),
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo para ordenamiento",
   *         @OA\Schema(type="string", enum={"created_at","updated_at","nombre","distancia_total_estimada","tiempo_total_estimado","fecha_hora_calculo","fecha_inicio","fecha_completado"}, example="created_at")
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="desc")
   *     ),
   *     @OA\Parameter(
   *         name="repartidor_id",
   *         in="query",
   *         required=false,
   *         description="Filtrar por UUID del repartidor (solo disponible para administradores)",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_desde",
   *         in="query",
   *         required=false,
   *         description="Filtrar rutas creadas desde esta fecha",
   *         @OA\Schema(type="string", format="date", example="2024-01-01")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_hasta",
   *         in="query",
   *         required=false,
   *         description="Filtrar rutas creadas hasta esta fecha",
   *         @OA\Schema(type="string", format="date", example="2024-12-31")
   *     ),
   *     @OA\Parameter(
   *         name="search",
   *         in="query",
   *         required=false,
   *         description="Buscar por nombre de la ruta",
   *         @OA\Schema(type="string", example="Ruta Centro")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de rutas obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando lista de rutas."),
   *             @OA\Property(property="data", type="array",
   *                 items=@OA\Items(type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="nombre", type="string"),
   *                     @OA\Property(property="distancia_total_estimada", type="number", format="float"),
   *                     @OA\Property(property="tiempo_total_estimado", type="integer", description="En segundos"),
   *                     @OA\Property(property="cantidad_pedidos", type="integer"),
   *                     @OA\Property(property="fecha_hora_calculo", type="string", format="date-time", nullable=true),
   *                     @OA\Property(property="fecha_inicio", type="string", format="date-time", nullable=true),
   *                     @OA\Property(property="fecha_completado", type="string", format="date-time", nullable=true),
   *                     @OA\Property(property="created_at", type="string", format="date-time"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time"),
   *                     @OA\Property(property="repartidor", type="object",
   *                         @OA\Property(property="id", type="string", format="uuid"),
   *                         @OA\Property(property="user", type="object",
   *                             @OA\Property(property="id", type="string", format="uuid"),
   *                             @OA\Property(property="name", type="string")
   *                         )
   *                     )
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

  /**
   * Crear una nueva ruta.
   *
   * @OA\Post(
   *     path="/api/rutas",
   *     operationId="rutasStore",
   *     tags={"Entities","Rutas"},
   *     summary="Crear ruta",
   *     description="Crea una nueva ruta de entrega para un repartidor específico.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"repartidor_id"},
   *             @OA\Property(property="repartidor_id", type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000", description="UUID del perfil del repartidor"),
   *             @OA\Property(property="nombre", type="string", nullable=true, example="Ruta Centro", description="Nombre descriptivo de la ruta")
   *         )
   *     ),
   *     @OA\Response(
   *         response=201,
   *         description="Ruta creada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Ruta creada exitosamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="nombre", type="string", nullable=true),
   *                 @OA\Property(property="punto_inicio", type="object", nullable=true,
   *                     @OA\Property(property="latitude", type="number", format="float"),
   *                     @OA\Property(property="longitude", type="number", format="float")
   *                 ),
   *                 @OA\Property(property="punto_final", type="object", nullable=true,
   *                     @OA\Property(property="latitude", type="number", format="float"),
   *                     @OA\Property(property="longitude", type="number", format="float")
   *                 ),
   *                 @OA\Property(property="polyline_encoded", type="string", nullable=true),
   *                 @OA\Property(property="distancia_total_estimada", type="number", format="float"),
   *                 @OA\Property(property="tiempo_total_estimado", type="integer"),
   *                 @OA\Property(property="cantidad_pedidos", type="integer"),
   *                 @OA\Property(property="fecha_hora_calculo", type="string", format="date-time", nullable=true),
   *                 @OA\Property(property="fecha_inicio", type="string", format="date-time", nullable=true),
   *                 @OA\Property(property="fecha_completado", type="string", format="date-time", nullable=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time"),
   *                 @OA\Property(property="repartidor", type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="user", type="object",
   *                         @OA\Property(property="id", type="string", format="uuid"),
   *                         @OA\Property(property="name", type="string")
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

  /**
   * Obtener detalles de una ruta con sus pedidos.
   *
   * @OA\Get(
   *     path="/api/rutas/{ruta}",
   *     operationId="rutasShow",
   *     tags={"Entities","Rutas"},
   *     summary="Obtener detalles de ruta",
   *     description="Obtiene los datos completos de una ruta, incluyendo la lista de pedidos asignados a ella.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo para ordenamiento de pedidos",
   *         @OA\Schema(type="string", enum={"tipo_pedido","estado","updated_at","orden_optimizado","orden_personalizado","orden_recojo"}, example="orden_personalizado")
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="asc")
   *     ),
   *     @OA\Parameter(
   *         name="estado",
   *         in="query",
   *         required=false,
   *         description="Filtrar pedidos por estado",
   *         @OA\Schema(type="string", enum={"pendiente","asignado","en_ruta","entregado","rechazado"})
   *     ),
   *     @OA\Parameter(
   *         name="optimizado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por optimización (true/false)",
   *         @OA\Schema(type="boolean")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Detalles de la ruta obtenidos exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando datos y lista de pedidos de la ruta."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="ruta", type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="nombre", type="string"),
   *                     @OA\Property(property="punto_inicio", type="object",
   *                         @OA\Property(property="latitude", type="number", format="float"),
   *                         @OA\Property(property="longitude", type="number", format="float")
   *                     ),
   *                     @OA\Property(property="punto_final", type="object",
   *                         @OA\Property(property="latitude", type="number", format="float"),
   *                         @OA\Property(property="longitude", type="number", format="float")
   *                     ),
   *                     @OA\Property(property="polyline_encoded", type="string", nullable=true),
   *                     @OA\Property(property="distancia_total_estimada", type="number", format="float"),
   *                     @OA\Property(property="tiempo_total_estimado", type="integer"),
   *                     @OA\Property(property="cantidad_pedidos", type="integer"),
   *                     @OA\Property(property="created_at", type="string", format="date-time"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time"),
   *                     @OA\Property(property="repartidor", type="object",
   *                         @OA\Property(property="id", type="string", format="uuid"),
   *                         @OA\Property(property="user", type="object",
   *                             @OA\Property(property="id", type="string", format="uuid"),
   *                             @OA\Property(property="name", type="string")
   *                         )
   *                     )
   *                 ),
   *                 @OA\Property(property="pedidos", type="array",
   *                     items=@OA\Items(type="object",
   *                         @OA\Property(property="id", type="string", format="uuid"),
   *                         @OA\Property(property="codigo_barra", type="string"),
   *                         @OA\Property(property="ubicacion_recojo", type="object",
   *                             @OA\Property(property="latitude", type="number", format="float"),
   *                             @OA\Property(property="longitude", type="number", format="float")
   *                         ),
   *                         @OA\Property(property="ubicacion_entrega", type="object",
   *                             @OA\Property(property="latitude", type="number", format="float"),
   *                             @OA\Property(property="longitude", type="number", format="float")
   *                         ),
   *                         @OA\Property(property="direccion_entrega_linea_1", type="string"),
   *                         @OA\Property(property="paciente_nombre", type="string"),
   *                         @OA\Property(property="paciente_telefono", type="string"),
   *                         @OA\Property(property="observaciones", type="string", nullable=true),
   *                         @OA\Property(property="tipo_pedido", type="string"),
   *                         @OA\Property(property="estado", type="string", enum={"pendiente","asignado","en_ruta","entregado","rechazado"}),
   *                         @OA\Property(property="entregas", type="object",
   *                             @OA\Property(property="orden_optimizado", type="integer", nullable=true),
   *                             @OA\Property(property="orden_personalizado", type="integer"),
   *                             @OA\Property(property="orden_recojo", type="integer", nullable=true),
   *                             @OA\Property(property="optimizado", type="boolean")
   *                         )
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
   *         response=403,
   *         description="Acceso prohibido",
   *         @OA\JsonContent(ref="#/components/schemas/ForbiddenResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Ruta no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Obtener la ruta actual del usuario repartidor.
   *
   * @OA\Get(
   *     path="/api/rutas/current",
   *     operationId="rutasCurrent",
   *     tags={"Entities","Rutas"},
   *     summary="Obtener ruta actual",
   *     description="Obtiene la ruta asignada actualmente al usuario repartidor autenticado con sus pedidos.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo para ordenamiento de pedidos",
   *         @OA\Schema(type="string", enum={"tipo_pedido","estado","updated_at","orden_optimizado","orden_personalizado","orden_recojo"}, example="orden_personalizado")
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="asc")
   *     ),
   *     @OA\Parameter(
   *         name="estado",
   *         in="query",
   *         required=false,
   *         description="Filtrar pedidos por estado",
   *         @OA\Schema(type="string", enum={"pendiente","asignado","en_ruta","entregado","rechazado"})
   *     ),
   *     @OA\Parameter(
   *         name="optimizado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por optimización",
   *         @OA\Schema(type="boolean")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Ruta actual obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando datos y lista de pedidos de la ruta."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="ruta", type="object"),
   *                 @OA\Property(property="pedidos", type="array", items=@OA\Items(type="object"))
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=403,
   *         description="Solo repartidores pueden acceder",
   *         @OA\JsonContent(ref="#/components/schemas/ForbiddenResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="El repartidor no tiene ruta asignada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Actualizar una ruta.
   *
   * @OA\Patch(
   *     path="/api/rutas/{ruta}",
   *     operationId="rutasUpdate",
   *     tags={"Entities","Rutas"},
   *     summary="Actualizar ruta",
   *     description="Actualiza los datos de una ruta existente. Si se cambia el repartidor, todos los pedidos sin asignar se reasignan al nuevo repartidor.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             @OA\Property(property="repartidor_id", type="string", format="uuid", nullable=true, description="UUID del nuevo repartidor"),
   *             @OA\Property(property="nombre", type="string", nullable=true, example="Ruta Centro Actualizada")
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Ruta actualizada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Ruta actualizada exitosamente."),
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
   *         description="Ruta no encontrada",
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

  /**
   * Eliminar una ruta.
   *
   * @OA\Delete(
   *     path="/api/rutas/{ruta}",
   *     operationId="rutasDestroy",
   *     tags={"Entities","Rutas"},
   *     summary="Eliminar ruta",
   *     description="Elimina una ruta de entrega del sistema.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=204,
   *         description="Ruta eliminada exitosamente"
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Ruta no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function destroy(Ruta $ruta)
  {
    $ruta->delete();

    return ApiResponder::noContent('Ruta eliminada correctamente.');
  }

  /**
   * Optimizar una ruta específica.
   *
   * @OA\Patch(
   *     path="/api/rutas/{ruta}/optimizar",
   *     operationId="rutasOptimizar",
   *     tags={"Entities","Rutas"},
   *     summary="Optimizar ruta",
   *     description="Inicia un proceso asíncrono para optimizar la secuencia de entregas en una ruta específica basado en horarios de jornada.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"inicio_jornada","fin_jornada"},
   *             @OA\Property(property="inicio_jornada", type="string", format="date-time", example="2024-12-01T08:00:00"),
   *             @OA\Property(property="fin_jornada", type="string", format="date-time", example="2024-12-01T18:00:00"),
   *             @OA\Property(property="ubicacion_actual", type="object", nullable=true,
   *                 @OA\Property(property="latitude", type="number", format="float"),
   *                 @OA\Property(property="longitude", type="number", format="float")
   *             ),
   *             @OA\Property(property="ignorar_recojos", type="boolean", nullable=true, example=false)
   *         )
   *     ),
   *     @OA\Response(
   *         response=202,
   *         description="Proceso de optimización iniciado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Su solicitud está siendo procesada. Recibirás una notificación cuando los pedidos de la ruta hayan sido optimizados."),
   *             @OA\Property(property="data", type="null")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Ruta no encontrada",
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

  /**
   * Optimizar todas las rutas.
   *
   * @OA\Post(
   *     path="/api/rutas/optimizar",
   *     operationId="rutasOptimizarAll",
   *     tags={"Entities","Rutas"},
   *     summary="Optimizar todas las rutas",
   *     description="Inicia un proceso asíncrono para crear y optimizar rutas para todos los pedidos pendientes de entrega en una región específica.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"codigo_iso_pais","inicio_jornada","fin_jornada"},
   *             @OA\Property(property="codigo_iso_pais", type="string", example="PE", description="Código ISO del país (PE, CO, BR, etc)"),
   *             @OA\Property(property="inicio_jornada", type="string", format="date-time", example="2024-12-01T08:00:00"),
   *             @OA\Property(property="fin_jornada", type="string", format="date-time", example="2024-12-01T18:00:00"),
   *             @OA\Property(property="codigo_postal", type="string", nullable=true, example="28001", description="Código postal para filtrar por región")
   *         )
   *     ),
   *     @OA\Response(
   *         response=202,
   *         description="Proceso de optimización iniciado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Su solicitud está siendo procesada. Recibirás una notificación cuando las rutas y pedidos hayan sido optimizados y asignados a los repartidores adecuados."),
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

  /**
   * Listar pedidos de una ruta.
   *
   * @OA\Get(
   *     path="/api/rutas/{ruta}/pedidos",
   *     operationId="rutasPedidosList",
   *     tags={"Entities","Rutas"},
   *     summary="Listar pedidos de ruta",
   *     description="Obtiene la lista de pedidos asignados a una ruta específica.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo para ordenamiento",
   *         @OA\Schema(type="string", enum={"tipo_pedido","estado","updated_at","orden_optimizado","orden_personalizado","orden_recojo"}, example="orden_personalizado")
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="asc")
   *     ),
   *     @OA\Parameter(
   *         name="estado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por estado del pedido",
   *         @OA\Schema(type="string", enum={"pendiente","asignado","en_ruta","entregado","rechazado"})
   *     ),
   *     @OA\Parameter(
   *         name="optimizado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por optimización",
   *         @OA\Schema(type="boolean")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de pedidos obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando lista de pedidos de la ruta."),
   *             @OA\Property(property="data", type="array",
   *                 items=@OA\Items(type="object")
   *             )
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
   *         description="Ruta no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Agregar un pedido a una ruta.
   *
   * @OA\Post(
   *     path="/api/rutas/{ruta}/pedidos",
   *     operationId="rutasPedidosAdd",
   *     tags={"Entities","Rutas"},
   *     summary="Agregar pedido a ruta",
   *     description="Agrega un pedido existente a una ruta. El pedido debe estar en estado pendiente o asignado.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"pedido_id"},
   *             @OA\Property(property="pedido_id", type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440001", description="UUID del pedido a agregar")
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido agregado a la ruta exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El pedido ha sido agregado a la ruta."),
   *             @OA\Property(property="data", type="null")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Ruta o pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=409,
   *         description="Conflicto (pedido ya asignado o estado inválido)",
   *         @OA\JsonContent(ref="#/components/schemas/BadRequestResponse")
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

  /**
   * Remover un pedido de una ruta.
   *
   * @OA\Delete(
   *     path="/api/rutas/{ruta}/pedidos/{pedido}",
   *     operationId="rutasPedidosRemove",
   *     tags={"Entities","Rutas"},
   *     summary="Remover pedido de ruta",
   *     description="Remueve un pedido específico de una ruta y recalcula el orden de entrega de los pedidos restantes.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440001")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Pedido removido de la ruta exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El pedido ha sido removido de la ruta."),
   *             @OA\Property(property="data", type="null")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Ruta o pedido no encontrado en la ruta",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
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

  /**
   * Reordenar pedidos en una ruta.
   *
   * @OA\Patch(
   *     path="/api/rutas/{ruta}/pedidos/reordenar",
   *     operationId="rutasPedidosReordenar",
   *     tags={"Entities","Rutas"},
   *     summary="Reordenar pedidos",
   *     description="Actualiza el orden personalizado de entrega de los pedidos en una ruta.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="ruta",
   *         in="path",
   *         required=true,
   *         description="UUID de la ruta",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         @OA\JsonContent(
   *             required={"cambios"},
   *             @OA\Property(property="cambios", type="array", minItems=1,
   *                 items=@OA\Items(type="object",
   *                     required={"pedido_id","orden_personalizado"},
   *                     @OA\Property(property="pedido_id", type="string", format="uuid"),
   *                     @OA\Property(property="orden_personalizado", type="integer", minimum=1)
   *                 ),
   *                 example={
   *                     {"pedido_id": "550e8400-e29b-41d4-a716-446655440001", "orden_personalizado": 2},
   *                     {"pedido_id": "550e8400-e29b-41d4-a716-446655440002", "orden_personalizado": 1}
   *                 }
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Orden de pedidos actualizado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El orden de la ruta ha sido actualizado exitosamente."),
   *             @OA\Property(property="data", type="null")
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Ruta no encontrada",
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

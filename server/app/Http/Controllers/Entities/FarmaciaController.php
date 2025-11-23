<?php

namespace App\Http\Controllers\Entities;

use App\Enums\EstadosFarmaciaEnum;
use App\Enums\PermissionsEnum;
use App\Enums\RolesEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\Farmacia\IndexFarmaciaRequest;
use App\Http\Requests\Farmacia\StoreFarmaciaRequest;
use App\Http\Requests\Farmacia\UpdateFarmaciaRequest;
use App\Http\Resources\FarmaciaResource;
use App\Http\Resources\UserResource;
use App\Models\Farmacia;
use App\Models\User;
use Auth;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FarmaciaController extends Controller
{
  /**
   * Listar farmacias con paginación y filtros.
   *
   * @OA\Get(
   *     path="/api/farmacias",
   *     operationId="farmaciasIndex",
   *     tags={"Entities","Farmacias"},
   *     summary="Listar farmacias",
   *     description="Obtiene una lista paginada de farmacias. Soporta filtrado por ciudad, estado/región, código postal, país, cadena, estado de operación y rango de fechas. También permite búsqueda por nombre, razón social, RUC/EIN y dirección.",
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
   *         description="Campo para ordenar",
   *         @OA\Schema(type="string", enum={"created_at","updated_at","nombre","razon_social","ciudad","estado_region","cadena","estado"}, example="nombre")
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección de ordenamiento",
   *         @OA\Schema(type="string", enum={"asc","desc"}, example="asc")
   *     ),
   *     @OA\Parameter(
   *         name="search",
   *         in="query",
   *         required=false,
   *         description="Búsqueda por nombre, razón social, RUC/EIN, dirección, ciudad, estado/región o contacto",
   *         @OA\Schema(type="string", example="Farmacia Central")
   *     ),
   *     @OA\Parameter(
   *         name="ciudad",
   *         in="query",
   *         required=false,
   *         description="Filtrar por ciudad",
   *         @OA\Schema(type="string", example="Lima")
   *     ),
   *     @OA\Parameter(
   *         name="estado_region",
   *         in="query",
   *         required=false,
   *         description="Filtrar por estado o región",
   *         @OA\Schema(type="string", example="Lima")
   *     ),
   *     @OA\Parameter(
   *         name="codigo_postal",
   *         in="query",
   *         required=false,
   *         description="Filtrar por códigos postales (valores separados por coma)",
   *         @OA\Schema(type="string", example="15001,15002")
   *     ),
   *     @OA\Parameter(
   *         name="codigo_iso_pais",
   *         in="query",
   *         required=false,
   *         description="Filtrar por código ISO del país (valores separados por coma)",
   *         @OA\Schema(type="string", example="PE,CO")
   *     ),
   *     @OA\Parameter(
   *         name="cadena",
   *         in="query",
   *         required=false,
   *         description="Filtrar por nombre de cadena farmacéutica",
   *         @OA\Schema(type="string", example="Farmacia del Doctor")
   *     ),
   *     @OA\Parameter(
   *         name="delivery_24h",
   *         in="query",
   *         required=false,
   *         description="Filtrar por disponibilidad de delivery 24 horas",
   *         @OA\Schema(type="boolean", example=true)
   *     ),
   *     @OA\Parameter(
   *         name="estado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por estado de operación (valores separados por coma)",
   *         @OA\Schema(type="string", example="activa,inactiva")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_desde",
   *         in="query",
   *         required=false,
   *         description="Filtrar por fecha de creación desde",
   *         @OA\Schema(type="string", format="date", example="2024-01-01")
   *     ),
   *     @OA\Parameter(
   *         name="fecha_hasta",
   *         in="query",
   *         required=false,
   *         description="Filtrar por fecha de creación hasta",
   *         @OA\Schema(type="string", format="date", example="2024-12-31")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de farmacias obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando lista de farmacias."),
   *             @OA\Property(property="data", type="array",
   *                 items=@OA\Items(type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="nombre", type="string"),
   *                     @OA\Property(property="razon_social", type="string", nullable=true),
   *                     @OA\Property(property="ruc_ein", type="string"),
   *                     @OA\Property(property="direccion_linea_1", type="string"),
   *                     @OA\Property(property="direccion_linea_2", type="string", nullable=true),
   *                     @OA\Property(property="ciudad", type="string"),
   *                     @OA\Property(property="estado_region", type="string"),
   *                     @OA\Property(property="codigo_postal", type="string", nullable=true),
   *                     @OA\Property(property="codigo_iso_pais", type="string"),
   *                     @OA\Property(property="ubicacion", type="object", nullable=true,
   *                         @OA\Property(property="latitude", type="number"),
   *                         @OA\Property(property="longitude", type="number")
   *                     ),
   *                     @OA\Property(property="telefono", type="string", nullable=true),
   *                     @OA\Property(property="email", type="string", format="email", nullable=true),
   *                     @OA\Property(property="contacto_responsable", type="string", nullable=true),
   *                     @OA\Property(property="telefono_responsable", type="string", nullable=true),
   *                     @OA\Property(property="cadena", type="string", nullable=true),
   *                     @OA\Property(property="horario_atencion", type="string", nullable=true),
   *                     @OA\Property(property="delivery_24h", type="boolean"),
   *                     @OA\Property(property="estado", type="string", enum={"activa","inactiva","suspendida"}),
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
  public function index(IndexFarmaciaRequest $request)
  {
    $user = Auth::user();

    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();
    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $query = Farmacia::query();

    if (!$user->hasPermissionTo(PermissionsEnum::FARMACIAS_VIEW_ANY) && $user->hasPermissionTo(PermissionsEnum::FARMACIAS_VIEW_RELATED)) {
      if ($user->esFarmacia() && $user->perfilFarmacia !== null) {
        $farmaciaId = $user->perfilFarmacia->farmacia_id;
        $query->where('id', $farmaciaId);
      }
    }

    $ciudadFilter = $request->getCiudad();
    if ($ciudadFilter !== null) {
      $query->where('ciudad', $ciudadFilter);
    }

    $estadoRegionFilter = $request->getEstadoRegion();
    if ($estadoRegionFilter !== null) {
      $query->where('estado_region', $estadoRegionFilter);
    }

    if ($request->hasCodigoPostal()) {
      $codigoPostalFilter = $request->getCodigoPostalFilter();
      if ($codigoPostalFilter !== null) {
        $query->whereIn('codigo_postal', $codigoPostalFilter);
      } else {
        $query->where('codigo_postal', null);
      }
    }

    $codigoIsoPaisFilter = $request->getCodigoIsoPaisFilter();
    if ($codigoIsoPaisFilter !== null) {
      $query->whereIn('codigo_iso_pais', $codigoIsoPaisFilter);
    }

    $cadenaFilter = $request->getCadena();
    if ($cadenaFilter !== null) {
      $query->where('cadena', $cadenaFilter);
    }

    if ($request->hasDelivery24h()) {
      $delivery24hFilter = $request->getDelivery24h();
      $query->where('delivery_24h', $delivery24hFilter);
    }

    $estadoFilter = $request->getEstadoFilter();
    if ($estadoFilter !== null) {
      $query->whereIn('estado', $estadoFilter);
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
        $q->where('farmacias.nombre', 'like', "%{$search}%")
          ->orWhere('farmacias.razon_social', 'like', "%{$search}%")
          ->orWhere('farmacias.ruc_ein', 'like', "%{$search}%")
          ->orWhere('farmacias.direccion_linea_1', 'like', "%{$search}%")
          ->orWhere('farmacias.ciudad', 'like', "%{$search}%")
          ->orWhere('farmacias.estado_region', 'like', "%{$search}%")
          ->orWhere('farmacias.contacto_responsable', 'like', "%{$search}%")
          ->orWhere('farmacias.cadena', 'like', "%{$search}%");
      });
    }

    $query->orderBy($orderBy, $orderDirection);

    $pagination = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Mostrando lista de farmacias.',
      data: FarmaciaResource::collection($pagination->items()),
      pagination: $pagination
    );
  }

  /**
   * Crear una nueva farmacia.
   *
   * @OA\Post(
   *     path="/api/farmacias",
   *     operationId="farmaciasStore",
   *     tags={"Entities","Farmacias"},
   *     summary="Crear farmacia",
   *     description="Crea una nueva farmacia en el sistema. Requiere información completa de la farmacia incluyendo datos de contacto y ubicación.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos de la farmacia a crear",
   *         @OA\JsonContent(
   *             required={"nombre","ruc_ein","direccion_linea_1","ciudad","estado_region","codigo_iso_pais"},
   *             @OA\Property(property="nombre", type="string", example="Farmacia Central Lima"),
   *             @OA\Property(property="razon_social", type="string", nullable=true, example="Farmacia Central S.A."),
   *             @OA\Property(property="ruc_ein", type="string", example="20123456789"),
   *             @OA\Property(property="direccion_linea_1", type="string", example="Jr. Principal 123"),
   *             @OA\Property(property="direccion_linea_2", type="string", nullable=true, example="Apto 4B"),
   *             @OA\Property(property="ciudad", type="string", example="Lima"),
   *             @OA\Property(property="estado_region", type="string", example="Lima"),
   *             @OA\Property(property="codigo_postal", type="string", nullable=true, example="15001"),
   *             @OA\Property(property="codigo_iso_pais", type="string", example="PE"),
   *             @OA\Property(property="ubicacion", type="object", nullable=true,
   *                 @OA\Property(property="latitude", type="number", example=-12.0464),
   *                 @OA\Property(property="longitude", type="number", example=-77.0428)
   *             ),
   *             @OA\Property(property="telefono", type="string", nullable=true, example="+51123456789"),
   *             @OA\Property(property="email", type="string", format="email", nullable=true, example="contacto@farmacia.pe"),
   *             @OA\Property(property="contacto_responsable", type="string", nullable=true, example="Juan Pérez"),
   *             @OA\Property(property="telefono_responsable", type="string", nullable=true, example="+51987654321"),
   *             @OA\Property(property="cadena", type="string", nullable=true, example="Farmacia del Doctor"),
   *             @OA\Property(property="horario_atencion", type="string", nullable=true, example="08:00 - 22:00"),
   *             @OA\Property(property="delivery_24h", type="boolean", example=false),
   *             @OA\Property(property="estado", type="string", enum={"activa","inactiva","suspendida"}, example="activa")
   *         )
   *     ),
   *     @OA\Response(
   *         response=201,
   *         description="Farmacia creada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Farmacia creada exitosamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="nombre", type="string"),
   *                 @OA\Property(property="ruc_ein", type="string"),
   *                 @OA\Property(property="ciudad", type="string"),
   *                 @OA\Property(property="estado", type="string"),
   *                 @OA\Property(property="created_at", type="string", format="date-time"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time")
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
  public function store(StoreFarmaciaRequest $request)
  {
    $validatedData = $request->validated();

    $farmacia = Farmacia::create($validatedData);

    return ApiResponder::created(
      message: 'Farmacia creada exitosamente.',
      data: FarmaciaResource::make($farmacia),
    );
  }

  /**
   * Obtener datos de una farmacia específica.
   *
   * @OA\Get(
   *     path="/api/farmacias/{farmacia}",
   *     operationId="farmaciasShow",
   *     tags={"Entities","Farmacias"},
   *     summary="Obtener datos de farmacia",
   *     description="Obtiene la información completa de una farmacia específica por su UUID o RUC/EIN.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="farmacia",
   *         in="path",
   *         required=true,
   *         description="UUID o RUC/EIN de la farmacia",
   *         @OA\Schema(type="string", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Datos de la farmacia obtenidos exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando datos de la farmacia."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid"),
   *                 @OA\Property(property="nombre", type="string"),
   *                 @OA\Property(property="razon_social", type="string", nullable=true),
   *                 @OA\Property(property="ruc_ein", type="string"),
   *                 @OA\Property(property="direccion_linea_1", type="string"),
   *                 @OA\Property(property="direccion_linea_2", type="string", nullable=true),
   *                 @OA\Property(property="ciudad", type="string"),
   *                 @OA\Property(property="estado_region", type="string"),
   *                 @OA\Property(property="codigo_postal", type="string", nullable=true),
   *                 @OA\Property(property="codigo_iso_pais", type="string"),
   *                 @OA\Property(property="ubicacion", type="object", nullable=true,
   *                     @OA\Property(property="latitude", type="number"),
   *                     @OA\Property(property="longitude", type="number")
   *                 ),
   *                 @OA\Property(property="telefono", type="string", nullable=true),
   *                 @OA\Property(property="email", type="string", format="email", nullable=true),
   *                 @OA\Property(property="contacto_responsable", type="string", nullable=true),
   *                 @OA\Property(property="telefono_responsable", type="string", nullable=true),
   *                 @OA\Property(property="cadena", type="string", nullable=true),
   *                 @OA\Property(property="horario_atencion", type="string", nullable=true),
   *                 @OA\Property(property="delivery_24h", type="boolean"),
   *                 @OA\Property(property="estado", type="string", enum={"activa","inactiva","suspendida"}),
   *                 @OA\Property(property="created_at", type="string", format="date-time"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time")
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Farmacia no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function show(Farmacia $farmacia)
  {
    return ApiResponder::success(
      message: 'Mostrando datos de la farmacia.',
      data: FarmaciaResource::make($farmacia)
    );
  }

  /**
   * Listar usuarios de una farmacia.
   *
   * @OA\Get(
   *     path="/api/farmacias/{farmacia}/users",
   *     operationId="farmaciasListUsers",
   *     tags={"Entities","Farmacias"},
   *     summary="Listar usuarios de farmacia",
   *     description="Obtiene la lista de todos los usuarios que pertenecen a una farmacia específica.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="farmacia",
   *         in="path",
   *         required=true,
   *         description="UUID de la farmacia",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de usuarios de la farmacia obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando los usuarios que pertenecen a la farmacia."),
   *             @OA\Property(property="data", type="array",
   *                 items=@OA\Items(type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="name", type="string"),
   *                     @OA\Property(property="email", type="string", format="email"),
   *                     @OA\Property(property="is_active", type="boolean"),
   *                     @OA\Property(property="created_at", type="string", format="date-time"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time")
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
   *         response=404,
   *         description="Farmacia no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function listUsers(Farmacia $farmacia)
  {
    $relationName = RolesEnum::FARMACIA->getProfileRelationName();

    $users = User::whereHas($relationName, function ($query) use ($farmacia) {
      $query->where('farmacia_id', $farmacia->id);
    })
      ->with($relationName)
      ->get();

    return ApiResponder::success(
      message: 'Mostrando los usuarios que pertenecen a la farmacia.',
      data: UserResource::collection($users)
    );
  }

  /**
   * Actualizar datos de una farmacia.
   *
   * @OA\Patch(
   *     path="/api/farmacias/{farmacia}",
   *     operationId="farmaciasUpdate",
   *     tags={"Entities","Farmacias"},
   *     summary="Actualizar farmacia",
   *     description="Actualiza la información de una farmacia. Soporta actualización parcial de campos.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="farmacia",
   *         in="path",
   *         required=true,
   *         description="UUID de la farmacia",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Campos a actualizar de la farmacia",
   *         @OA\JsonContent(
   *             @OA\Property(property="nombre", type="string", example="Farmacia Central Lima"),
   *             @OA\Property(property="razon_social", type="string", nullable=true),
   *             @OA\Property(property="direccion_linea_1", type="string"),
   *             @OA\Property(property="telefono", type="string", nullable=true),
   *             @OA\Property(property="email", type="string", format="email", nullable=true),
   *             @OA\Property(property="delivery_24h", type="boolean"),
   *             @OA\Property(property="estado", type="string", enum={"activa","inactiva","suspendida"})
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Farmacia actualizada exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Farmacia creada exitosamente."),
   *             @OA\Property(property="data", type="object")
   *         )
   *     ),
   *     @OA\Response(
   *         response=400,
   *         description="No se recibió información para actualizar",
   *         @OA\JsonContent(ref="#/components/schemas/BadRequestResponse")
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Farmacia no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
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
  public function update(UpdateFarmaciaRequest $request, Farmacia $farmacia)
  {
    $validatedData = $request->validated();

    if (sizeof($validatedData) === 0) {
      throw CustomException::badRequest('No se recibió información para actualizar');
    }

    $farmacia->update($validatedData);

    return ApiResponder::success(
      message: 'Farmacia creada exitosamente.',
      data: FarmaciaResource::make($farmacia),
    );
  }

  /**
   * Actualizar estado de una farmacia.
   *
   * @OA\Patch(
   *     path="/api/farmacias/{farmacia}/estado",
   *     operationId="farmaciasUpdateEstado",
   *     tags={"Entities","Farmacias"},
   *     summary="Actualizar estado de farmacia",
   *     description="Actualiza el estado operativo de una farmacia (activa, inactiva, suspendida).",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="farmacia",
   *         in="path",
   *         required=true,
   *         description="UUID de la farmacia",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Nuevo estado de la farmacia",
   *         @OA\JsonContent(
   *             required={"estado"},
   *             @OA\Property(property="estado", type="string", enum={"activa","inactiva","suspendida"}, example="inactiva")
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Estado de la farmacia actualizado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El estado de la farmacia ha sido actualizado"),
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
   *         description="Farmacia no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
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
  public function updateEstado(Request $request, Farmacia $farmacia)
  {
    $key = 'estado';

    $request->validate([$key => ['required', 'string', Rule::in(EstadosFarmaciaEnum::cases())]]);

    $farmacia->update([$key => $request->input($key)]);

    return ApiResponder::success(
      message: 'El estado de la farmacia ha sido actualizado',
      data: FarmaciaResource::make($farmacia),
    );
  }

  /**
   * Eliminar una farmacia.
   *
   * @OA\Delete(
   *     path="/api/farmacias/{farmacia}",
   *     operationId="farmaciasDestroy",
   *     tags={"Entities","Farmacias"},
   *     summary="Eliminar farmacia",
   *     description="Elimina una farmacia del sistema. Esta operación es irreversible.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="farmacia",
   *         in="path",
   *         required=true,
   *         description="UUID de la farmacia",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000")
   *     ),
   *     @OA\Response(
   *         response=204,
   *         description="Farmacia eliminada exitosamente"
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Farmacia no encontrada",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error interno del servidor",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     )
   * )
   */
  public function destroy(Farmacia $farmacia)
  {
    $farmacia->delete();

    return ApiResponder::noContent('Farmacia eliminada correctamente.');
  }
}

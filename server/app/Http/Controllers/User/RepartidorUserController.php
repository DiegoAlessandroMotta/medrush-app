<?php

namespace App\Http\Controllers\User;

use App\Enums\EstadosRepartidorEnum;
use App\Enums\RolesEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\User\List\IndexRepartidorUserRequest;
use App\Http\Requests\User\Register\RegisterRepartidorUserRequest;
use App\Http\Requests\User\Update\UpdateRepartidorUserRequest;
use App\Http\Requests\User\UploadFiles\UploadFotoLicenciaRequest;
use App\Http\Requests\User\UploadFiles\UploadFotoSeguroVehiculoRequest;
use App\Http\Resources\UserResource;
use App\Models\PerfilRepartidor;
use App\Models\User;
use App\Services\Disk\PrivateUploadsDiskService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RepartidorUserController extends Controller
{
  /**
   * @OA\Get(
   *     path="/api/users/repartidores",
   *     operationId="repartidorUsersIndex",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Listar usuarios repartidores",
   *     description="Obtiene una lista paginada de usuarios repartidores. Soporta filtrado por estado activo, verificación, código país, rango de fechas y búsqueda por nombre/email.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="page",
   *         in="query",
   *         required=false,
   *         description="Número de página (por defecto: 1)",
   *         @OA\Schema(type="integer", example=1),
   *     ),
   *     @OA\Parameter(
   *         name="per_page",
   *         in="query",
   *         required=false,
   *         description="Cantidad de elementos por página (por defecto: 15)",
   *         @OA\Schema(type="integer", example=15),
   *     ),
   *     @OA\Parameter(
   *         name="order_by",
   *         in="query",
   *         required=false,
   *         description="Campo por el que ordenar (created_at, updated_at, name, email, is_active)",
   *         @OA\Schema(type="string", example="created_at"),
   *     ),
   *     @OA\Parameter(
   *         name="order_direction",
   *         in="query",
   *         required=false,
   *         description="Dirección del ordenamiento (asc, desc)",
   *         @OA\Schema(type="string", enum={"asc", "desc"}, example="desc"),
   *     ),
   *     @OA\Parameter(
   *         name="is_active",
   *         in="query",
   *         required=false,
   *         description="Filtrar por estado activo (true, false)",
   *         @OA\Schema(type="boolean", example=true),
   *     ),
   *     @OA\Parameter(
   *         name="search",
   *         in="query",
   *         required=false,
   *         description="Búsqueda por nombre o email",
   *         @OA\Schema(type="string", example="juan"),
   *     ),
   *     @OA\Parameter(
   *         name="codigo_iso_pais",
   *         in="query",
   *         required=false,
   *         description="Filtrar por código ISO de país (puede ser múltiple)",
   *         @OA\Schema(type="array", items=@OA\Items(type="string"), example={"CO","MX"}),
   *     ),
   *     @OA\Parameter(
   *         name="estado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por estado del repartidor",
   *         @OA\Schema(type="array", items=@OA\Items(type="string", enum={"activo","inactivo","suspendido"})),
   *     ),
   *     @OA\Parameter(
   *         name="verificado",
   *         in="query",
   *         required=false,
   *         description="Filtrar por estado de verificación (true, false)",
   *         @OA\Schema(type="boolean", example=true),
   *     ),
   *     @OA\Parameter(
   *         name="fecha_desde",
   *         in="query",
   *         required=false,
   *         description="Filtrar por fecha de creación desde",
   *         @OA\Schema(type="string", format="date", example="2025-01-01"),
   *     ),
   *     @OA\Parameter(
   *         name="fecha_hasta",
   *         in="query",
   *         required=false,
   *         description="Filtrar por fecha de creación hasta",
   *         @OA\Schema(type="string", format="date", example="2025-12-31"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de repartidores obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando todos los usuarios repartidores."),
   *             @OA\Property(property="data", type="array", items=@OA\Items(
   *                 type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Juan García"),
   *                 @OA\Property(property="email", type="string", format="email", example="juan@example.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", nullable=true, example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"repartidor"}),
   *                 @OA\Property(property="perfil_repartidor", type="object", nullable=true, description="Perfil del repartidor con documentos y vehículo"),
   *             )),
   *             @OA\Property(property="pagination", type="object",
   *                 @OA\Property(property="total", type="integer", example=150),
   *                 @OA\Property(property="per_page", type="integer", example=15),
   *                 @OA\Property(property="current_page", type="integer", example=1),
   *                 @OA\Property(property="last_page", type="integer", example=10),
   *                 @OA\Property(property="from", type="integer", example=1),
   *                 @OA\Property(property="to", type="integer", example=15),
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
   *         description="Error de validación en parámetros",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function index(IndexRepartidorUserRequest $request)
  {
    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();
    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $relationName = RolesEnum::REPARTIDOR->getProfileRelationName();
    $query = User::role(RolesEnum::REPARTIDOR)
      ->select(['users.*'])
      ->join(
        'perfiles_repartidor',
        'users.id',
        '=',
        'perfiles_repartidor.id',
      )
      ->with([
        'roles',
        $relationName
      ]);

    if ($request->hasIsActive()) {
      $isActiveFilter = $request->getIsActive();
      $query->where('users.is_active', $isActiveFilter);
    }

    $search = $request->getSearch();
    if ($search !== null) {
      $query->where(function ($q) use ($search) {
        $q->where('users.name', 'like', "%{$search}%")
          ->orWhere('users.email', 'like', "%{$search}%");
      });
    }

    $codigoIsoPaisFilter = $request->getCodigoIsoPaisFilter();
    if ($codigoIsoPaisFilter !== null) {
      $query->whereIn('perfiles_repartidor.codigo_iso_pais', $codigoIsoPaisFilter);
    }

    $estadoFilter = $request->getEstadoFilter();
    if ($estadoFilter !== null) {
      $query->whereIn('perfiles_repartidor.estado', $estadoFilter);
    }

    $verificadoFilter = $request->getVerificado();
    if ($verificadoFilter !== null) {
      $query->where('perfiles_repartidor.verificado', $verificadoFilter);
    }

    $fechaDesde = $request->getFechaDesde();
    $fechaHasta = $request->getFechaHasta();
    if ($fechaDesde !== null && $fechaHasta !== null) {
      $query->whereBetween('users.created_at', [$fechaDesde, $fechaHasta]);
    } elseif ($fechaDesde !== null) {
      $query->where('users.created_at', '>=', $fechaDesde);
    } elseif ($fechaHasta !== null) {
      $query->where('users.created_at', '<=', $fechaHasta);
    }

    $query->orderBy($orderBy, $orderDirection);

    $pagination = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Mostrando todos los usuarios repartidores.',
      data: UserResource::collection($pagination->items()),
      pagination: $pagination,
    );
  }

  /**
   * @OA\Post(
   *     path="/api/users/repartidores",
   *     operationId="repartidorUsersRegister",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Crear nuevo usuario repartidor",
   *     description="Registra un nuevo usuario repartidor en el sistema con información básica y datos del perfil. Se genera un token de acceso para sesión inmediata.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos del nuevo repartidor",
   *         @OA\JsonContent(
   *             required={"name","email","password","password_confirmation","device_name","codigo_iso_pais","telefono"},
   *             @OA\Property(property="name", type="string", description="Nombre completo", example="Juan García López", maxLength=255),
   *             @OA\Property(property="email", type="string", format="email", description="Email único", example="juan@example.com", maxLength=255),
   *             @OA\Property(property="password", type="string", format="password", description="Contraseña", example="SecurePass123!"),
   *             @OA\Property(property="password_confirmation", type="string", format="password", description="Confirmación", example="SecurePass123!"),
   *             @OA\Property(property="device_name", type="string", description="Nombre del dispositivo", example="iPhone 15"),
   *             @OA\Property(property="codigo_iso_pais", type="string", description="Código ISO del país", example="CO"),
   *             @OA\Property(property="telefono", type="string", description="Número de teléfono", example="+573001234567"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=201,
   *         description="Repartidor registrado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Usuario repartidor registrado exitosamente"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="user", type="object",
   *                     @OA\Property(property="id", type="string", format="uuid"),
   *                     @OA\Property(property="name", type="string", example="Juan García López"),
   *                     @OA\Property(property="email", type="string", format="email", example="juan@example.com"),
   *                     @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"repartidor"}),
   *                     @OA\Property(property="perfil_repartidor", type="object", description="Perfil del repartidor"),
   *                 ),
   *                 @OA\Property(property="access_token", type="string", description="Token de acceso", example="1|abcd..."),
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
   *         description="Error de validación",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function register(RegisterRepartidorUserRequest $request)
  {
    $userData = $request->getUserData();
    $repartidorData = $request->getRepartidorUserData();
    $userData['password'] = Hash::make($userData['password']);

    /** @var User $user */
    $user = DB::transaction(function () use ($userData, $repartidorData) {
      $user = User::create($userData);

      PerfilRepartidor::create(array_merge(['id' => $user->id], $repartidorData));

      return $user;
    });

    $user->assignRole(RolesEnum::REPARTIDOR);

    $token = $user->createToken($request->getDeviceName())->plainTextToken;

    $user->load(RolesEnum::REPARTIDOR->getProfileRelationName());

    return ApiResponder::created(
      message: 'Usuario repartidor registrado exitosamente',
      data: [
        'user' => UserResource::make($user),
        'access_token' => $token,
      ]
    );
  }

  /**
   * @OA\Get(
   *     path="/api/users/repartidores/{perfilRepartidorId}",
   *     operationId="repartidorUsersShow",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Obtener detalles de un repartidor",
   *     description="Retorna la información completa de un repartidor incluyendo documentos verificables.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilRepartidorId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de repartidor",
   *         @OA\Schema(type="string", format="uuid"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Información del repartidor obtenida",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}),
   *             @OA\Property(property="message", type="string", example="Mostrando datos del usuario repartidor."),
   *             @OA\Property(property="data", type="object"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Repartidor no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function show(PerfilRepartidor $perfilRepartidor)
  {
    $user = $perfilRepartidor->user;
    $user->load(RolesEnum::REPARTIDOR->getProfileRelationName());

    return ApiResponder::success(
      message: 'Mostrando datos del usuario repartidor.',
      data: UserResource::make($user)
    );
  }

  /**
   * @OA\Put(
   *     path="/api/users/repartidores/{perfilRepartidorId}",
   *     operationId="repartidorUsersUpdate",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Actualizar datos de un repartidor",
   *     description="Actualiza información del usuario y/o perfil del repartidor. Se puede actualizar datos básicos o específicos del perfil repartidor.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilRepartidorId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de repartidor",
   *         @OA\Schema(type="string", format="uuid"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos a actualizar",
   *         @OA\JsonContent(
   *             @OA\Property(property="name", type="string", description="Nombre (opcional)"),
   *             @OA\Property(property="email", type="string", format="email", description="Email (opcional)"),
   *             @OA\Property(property="password", type="string", format="password", description="Contraseña (opcional)"),
   *             @OA\Property(property="password_confirmation", type="string", format="password", description="Confirmación"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Repartidor actualizado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}),
   *             @OA\Property(property="message", type="string", example="Los datos del usuario han sido actualizados."),
   *             @OA\Property(property="data", type="object"),
   *         ),
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
   *         description="Repartidor no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function update(UpdateRepartidorUserRequest $request, PerfilRepartidor $perfilRepartidor)
  {
    if (empty($request->validated())) {
      throw CustomException::badRequest('No se recibió información para actualizar');
    }

    $user = $perfilRepartidor->user;
    $userData = $request->getUserData();
    $repartidorData = $request->getRepartidorData();
    if ($request->hasPassword()) {
      $userData['password'] = Hash::make($userData['password']);
    }

    DB::transaction(function () use ($user, $perfilRepartidor, $userData, $repartidorData) {
      if (!empty($userData)) {
        $user->update($userData);
      }

      if (!empty($repartidorData)) {
        $perfilRepartidor->update($repartidorData);
      }
    });

    $user->load(RolesEnum::REPARTIDOR->getProfileRelationName());

    return ApiResponder::success(
      message: 'Los datos del usuario han sido actualizados.',
      data: UserResource::make($user),
    );
  }

  /**
   * @OA\Patch(
   *     path="/api/users/repartidores/{perfilRepartidorId}/estado",
   *     operationId="repartidorUsersUpdateEstado",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Actualizar estado del repartidor",
   *     description="Actualiza el estado operacional del repartidor (activo, inactivo, suspendido).",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilRepartidorId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de repartidor",
   *         @OA\Schema(type="string", format="uuid"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Nuevo estado",
   *         @OA\JsonContent(
   *             required={"estado"},
   *             @OA\Property(property="estado", type="string", enum={"activo","inactivo","suspendido"}, example="activo"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Estado actualizado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}),
   *             @OA\Property(property="message", type="string", example="El estado del repartidor ha sido actualizado"),
   *             @OA\Property(property="data", type="object"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Estado inválido",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function updateEstado(Request $request, PerfilRepartidor $perfilRepartidor)
  {
    $key = 'estado';

    $request->validate([$key => ['required', 'string', Rule::in(EstadosRepartidorEnum::cases())]]);

    $perfilRepartidor->update([$key => $request->input($key)]);

    $user = $perfilRepartidor->user;
    $user->load(RolesEnum::REPARTIDOR->getProfileRelationName());

    return ApiResponder::success(
      message: 'El estado del repartidor ha sido actualizado',
      data: UserResource::make($user),
    );
  }

  /**
   * @OA\Patch(
   *     path="/api/users/repartidores/{perfilRepartidorId}/verificado",
   *     operationId="repartidorUsersUpdateVerificado",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Actualizar estado de verificación",
   *     description="Marca un repartidor como verificado o no verificado después de validar sus documentos.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilRepartidorId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de repartidor",
   *         @OA\Schema(type="string", format="uuid"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Estado de verificación",
   *         @OA\JsonContent(
   *             required={"verificado"},
   *             @OA\Property(property="verificado", type="boolean", example=true),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Verificación actualizada",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}),
   *             @OA\Property(property="message", type="string", example="El estado verificado del repartidor ha sido actualizado."),
   *             @OA\Property(property="data", type="object"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Valor inválido",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function updateVerificado(Request $request, PerfilRepartidor $perfilRepartidor)
  {
    $key = 'verificado';

    $request->validate([$key => ['required', 'boolean']]);

    $perfilRepartidor->update([$key => $request->input($key)]);

    $user = $perfilRepartidor->user;
    $user->load(RolesEnum::REPARTIDOR->getProfileRelationName());

    return ApiResponder::success(
      message: 'El estado verificado del repartidor ha sido actualizado.',
      data: UserResource::make($user),
    );
  }

  /**
   * @OA\Post(
   *     path="/api/users/repartidores/{perfilRepartidorId}/documentos/licencia",
   *     operationId="repartidorUploadFotoLicencia",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Subir foto de licencia de conducir",
   *     description="Carga la foto de la licencia de conducir del repartidor. Reemplaza la anterior si existe.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilRepartidorId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de repartidor",
   *         @OA\Schema(type="string", format="uuid"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Archivo de imagen",
   *         @OA\MediaType(
   *             mediaType="multipart/form-data",
   *             @OA\Schema(
   *                 type="object",
   *                 required={"foto_licencia"},
   *                 @OA\Property(
   *                     property="foto_licencia",
   *                     type="string",
   *                     format="binary",
   *                     description="Imagen JPEG/PNG de la licencia"
   *                 )
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Licencia subida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}),
   *             @OA\Property(property="message", type="string", example="La foto de su licencia de conducir ha sido actualizada correctamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="url", type="string", format="url"),
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
   *         description="Archivo inválido",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error al guardar",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     ),
   * )
   */
  public function uploadFotoLicencia(UploadFotoLicenciaRequest $request, PerfilRepartidor $perfilRepartidor)
  {
    if (!$request->hasFile('foto_licencia')) {
      return ApiResponder::success(message: 'Sin cambios (no se envió archivo).', data: ['url' => null]);
    }

    $oldLicenciaPath = $perfilRepartidor->foto_licencia_path;
    $fotoLicenciaFile = $request->file('foto_licencia');
    $newFotoLicenciaPath = null;

    try {
      $newFotoLicenciaPath = PrivateUploadsDiskService::saveImage(
        imgPath: $fotoLicenciaFile->getRealPath(),
        prefix: 'l-',
        width: 2000,
        height: 2000,
        quality: 95,
      );

      if ($newFotoLicenciaPath === null) {
        throw CustomException::internalServer('Error inesperado al intentar guardar la foto del documento.');
      }

      $perfilRepartidor->update([
        'foto_licencia_path' => $newFotoLicenciaPath,
      ]);

      if ($oldLicenciaPath !== null) {
        PrivateUploadsDiskService::delete($oldLicenciaPath);
      }

      return ApiResponder::success(
        message: 'La foto de su licencia de conducir ha sido actualizada correctamente.',
        data: [
          'url' => PrivateUploadsDiskService::getSignedUrl($newFotoLicenciaPath)
        ],
      );
    } catch (\Throwable $e) {
      if ($newFotoLicenciaPath !== null) {
        PrivateUploadsDiskService::delete($newFotoLicenciaPath);
      }

      throw CustomException::internalServer(
        'Error inesperado al intentar actualizar la foto de su licencia de conducir.',
        $e,
      );
    }
  }

  /**
   * @OA\Post(
   *     path="/api/users/repartidores/{perfilRepartidorId}/documentos/seguro",
   *     operationId="repartidorUploadFotoSeguroVehiculo",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Subir foto de seguro del vehículo",
   *     description="Carga la foto del seguro del vehículo del repartidor. Reemplaza la anterior si existe.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilRepartidorId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de repartidor",
   *         @OA\Schema(type="string", format="uuid"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Archivo de imagen",
   *         @OA\MediaType(
   *             mediaType="multipart/form-data",
   *             @OA\Schema(
   *                 type="object",
   *                 required={"foto_seguro_vehiculo"},
   *                 @OA\Property(
   *                     property="foto_seguro_vehiculo",
   *                     type="string",
   *                     format="binary",
   *                     description="Imagen JPEG/PNG del seguro"
   *                 )
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Seguro subido exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}),
   *             @OA\Property(property="message", type="string", example="La foto del seguro de su vehículo ha sido actualizada correctamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="url", type="string", format="url"),
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
   *         description="Archivo inválido",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   *     @OA\Response(
   *         response=500,
   *         description="Error al guardar",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     ),
   * )
   */
  public function uploadFotoSeguroVehiculo(UploadFotoSeguroVehiculoRequest $request, PerfilRepartidor $perfilRepartidor)
  {
    if (!$request->hasFile('foto_seguro_vehiculo')) {
      return ApiResponder::success(message: 'Sin cambios (no se envió archivo).', data: ['url' => null]);
    }

    $oldSeguroVehiculoPath = $perfilRepartidor->foto_seguro_vehiculo_path;
    $fotoSeguroVehiculoFile = $request->file('foto_seguro_vehiculo');
    $newFotoSeguroVehiculoPath = null;

    try {
      $newFotoSeguroVehiculoPath = PrivateUploadsDiskService::saveImage(
        imgPath: $fotoSeguroVehiculoFile->getRealPath(),
        prefix: 'sv-',
        width: 2000,
        height: 2000,
        quality: 95,
      );

      if ($newFotoSeguroVehiculoPath === null) {
        throw CustomException::internalServer('Error inesperado al intentar guardar la foto.');
      }

      $perfilRepartidor->update([
        'foto_seguro_vehiculo_path' => $newFotoSeguroVehiculoPath,
      ]);

      if ($oldSeguroVehiculoPath !== null) {
        PrivateUploadsDiskService::delete($oldSeguroVehiculoPath);
      }

      return ApiResponder::success(
        message: 'La foto del seguro de su vehículo ha sido actualizada correctamente.',
        data: [
          'url' => PrivateUploadsDiskService::getSignedUrl($newFotoSeguroVehiculoPath)
        ],
      );
    } catch (\Throwable $e) {
      if ($newFotoSeguroVehiculoPath !== null) {
        PrivateUploadsDiskService::delete($newFotoSeguroVehiculoPath);
      }

      throw CustomException::internalServer(
        'Error inesperado al intentar actualizar la foto.',
        $e,
      );
    }
  }

  /**
   * @OA\Delete(
   *     path="/api/users/repartidores/{perfilRepartidorId}",
   *     operationId="repartidorUsersDestroy",
   *     tags={"User","PerfilRepartidor"},
   *     summary="Eliminar un repartidor",
   *     description="Elimina un repartidor del sistema. Se revoca automáticamente todos sus tokens y se elimina su perfil.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilRepartidorId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de repartidor",
   *         @OA\Schema(type="string", format="uuid"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Repartidor eliminado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}),
   *             @OA\Property(property="message", type="string", example="El usuario repartidor ha sido eliminado exitosamente."),
   *             @OA\Property(property="data", type="null"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Repartidor no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function destroy(PerfilRepartidor $perfilRepartidor)
  {
    $user = $perfilRepartidor->user;

    DB::transaction(function () use ($perfilRepartidor, $user) {
      $perfilRepartidor->delete();
      $user->tokens()->delete();
      $user->delete();
    });

    return ApiResponder::success(
      message: 'El usuario repartidor ha sido eliminado exitosamente.'
    );
  }
}

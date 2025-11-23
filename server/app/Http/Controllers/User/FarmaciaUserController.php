<?php

namespace App\Http\Controllers\User;

use App\Enums\PermissionsEnum;
use App\Enums\RolesEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\User\List\IndexFarmaciaUserRequest;
use App\Http\Requests\User\Register\RegisterFarmaciaUserRequest;
use App\Http\Requests\User\Update\UpdateBaseUserRequest;
use App\Http\Resources\UserResource;
use App\Models\PerfilFarmacia;
use App\Models\User;
use Auth;
use DB;
use Hash;

class FarmaciaUserController extends Controller
{
  /**
   * @OA\Get(
   *     path="/api/users/farmacias",
   *     operationId="farmaciaUsersIndex",
   *     tags={"User","Farmacia"},
   *     summary="Listar usuarios de farmacias",
   *     description="Obtiene una lista paginada de usuarios con rol de farmacia. Los usuarios farmacia solo pueden ver sus propios usuarios. Soporta búsqueda por nombre o email, y filtrado por estado activo.",
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
   *         @OA\Schema(type="string", example="farmacia"),
   *     ),
   *     @OA\Parameter(
   *         name="farmacia_id",
   *         in="query",
   *         required=false,
   *         description="Filtrar por ID de farmacia (solo administradores)",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de usuarios de farmacias obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando los usuarios de farmacias."),
   *             @OA\Property(property="data", type="array", items=@OA\Items(
   *                 type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Gerente Farmacia"),
   *                 @OA\Property(property="email", type="string", format="email", example="gerente@farmacia.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", nullable=true, example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"farmacia"}),
   *                 @OA\Property(property="perfil_farmacia", type="object", nullable=true, description="Perfil de la farmacia del usuario"),
   *             )),
   *             @OA\Property(property="pagination", type="object",
   *                 @OA\Property(property="total", type="integer", example=25),
   *                 @OA\Property(property="per_page", type="integer", example=15),
   *                 @OA\Property(property="current_page", type="integer", example=1),
   *                 @OA\Property(property="last_page", type="integer", example=2),
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
  public function index(IndexFarmaciaUserRequest $request)
  {
    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();
    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $relationName = RolesEnum::FARMACIA->getProfileRelationName();
    $query = User::role(RolesEnum::FARMACIA)
      ->with([
        'roles',
        $relationName
      ]);

    if ($request->hasIsActive()) {
      $isActiveFilter = $request->getIsActive();
      $query->where('is_active', $isActiveFilter);
    }

    $user = Auth::user();

    if ($user->esFarmacia() && $user->perfilFarmacia?->farmacia_id !== null) {
      $farmaciaId = $user->perfilFarmacia->farmacia_id;
      $query->where('perfiles_farmacia.farmacia_id', $farmaciaId);
    }

    $farmaciaIdFilter = $request->getFarmaciaId();
    if ($farmaciaIdFilter !== null && !$user->esFarmacia()) {
      $query->where('perfiles_farmacia.farmacia_id', $farmaciaIdFilter);
    }

    $search = $request->getSearch();
    if ($search !== null) {
      $query->where(function ($q) use ($search) {
        $q->where('name', 'like', "%{$search}%")
          ->orWhere('email', 'like', "%{$search}%");
      });
    }

    $query->orderBy($orderBy, $orderDirection);

    $pagination = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Mostrando los usuarios de farmacias.',
      data: UserResource::collection($pagination->items()),
      pagination: $pagination,
    );
  }

  /**
   * @OA\Post(
   *     path="/api/users/farmacias",
   *     operationId="farmaciaUsersRegister",
   *     tags={"User","Farmacia"},
   *     summary="Crear nuevo usuario de farmacia",
   *     description="Registra un nuevo usuario con rol de farmacia en el sistema. Se genera automáticamente un token de acceso para sesión inmediata.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos del nuevo usuario de farmacia",
   *         @OA\JsonContent(
   *             required={"name","email","password","password_confirmation","device_name","farmacia_id"},
   *             @OA\Property(property="name", type="string", description="Nombre completo del usuario", example="Gerente Farmacia", maxLength=255),
   *             @OA\Property(property="email", type="string", format="email", description="Email único del usuario", example="gerente@farmacia.com", maxLength=255),
   *             @OA\Property(property="password", type="string", format="password", description="Contraseña (mín 8 caracteres, mayúscula, número y símbolo)", example="SecurePass123!"),
   *             @OA\Property(property="password_confirmation", type="string", format="password", description="Confirmación de contraseña", example="SecurePass123!"),
   *             @OA\Property(property="device_name", type="string", description="Nombre del dispositivo para identificar sesión", example="Web - Chrome"),
   *             @OA\Property(property="farmacia_id", type="string", format="uuid", description="ID de la farmacia asociada", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=201,
   *         description="Usuario de farmacia registrado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Usuario farmacia registrado exitosamente"),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="user", type="object",
   *                     @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                     @OA\Property(property="name", type="string", example="Gerente Farmacia"),
   *                     @OA\Property(property="email", type="string", format="email", example="gerente@farmacia.com"),
   *                     @OA\Property(property="avatar", type="string", format="url", nullable=true, example=null),
   *                     @OA\Property(property="is_active", type="boolean", example=true),
   *                     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                     @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"farmacia"}),
   *                     @OA\Property(property="perfil_farmacia", type="object", nullable=true, description="Perfil de la farmacia"),
   *                 ),
   *                 @OA\Property(property="access_token", type="string", description="Token de acceso Sanctum", example="1|abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx"),
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
   *         description="Error de validación - Datos inválidos o email duplicado",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function register(RegisterFarmaciaUserRequest $request)
  {
    $userData = $request->getUserData();
    $farmaciaUserData = $request->getFarmaciaUserData();
    $userData['password'] = Hash::make($userData['password']);

    /** @var User $user */
    $user = DB::transaction(function () use ($userData, $farmaciaUserData) {
      $user = User::create($userData);

      PerfilFarmacia::create(array_merge(['id' => $user->id], $farmaciaUserData));

      return $user;
    });

    $user->assignRole(RolesEnum::FARMACIA);

    $token = $user->createToken($request->getDeviceName())->plainTextToken;

    $user->load(RolesEnum::FARMACIA->getProfileRelationName());

    return ApiResponder::created(
      message: 'Usuario farmacia registrado exitosamente',
      data: [
        'user' => UserResource::make($user),
        'access_token' => $token,
      ]
    );
  }

  /**
   * @OA\Get(
   *     path="/api/users/farmacias/{perfilFarmaciaId}",
   *     operationId="farmaciaUsersShow",
   *     tags={"User","Farmacia"},
   *     summary="Obtener detalles de un usuario de farmacia",
   *     description="Retorna la información completa de un usuario de farmacia específico, incluyendo su perfil de farmacia.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilFarmaciaId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de farmacia",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Información del usuario de farmacia obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando datos del usuario de farmacia."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Gerente Farmacia"),
   *                 @OA\Property(property="email", type="string", format="email", example="gerente@farmacia.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", nullable=true, example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"farmacia"}),
   *                 @OA\Property(property="perfil_farmacia", type="object", nullable=true, description="Perfil de la farmacia"),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Usuario de farmacia no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function show(PerfilFarmacia $perfilFarmacia)
  {
    $user = $perfilFarmacia->user;
    $user->load(RolesEnum::FARMACIA->getProfileRelationName());

    return ApiResponder::success(
      message: 'Mostrando datos del usuario de farmacia.',
      data: UserResource::make($user)
    );
  }

  /**
   * @OA\Put(
   *     path="/api/users/farmacias/{perfilFarmaciaId}",
   *     operationId="farmaciaUsersUpdate",
   *     tags={"User","Farmacia"},
   *     summary="Actualizar datos de un usuario de farmacia",
   *     description="Actualiza la información de un usuario de farmacia. Los campos son opcionales; solo se actualizan los que se envían.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilFarmaciaId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de farmacia",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos a actualizar del usuario",
   *         @OA\JsonContent(
   *             @OA\Property(property="name", type="string", description="Nombre completo (opcional)", example="Gerente Farmacia Principal", maxLength=255),
   *             @OA\Property(property="email", type="string", format="email", description="Email único (opcional)", example="gerente.principal@farmacia.com", maxLength=255),
   *             @OA\Property(property="password", type="string", format="password", description="Nueva contraseña (opcional, requiere confirmation)", example="NewSecurePass123!"),
   *             @OA\Property(property="password_confirmation", type="string", format="password", description="Confirmación de contraseña", example="NewSecurePass123!"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Usuario de farmacia actualizado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Los datos del usuario han sido actualizados."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Gerente Farmacia Principal"),
   *                 @OA\Property(property="email", type="string", format="email", example="gerente.principal@farmacia.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", nullable=true, example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T15:45:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"farmacia"}),
   *             ),
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
   *         description="Usuario de farmacia no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación - Datos inválidos o email duplicado",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function update(UpdateBaseUserRequest $request, PerfilFarmacia $perfilFarmacia)
  {
    if (empty($request->validated())) {
      throw CustomException::badRequest('No se recibió información para actualizar');
    }

    $user = $perfilFarmacia->user;
    $userData = $request->getUserData();
    if ($request->hasPassword()) {
      $userData['password'] = Hash::make($userData['password']);
    }

    $user->update($userData);

    $user->load(RolesEnum::REPARTIDOR->getProfileRelationName());

    return ApiResponder::success(
      message: 'Los datos del usuario han sido actualizados.',
      data: UserResource::make($user),
    );
  }

  /**
   * @OA\Delete(
   *     path="/api/users/farmacias/{perfilFarmaciaId}",
   *     operationId="farmaciaUsersDestroy",
   *     tags={"User","Farmacia"},
   *     summary="Eliminar un usuario de farmacia",
   *     description="Elimina un usuario de farmacia del sistema. Se revoca automáticamente todos sus tokens activos y se elimina su perfil de farmacia.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="perfilFarmaciaId",
   *         in="path",
   *         required=true,
   *         description="UUID del perfil de farmacia",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Usuario de farmacia eliminado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El usuario de farmacia ha sido eliminado exitosamente."),
   *             @OA\Property(property="data", type="null", example=null),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Usuario de farmacia no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function destroy(PerfilFarmacia $perfilFarmacia)
  {
    $user = $perfilFarmacia->user;

    if (!$user) {
      throw CustomException::notFound('Usuario no encontrado');
    }

    DB::transaction(function () use ($perfilFarmacia, $user) {
      $perfilFarmacia->delete();
      $user->tokens()->delete();
      $user->delete();
    });

    return ApiResponder::success(
      message: 'El usuario de farmacia ha sido eliminado exitosamente.'
    );
  }
}

<?php

namespace App\Http\Controllers\User;

use App\Enums\RolesEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\User\List\IndexBaseUserRequest;
use App\Http\Requests\User\Register\RegisterAdminUserRequest;
use App\Http\Requests\User\Update\UpdateBaseUserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Hash;

class AdminUserController extends Controller
{
  /**
   * @OA\Get(
   *     path="/api/users/admins",
   *     operationId="adminUsersIndex",
   *     tags={"User","PerfilAdministrador"},
   *     summary="Listar usuarios administradores",
   *     description="Obtiene una lista paginada de usuarios administradores. Soporta filtrado por estado activo y búsqueda por nombre o email, con ordenamiento personalizable.",
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
   *         @OA\Schema(type="string", example="admin"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Lista de administradores obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando todos los usuarios administradores."),
   *             @OA\Property(property="data", type="array", items=@OA\Items(
   *                 type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Admin User"),
   *                 @OA\Property(property="email", type="string", format="email", example="admin@example.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", nullable=true, description="URL firmada de la foto de perfil", example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"administrador"}),
   *             )),
   *             @OA\Property(property="pagination", type="object",
   *                 @OA\Property(property="total", type="integer", example=42),
   *                 @OA\Property(property="per_page", type="integer", example=15),
   *                 @OA\Property(property="current_page", type="integer", example=1),
   *                 @OA\Property(property="last_page", type="integer", example=3),
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
   *         description="Error de validación en parámetros de paginación o filtrado",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function index(IndexBaseUserRequest $request)
  {
    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();
    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $query = User::role(RolesEnum::ADMINISTRADOR)
      ->with('roles');

    if ($request->hasIsActive()) {
      $isActiveFilter = $request->getIsActive();
      $query->where('is_active', $isActiveFilter);
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
      message: 'Mostrando todos los usuarios administradores.',
      data: UserResource::collection($pagination->items()),
      pagination: $pagination,
    );
  }

  /**
   * @OA\Post(
   *     path="/api/users/admins",
   *     operationId="adminUsersRegister",
   *     tags={"User","PerfilAdministrador"},
   *     summary="Crear nuevo usuario administrador",
   *     description="Registra un nuevo usuario administrador en el sistema. Se genera automáticamente un token de acceso para inicio de sesión inmediato.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos del nuevo administrador",
   *         @OA\JsonContent(
   *             required={"name","email","password","password_confirmation","device_name"},
   *             @OA\Property(property="name", type="string", description="Nombre completo del administrador", example="Juan García", maxLength=255),
   *             @OA\Property(property="email", type="string", format="email", description="Email único del administrador", example="juan@example.com", maxLength=255),
   *             @OA\Property(property="password", type="string", format="password", description="Contraseña del administrador (mín 8 caracteres, debe incluir mayúscula, número y símbolo)", example="SecurePass123!"),
   *             @OA\Property(property="password_confirmation", type="string", format="password", description="Confirmación de la contraseña", example="SecurePass123!"),
   *             @OA\Property(property="device_name", type="string", description="Nombre del dispositivo para identificar la sesión", example="Web - Chrome"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=201,
   *         description="Administrador registrado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Usuario registrado exitosamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="user", type="object",
   *                     @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                     @OA\Property(property="name", type="string", example="Juan García"),
   *                     @OA\Property(property="email", type="string", format="email", example="juan@example.com"),
   *                     @OA\Property(property="avatar", type="string", format="url", nullable=true, example=null),
   *                     @OA\Property(property="is_active", type="boolean", example=true),
   *                     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                     @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"administrador"}),
   *                 ),
   *                 @OA\Property(property="access_token", type="string", description="Token de acceso Sanctum para sesión inmediata", example="1|abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx"),
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
   *         description="Error de validación - Datos inválidos o email ya existe",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function register(RegisterAdminUserRequest $request)
  {
    $userData = $request->getUserData();
    $userData['password'] = Hash::make($userData['password']);

    /** @var User $user */
    $user = User::create($userData);

    $user->assignRole(RolesEnum::ADMINISTRADOR);

    $token = $user->createToken($request->getDeviceName())->plainTextToken;

    return ApiResponder::created('Usuario registrado exitosamente.', [
      'user' => UserResource::make($user),
      'access_token' => $token,
    ]);
  }

  /**
   * @OA\Get(
   *     path="/api/users/admins/{userId}",
   *     operationId="adminUsersShow",
   *     tags={"User","PerfilAdministrador"},
   *     summary="Obtener detalles de un administrador",
   *     description="Retorna la información completa de un usuario administrador específico, incluyendo sus roles.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="userId",
   *         in="path",
   *         required=true,
   *         description="UUID del administrador",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Información del administrador obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando datos del usuario administrador."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Juan García"),
   *                 @OA\Property(property="email", type="string", format="email", example="juan@example.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", nullable=true, example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"administrador"}),
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
   *         description="Usuario administrador no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function show(User $user)
  {
    $user->load(['roles']);

    return ApiResponder::success(
      message: 'Mostrando datos del usuario administrador.',
      data: UserResource::make($user)
    );
  }

  /**
   * @OA\Put(
   *     path="/api/users/admins/{userId}",
   *     operationId="adminUsersUpdate",
   *     tags={"User","PerfilAdministrador"},
   *     summary="Actualizar datos de un administrador",
   *     description="Actualiza la información de un usuario administrador. Los campos son opcionales; solo se actualizan los que se envían. Si se proporciona contraseña, debe incluirse la confirmación.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="userId",
   *         in="path",
   *         required=true,
   *         description="UUID del administrador",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Datos a actualizar del administrador",
   *         @OA\JsonContent(
   *             @OA\Property(property="name", type="string", description="Nombre completo (opcional)", example="Juan Carlos García", maxLength=255),
   *             @OA\Property(property="email", type="string", format="email", description="Email único (opcional)", example="juan.garcia@example.com", maxLength=255),
   *             @OA\Property(property="password", type="string", format="password", description="Nueva contraseña (opcional, requiere password_confirmation)", example="NewSecurePass123!"),
   *             @OA\Property(property="password_confirmation", type="string", format="password", description="Confirmación de nueva contraseña", example="NewSecurePass123!"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Administrador actualizado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Los datos del usuario han sido actualizados."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Juan Carlos García"),
   *                 @OA\Property(property="email", type="string", format="email", example="juan.garcia@example.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", nullable=true, example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T15:45:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"administrador"}),
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
   *         description="Usuario administrador no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación - Datos inválidos o email duplicado",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function update(UpdateBaseUserRequest $request, User $user)
  {
    if (empty($request->validated())) {
      throw CustomException::badRequest('No se recibió información para actualizar');
    }

    $userData = $request->getUserData();
    if ($request->hasPassword()) {
      $userData['password'] = Hash::make($userData['password']);
    }

    $user->update($userData);

    return ApiResponder::success(
      message: 'Los datos del usuario han sido actualizados.',
      data: UserResource::make($user),
    );
  }

  /**
   * @OA\Delete(
   *     path="/api/users/admins/{userId}",
   *     operationId="adminUsersDestroy",
   *     tags={"User","PerfilAdministrador"},
   *     summary="Eliminar un usuario administrador",
   *     description="Elimina un usuario administrador del sistema. Se revoca automáticamente todos sus tokens activos. No permite eliminar el último administrador del sistema.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="userId",
   *         in="path",
   *         required=true,
   *         description="UUID del administrador a eliminar",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Administrador eliminado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El usuario administrador ha sido eliminado exitosamente."),
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
   *         description="Usuario administrador no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=409,
   *         description="No se puede eliminar el último usuario administrador del sistema",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"error"}, example="error"),
   *             @OA\Property(property="message", type="string", example="No se puede eliminar el último usuario administrador del sistema."),
   *             @OA\Property(property="error", type="object",
   *                 @OA\Property(property="code", type="string", example="CONFLICT"),
   *                 @OA\Property(property="errors", type="null"),
   *             ),
   *         ),
   *     ),
   * )
   */
  public function destroy(User $user)
  {
    if ($user->hasRole(RolesEnum::ADMINISTRADOR)) {
      $adminCount = User::role(RolesEnum::ADMINISTRADOR)->count();

      if ($adminCount <= 1) {
        throw CustomException::conflict('No se puede eliminar el último usuario administrador del sistema.');
      }
    }

    $user->tokens()->delete();
    $user->delete();

    return ApiResponder::success(
      message: 'El usuario administrador ha sido eliminado exitosamente.'
    );
  }
}

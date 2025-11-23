<?php

namespace App\Http\Controllers\Auth;

use App\Enums\RolesEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Auth;
use Hash;
use Illuminate\Http\Request;
use Log;

class AuthController extends Controller
{
  private function loadUserProfileRelation(User $user): User
  {
    $roleName = $user->getRoleNames()->first();
    $roleEnum = RolesEnum::tryFrom($roleName);
    $relationName = null;

    if ($roleEnum !== null) {
      $relationName = $roleEnum->getProfileRelationName();

      if ($relationName !== null && method_exists($user, $relationName)) {
        $user->load($relationName);
      } elseif ($relationName !== null) {
        Log::warning(
          'Method "' . $relationName . '" for role "' . $roleName . '" was not found in User model when trying to load the profile.',
          ['user_id' => $user->id, 'role_name' => $roleName, 'relation_name' => $relationName]
        );
      }
    }

    return $user;
  }

  /**
   * @OA\Post(
   *     path="/api/auth/login",
   *     operationId="authLogin",
   *     tags={"Auth"},
   *     summary="Inicio de sesión",
   *     description="Autentica un usuario con email y contraseña. Retorna un token de acceso (Sanctum) que debe usarse en las peticiones posteriores.",
   *     @OA\RequestBody(
   *         required=true,
   *         description="Credenciales del usuario",
   *         @OA\JsonContent(
   *             required={"email","password","device_name"},
   *             @OA\Property(property="email", type="string", format="email", description="Email del usuario", example="admin@example.com"),
   *             @OA\Property(property="password", type="string", format="password", description="Contraseña del usuario", example="password"),
   *             @OA\Property(property="device_name", type="string", description="Nombre del dispositivo (móvil, web, etc)", example="iPhone 15 Pro"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Inicio de sesión exitoso",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Inicio de sesión exitoso."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="user", type="object",
   *                     @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                     @OA\Property(property="name", type="string", example="Admin User"),
   *                     @OA\Property(property="email", type="string", format="email", example="admin@example.com"),
   *                     @OA\Property(property="avatar", type="string", format="url", description="URL firmada de la foto de perfil", example="https://example.com/storage/signed-url"),
   *                     @OA\Property(property="is_active", type="boolean", example=true),
   *                     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                     @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"admin"}),
   *                     @OA\Property(property="perfil_repartidor", type="object", nullable=true, description="Perfil del repartidor si el usuario tiene ese rol"),
   *                     @OA\Property(property="perfil_farmacia", type="object", nullable=true, description="Perfil de la farmacia si el usuario tiene ese rol"),
   *                 ),
   *                 @OA\Property(property="access_token", type="string", description="Token de acceso Sanctum a usar en el header Authorization", example="1|abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx"),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Error de validación - Email, contraseña inválidos o cuenta desactivada",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"fail"}, example="fail"),
   *             @OA\Property(property="message", type="string", example="Los datos proporcionados no son válidos."),
   *             @OA\Property(property="error", type="object",
   *                 @OA\Property(property="code", type="string", example="VALIDATION_ERROR"),
   *                 @OA\Property(property="errors", type="object",
   *                     @OA\Property(property="email", type="array", items=@OA\Items(type="string"), example={"Las credenciales proporcionadas son incorrectas. (Email/Contraseña)","Tu cuenta está desactivada. Contacta al administrador."}),
   *                 ),
   *             ),
   *         ),
   *     ),
   * )
   */
  public function login(Request $request)
  {
    $request->validate([
      'email' => ['required', 'email'],
      'password' => ['required', 'string'],
      'device_name' => ['required', 'string'],
    ]);

    /** @var User|null $user */
    $user = User::where('email', $request->email)->first();

    if ($user === null || !Hash::check($request->password, $user->password)) {
      return ApiResponder::validationError(
        errors: ['email' => 'Las credenciales proporcionadas son incorrectas. (Email/Contraseña)']
      );
    }

    if (!$user->is_active) {
      return ApiResponder::validationError(
        errors: ['email' => 'Tu cuenta está desactivada. Contacta al administrador.']
      );
    }

    $user = $this->loadUserProfileRelation($user);

    $token = $user->createToken($request->device_name)->plainTextToken;

    return ApiResponder::success('Inicio de sesión exitoso.', [
      'user' => UserResource::make($user),
      'access_token' => $token,
    ]);
  }

  /**
   * @OA\Get(
   *     path="/api/auth/me",
   *     operationId="authMe",
   *     tags={"Auth"},
   *     summary="Obtener información del usuario autenticado",
   *     description="Retorna la información completa del usuario actualmente autenticado.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=200,
   *         description="Información del usuario obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Información del usuario autenticado."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="id", type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *                 @OA\Property(property="name", type="string", example="Admin User"),
   *                 @OA\Property(property="email", type="string", format="email", example="admin@example.com"),
   *                 @OA\Property(property="avatar", type="string", format="url", description="URL firmada de la foto de perfil", example="https://example.com/storage/signed-url"),
   *                 @OA\Property(property="is_active", type="boolean", example=true),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="roles", type="array", items=@OA\Items(type="string"), example={"admin"}),
   *                 @OA\Property(property="perfil_repartidor", type="object", nullable=true, description="Perfil del repartidor si el usuario tiene ese rol"),
   *                 @OA\Property(property="perfil_farmacia", type="object", nullable=true, description="Perfil de la farmacia si el usuario tiene ese rol"),
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function me(Request $request)
  {
    $user = Auth::user();

    $user = $this->loadUserProfileRelation($user);

    return ApiResponder::success(
      message: 'Información del usuario autenticado.',
      data: UserResource::make($user)
    );
  }

  /**
   * @OA\Post(
   *     path="/api/auth/logout",
   *     operationId="authLogout",
   *     tags={"Auth"},
   *     summary="Cerrar sesión en el dispositivo actual",
   *     description="Revoca el token del dispositivo actual. El usuario seguirá autenticado en otros dispositivos.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=204,
   *         description="Sesión cerrada exitosamente"
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function logout(Request $request)
  {
    /** @var \Illuminate\Database\Eloquent\Model $accessToken  */
    $accessToken = Auth::user()->currentAccessToken();

    $accessToken->delete();

    return ApiResponder::noContent('Sesión cerrada exitosamente.');
  }

  /**
   * @OA\Post(
   *     path="/api/auth/logout-all",
   *     operationId="authLogoutAll",
   *     tags={"Auth"},
   *     summary="Cerrar sesión en todos los dispositivos",
   *     description="Revoca todos los tokens del usuario. El usuario quedará completamente desautenticado en todos los dispositivos.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=204,
   *         description="Sesión cerrada en todos los dispositivos"
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function logoutAll(Request $request)
  {
    Auth::user()->tokens()->delete();

    return ApiResponder::noContent('Sesión cerrada en todos los dispositivos.');
  }

  /**
   * @OA\Get(
   *     path="/api/auth/tokens",
   *     operationId="authListTokens",
   *     tags={"Auth"},
   *     summary="Listar todas las sesiones activas",
   *     description="Retorna una lista de todos los tokens (sesiones activas) del usuario autenticado, incluyendo en cuál dispositivo fue usado por última vez.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=200,
   *         description="Lista de sesiones obtenida exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Sesiones activas obtenidas exitosamente."),
   *             @OA\Property(property="data", type="array", items=@OA\Items(
   *                 type="object",
   *                 @OA\Property(property="id", type="integer", example=1),
   *                 @OA\Property(property="name", type="string", description="Nombre del dispositivo", example="iPhone 15 Pro"),
   *                 @OA\Property(property="last_used_at", type="string", format="date-time", nullable=true, example="2025-11-22T14:30:00Z"),
   *                 @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T10:30:00Z"),
   *                 @OA\Property(property="is_current", type="boolean", description="Indica si es el token/sesión actual", example=true),
   *             )),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function listTokens(Request $request)
  {
    /** @var User $user */
    $user = $request->user();

    $tokens = $user->tokens()
      ->select('id', 'name', 'last_used_at', 'created_at')
      ->orderBy('last_used_at', 'desc')
      ->get();

    $currentTokenId = $user->currentAccessToken()->id;

    $formattedTokens = $tokens->map(function ($token) use ($currentTokenId) {
      return [
        'id' => $token->id,
        'name' => $token->name,
        'last_used_at' => $token->last_used_at,
        'created_at' => $token->created_at,
        'is_current' => ($token->id === $currentTokenId),
      ];
    });

    return ApiResponder::success(
      'Sesiones activas obtenidas exitosamente.',
      $formattedTokens
    );
  }

  /**
   * @OA\Delete(
   *     path="/api/auth/tokens/{tokenId}",
   *     operationId="authRevokeToken",
   *     tags={"Auth"},
   *     summary="Revocar una sesión específica",
   *     description="Revoca un token específico (sesión) del usuario. No puedes revocar el token que estás usando actualmente.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="tokenId",
   *         in="path",
   *         required=true,
   *         description="ID del token a revocar",
   *         @OA\Schema(type="integer", example=1),
   *     ),
   *     @OA\Response(
   *         response=204,
   *         description="Sesión revocada exitosamente"
   *     ),
   *     @OA\Response(
   *         response=400,
   *         description="No puedes revocar el token que estás usando actualmente",
   *         @OA\JsonContent(ref="#/components/schemas/BadRequestResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Token no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function revokeToken(Request $request, string $tokenId)
  {
    $user = Auth::user();

    $token = $user->tokens()->where('id', $tokenId)->first();

    if ($token == null) {
      throw CustomException::notFound('Token no encontrado o no pertenece a este usuario.');
    }

    if ($token->id === $user->currentAccessToken()->id) {
      throw CustomException::badRequest('No puedes revocar el token que estás usando actualmente.');
    }

    $token->delete();

    return ApiResponder::noContent('Sesión revocada exitosamente.');
  }
}

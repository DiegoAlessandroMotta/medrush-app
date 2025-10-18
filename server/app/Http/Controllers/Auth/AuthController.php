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
use Illuminate\Http\Response;
use Log;

use function Laravel\Prompts\error;

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

  public function me(Request $request)
  {
    $user = Auth::user();

    $user = $this->loadUserProfileRelation($user);

    return ApiResponder::success(
      message: 'Información del usuario autenticado.',
      data: UserResource::make($user)
    );
  }

  public function logout(Request $request)
  {
    /** @var \Illuminate\Database\Eloquent\Model $accessToken  */
    $accessToken = Auth::user()->currentAccessToken();

    $accessToken->delete();

    return ApiResponder::noContent('Sesión cerrada exitosamente.');
  }

  public function logoutAll(Request $request)
  {
    Auth::user()->tokens()->delete();

    return ApiResponder::noContent('Sesión cerrada en todos los dispositivos.');
  }

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

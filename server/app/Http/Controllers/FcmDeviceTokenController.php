<?php

namespace App\Http\Controllers;

use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Models\FcmDeviceToken;
use Auth;
use Illuminate\Http\Request;

class FcmDeviceTokenController extends Controller
{
  /**
   * @OA\Post(
   *     path="/api/fcm/tokens",
   *     operationId="fcmTokensStore",
   *     tags={"FCM","Device Tokens"},
   *     summary="Registrar o actualizar token FCM",
   *     description="Registra un nuevo token FCM para notificaciones push en el dispositivo actual. Si el token ya existe, actualiza la fecha de último uso. Útil para mantener múltiples dispositivos sincronizados.",
   *     security={{"sanctum":{}}},
   *     @OA\RequestBody(
   *         required=true,
   *         description="Token FCM del dispositivo",
   *         @OA\JsonContent(
   *             required={"token"},
   *             @OA\Property(property="token", type="string", description="Token FCM proporcionado por Firebase Cloud Messaging", example="eJZY5g7xR..."),
   *             @OA\Property(property="platform", type="string", nullable=true, description="Plataforma del dispositivo (ios, android, web, etc)", example="ios"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Token FCM registrado o actualizado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El token FCM ha sido registrado exitosamente."),
   *             @OA\Property(property="data", type="null"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Validación fallida - Token requerido",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
  public function store(Request $request)
  {
    $user = Auth::user();

    $request->validate([
      'token' => ['required', 'string'],
      'platform' => ['nullable', 'string'],
    ]);

    $existingToken = $user
      ->fcmDeviceTokens()
      ?->where('token', '=', $request->token)
      ->first();

    if ($existingToken !== null) {
      $existingToken->touch();
      return ApiResponder::success('El token FCM ha sido actualizado.');
    }

    $sessionId = $user->currentAccessToken()?->id;

    FcmDeviceToken::create([
      'user_id' => $user->id,
      'session_id' => $sessionId,
      'token' => $request->token,
      'platform' => $request->platform,
      'last_used_at' => now(),
    ]);

    return ApiResponder::success('El token FCM ha sido registrado exitosamente.');
  }

  /**
   * @OA\Delete(
   *     path="/api/fcm/tokens/{token}",
   *     operationId="fcmTokensDestroy",
   *     tags={"FCM","Device Tokens"},
   *     summary="Eliminar un token FCM específico",
   *     description="Elimina un token FCM específico del usuario. El usuario dejaría de recibir notificaciones push en ese dispositivo.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="token",
   *         in="path",
   *         required=true,
   *         description="Token FCM a eliminar",
   *         @OA\Schema(type="string", example="eJZY5g7xR..."),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Token eliminado o no encontrado",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El token FCM ha sido eliminado exitosamente."),
   *             @OA\Property(property="data", type="null"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function destroy(Request $request, string $token)
  {
    $user = Auth::user();

    $fcmToken = $user->fcmDeviceTokens()?->where('token', $token)->first();

    if ($fcmToken === null) {
      return ApiResponder::success('El token FCM no fue encontrado o ya ha sido eliminado.');
    }

    $fcmToken->delete();

    return ApiResponder::success('El token FCM ha sido eliminado exitosamente.');
  }

  /**
   * @OA\Delete(
   *     path="/api/fcm/tokens/sesion/actual",
   *     operationId="fcmTokensDestroyCurrentSessionTokens",
   *     tags={"FCM","Device Tokens"},
   *     summary="Eliminar tokens FCM de la sesión actual",
   *     description="Elimina todos los tokens FCM asociados a la sesión actual del usuario. Útil al cerrar sesión o en un dispositivo específico.",
   *     security={{"sanctum":{}}},
   *     @OA\Response(
   *         response=200,
   *         description="Tokens de la sesión eliminados",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Se eliminaron 2 tokens FCM asociados a la sesión actual."),
   *             @OA\Property(property="data", type="null"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=400,
   *         description="No hay sesión activa",
   *         @OA\JsonContent(ref="#/components/schemas/BadRequestResponse")
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   * )
   */
  public function destroyCurrentSessionTokens(Request $request)
  {
    $user = Auth::user();

    $sessionId = $user->currentAccessToken()?->id;

    if ($sessionId === null) {
      throw CustomException::badRequest('No hay una sesión activa para eliminar tokens.');
    }

    $deletedCount = $user->fcmDeviceTokens()?->where('session_id', $sessionId)->delete();

    return ApiResponder::success("Se eliminaron $deletedCount tokens FCM asociados a la sesión actual.");
  }
}

<?php

namespace App\Http\Controllers;

use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Models\FcmDeviceToken;
use Auth;
use Illuminate\Http\Request;

class FcmDeviceTokenController extends Controller
{
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

<?php

namespace App\Http\Controllers\User;

use App\Enums\RolesEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\User\Update\UploadProfilePictureRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\Disk\PrivateUploadsDiskService;
use Illuminate\Http\Request;

class BaseUserController extends Controller
{
  public function activo(Request $request, User $user)
  {
    $key = 'is_active';

    $request->validate([
      $key => ['required', 'boolean'],
    ]);

    $newState = $request->input($key);

    if (!$newState && $user->hasRole(RolesEnum::ADMINISTRADOR)) {
      $activeAdminsCount = User::role(RolesEnum::ADMINISTRADOR)
        ->where('is_active', true)
        ->count();

      if ($activeAdminsCount <= 1) {
        throw CustomException::badRequest('No se puede desactivar la cuenta del último administrador activo del sistema.');
      }
    }

    $user->update([$key => $newState]);

    return ApiResponder::success(
      message: 'El estado activo de la cuenta ha sido actualizado.',
      data: UserResource::make($user),
    );
  }

  public function uploadPicture(UploadProfilePictureRequest $request, User $user)
  {
    $oldAvatarPath = $user->avatar_path;

    if (!$request->hasFile('avatar')) {
      if ($oldAvatarPath !== null) {
        PrivateUploadsDiskService::delete($oldAvatarPath);
      }

      $user->update([
        'avatar_path' => null,
      ]);

      return ApiResponder::success(
        message: 'Foto de perfil eliminada correctamente.',
      );
    }

    $avatarFile = $request->file('avatar');
    $newAvatarPath = null;

    try {
      $newAvatarPath = PrivateUploadsDiskService::saveImage(
        imgPath: $avatarFile->getRealPath(),
        prefix: 'pfp-',
        width: 300,
        height: 300,
        crop: true
      );

      if ($newAvatarPath === null) {
        throw CustomException::internalServer('Error inesperado al intentar guardar la foto de perfil.');
      }

      $user->update([
        'avatar_path' => $newAvatarPath,
      ]);

      if ($oldAvatarPath !== null) {
        PrivateUploadsDiskService::delete($oldAvatarPath);
      }

      return ApiResponder::success(
        message: 'Foto de perfil actualizada correctamente.',
        data: [
          'url' => PrivateUploadsDiskService::getSignedUrl($newAvatarPath)
        ],
      );
    } catch (\Throwable $e) {
      if ($newAvatarPath !== null) {
        PrivateUploadsDiskService::delete($newAvatarPath);
      }

      throw CustomException::internalServer(
        'Error inesperado al intentar actualizar la foto de perfil.',
      );
    }
  }
}

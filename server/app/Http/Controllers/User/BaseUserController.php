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
  /**
   * @OA\Patch(
   *     path="/api/users/{userId}/activo",
   *     operationId="userToggleActive",
   *     tags={"User","Base"},
   *     summary="Activar o desactivar usuario",
   *     description="Activa o desactiva un usuario. Los administradores no pueden desactivarse a sí mismos ni puede haber solo uno activo en el sistema.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="userId",
   *         in="path",
   *         required=true,
   *         description="UUID del usuario",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\RequestBody(
   *         required=true,
   *         description="Nuevo estado activo",
   *         @OA\JsonContent(
   *             required={"is_active"},
   *             @OA\Property(property="is_active", type="boolean", example=true),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Estado actualizado exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="El estado activo de la cuenta ha sido actualizado."),
   *             @OA\Property(property="data", type="object"),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=400,
   *         description="No se puede desactivar el último administrador activo",
   *         @OA\JsonContent(ref="#/components/schemas/BadRequestResponse")
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=422,
   *         description="Valor inválido para is_active",
   *         @OA\JsonContent(ref="#/components/schemas/ValidationErrorResponse")
   *     ),
   * )
   */
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

  /**
   * @OA\Post(
   *     path="/api/users/{userId}/avatar",
   *     operationId="userUploadPicture",
   *     tags={"User","Base"},
   *     summary="Subir o actualizar foto de perfil",
   *     description="Carga o actualiza la foto de perfil del usuario. Puede omitirse el archivo para eliminar la foto actual.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="userId",
   *         in="path",
   *         required=true,
   *         description="UUID del usuario",
   *         @OA\Schema(type="string", format="uuid", example="f47ac10b-58cc-4372-a567-0e02b2c3d479"),
   *     ),
   *     @OA\RequestBody(
   *         required=false,
   *         description="Archivo de imagen",
   *         @OA\MediaType(
   *             mediaType="multipart/form-data",
   *             @OA\Schema(
   *                 type="object",
   *                 properties={
   *                     @OA\Property(
   *                         property="avatar",
   *                         description="Imagen JPEG/PNG. Opcional - si se omite, elimina la foto actual",
   *                         type="string",
   *                         format="binary"
   *                     )
   *                 }
   *             )
   *         )
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Foto de perfil actualizada o eliminada",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Foto de perfil actualizada correctamente."),
   *             @OA\Property(property="data", type="object",
   *                 @OA\Property(property="url", type="string", format="url", nullable=true, description="URL firmada para descargar la imagen"),
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
   *         description="Error al procesar la imagen",
   *         @OA\JsonContent(ref="#/components/schemas/ServerErrorResponse")
   *     ),
   * )
   */
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

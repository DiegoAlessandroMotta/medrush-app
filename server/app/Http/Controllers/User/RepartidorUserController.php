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
use App\Http\Requests\User\UploadFiles\UploadFotoDniIdRequest;
use App\Http\Requests\User\UploadFiles\UploadFotoLicenciaRequest;
use App\Http\Requests\User\UploadFiles\UploadFotoSeguroVehiculoRequest;
use App\Http\Resources\UserResource;
use App\Models\PerfilRepartidor;
use App\Models\User;
use App\Services\Disk\PrivateUploadsDiskService;
use DB;
use Hash;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RepartidorUserController extends Controller
{
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

  public function show(PerfilRepartidor $perfilRepartidor)
  {
    $user = $perfilRepartidor->user;
    $user->load(RolesEnum::REPARTIDOR->getProfileRelationName());

    return ApiResponder::success(
      message: 'Mostrando datos del usuario repartidor.',
      data: UserResource::make($user)
    );
  }

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

  public function uploadFotoDniId(UploadFotoDniIdRequest $request, PerfilRepartidor $perfilRepartidor)
  {
    if (!$request->hasFile('foto_dni_id')) {
      throw CustomException::validationException(errors: [
        'foto_dni_id' => 'Debe adjuntar una foto de su documento de identidad'
      ]);
    }

    $oldFotoDniIdPath = $perfilRepartidor->foto_dni_id_path;
    $fotoDniIdFile = $request->file('foto_dni_id');
    $newFotoDniIdPath = null;

    try {
      $newFotoDniIdPath = PrivateUploadsDiskService::saveImage(
        imgPath: $fotoDniIdFile->getRealPath(),
        prefix: 'di-',
        width: 1000,
        height: 1000,
      );

      if ($newFotoDniIdPath === null) {
        throw CustomException::internalServer('Error inesperado al intentar guardar la foto del documento.');
      }

      $perfilRepartidor->update([
        'foto_dni_id_path' => $newFotoDniIdPath,
      ]);

      if ($oldFotoDniIdPath !== null) {
        PrivateUploadsDiskService::delete($oldFotoDniIdPath);
      }

      return ApiResponder::success(
        message: 'La foto de su documento de identidad ha sido actualizada correctamente.',
        data: [
          'url' => PrivateUploadsDiskService::getSignedUrl($newFotoDniIdPath)
        ],
      );
    } catch (\Throwable $e) {
      if ($newFotoDniIdPath !== null) {
        PrivateUploadsDiskService::delete($newFotoDniIdPath);
      }

      throw CustomException::internalServer(
        'Error inesperado al intentar actualizar la foto del documento de identidad.',
        $e,
      );
    }
  }

  public function uploadFotoLicencia(UploadFotoLicenciaRequest $request, PerfilRepartidor $perfilRepartidor)
  {
    if (!$request->hasFile('foto_licencia')) {
      throw CustomException::validationException(errors: [
        'foto_licencia' => 'Debe adjuntar una foto de su licencia de conducir'
      ]);
    }

    $oldLicenciaPath = $perfilRepartidor->foto_licencia_path;
    $fotoLicenciaFile = $request->file('foto_licencia');
    $newFotoLicenciaPath = null;

    try {
      $newFotoLicenciaPath = PrivateUploadsDiskService::saveImage(
        imgPath: $fotoLicenciaFile->getRealPath(),
        prefix: 'l-',
        width: 1000,
        height: 1000,
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

  public function uploadFotoSeguroVehiculo(UploadFotoSeguroVehiculoRequest $request, PerfilRepartidor $perfilRepartidor)
  {
    if (!$request->hasFile('foto_seguro_vehiculo')) {
      throw CustomException::validationException(errors: [
        'foto_seguro_vehiculo' => 'Debe adjuntar una foto del seguro de su vehículo'
      ]);
    }

    $oldSeguroVehiculoPath = $perfilRepartidor->foto_seguro_vehiculo_path;
    $fotoSeguroVehiculoFile = $request->file('foto_seguro_vehiculo');
    $newFotoSeguroVehiculoPath = null;

    try {
      $newFotoSeguroVehiculoPath = PrivateUploadsDiskService::saveImage(
        imgPath: $fotoSeguroVehiculoFile->getRealPath(),
        prefix: 'sv-',
        width: 1000,
        height: 1000,
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

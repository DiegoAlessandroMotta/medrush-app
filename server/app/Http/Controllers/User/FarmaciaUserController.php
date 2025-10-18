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

  public function show(PerfilFarmacia $perfilFarmacia)
  {
    $user = $perfilFarmacia->user;
    $user->load(RolesEnum::FARMACIA->getProfileRelationName());

    return ApiResponder::success(
      message: 'Mostrando datos del usuario de farmacia.',
      data: UserResource::make($user)
    );
  }

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

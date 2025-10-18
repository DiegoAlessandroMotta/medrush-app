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

  public function show(User $user)
  {
    $user->load(['roles']);

    return ApiResponder::success(
      message: 'Mostrando datos del usuario administrador.',
      data: UserResource::make($user)
    );
  }

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

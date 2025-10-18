<?php

namespace App\Http\Controllers\Entities;

use App\Enums\EstadosFarmaciaEnum;
use App\Enums\PermissionsEnum;
use App\Enums\RolesEnum;
use App\Exceptions\CustomException;
use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Http\Requests\Farmacia\IndexFarmaciaRequest;
use App\Http\Requests\Farmacia\StoreFarmaciaRequest;
use App\Http\Requests\Farmacia\UpdateFarmaciaRequest;
use App\Http\Resources\FarmaciaResource;
use App\Http\Resources\UserResource;
use App\Models\Farmacia;
use App\Models\User;
use Auth;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FarmaciaController extends Controller
{
  public function index(IndexFarmaciaRequest $request)
  {
    $user = Auth::user();

    $perPage = $request->getPerPage();
    $currentPage = $request->getCurrentPage();
    $orderBy = $request->getOrderBy();
    $orderDirection = $request->getOrderDirection();

    $query = Farmacia::query();

    if (!$user->hasPermissionTo(PermissionsEnum::FARMACIAS_VIEW_ANY) && $user->hasPermissionTo(PermissionsEnum::FARMACIAS_VIEW_RELATED)) {
      if ($user->esFarmacia() && $user->perfilFarmacia !== null) {
        $farmaciaId = $user->perfilFarmacia->farmacia_id;
        $query->where('id', $farmaciaId);
      }
    }

    $ciudadFilter = $request->getCiudad();
    if ($ciudadFilter !== null) {
      $query->where('ciudad', $ciudadFilter);
    }

    $estadoRegionFilter = $request->getEstadoRegion();
    if ($estadoRegionFilter !== null) {
      $query->where('estado_region', $estadoRegionFilter);
    }

    if ($request->hasCodigoPostal()) {
      $codigoPostalFilter = $request->getCodigoPostalFilter();
      if ($codigoPostalFilter !== null) {
        $query->whereIn('codigo_postal', $codigoPostalFilter);
      } else {
        $query->where('codigo_postal', null);
      }
    }

    $codigoIsoPaisFilter = $request->getCodigoIsoPaisFilter();
    if ($codigoIsoPaisFilter !== null) {
      $query->whereIn('codigo_iso_pais', $codigoIsoPaisFilter);
    }

    $cadenaFilter = $request->getCadena();
    if ($cadenaFilter !== null) {
      $query->where('cadena', $cadenaFilter);
    }

    if ($request->hasDelivery24h()) {
      $delivery24hFilter = $request->getDelivery24h();
      $query->where('delivery_24h', $delivery24hFilter);
    }

    $estadoFilter = $request->getEstadoFilter();
    if ($estadoFilter !== null) {
      $query->whereIn('estado', $estadoFilter);
    }

    $fechaDesde = $request->getFechaDesde();
    $fechaHasta = $request->getFechaHasta();
    if ($fechaDesde !== null && $fechaHasta !== null) {
      $query->whereBetween('created_at', [$fechaDesde, $fechaHasta]);
    } elseif ($fechaDesde !== null) {
      $query->where('created_at', '>=', $fechaDesde);
    } elseif ($fechaHasta !== null) {
      $query->where('created_at', '<=', $fechaHasta);
    }

    $search = $request->getSearch();
    if ($request->hasSearch() && $search !== null) {
      $query->where(function ($q) use ($search) {
        $q->where('farmacias.nombre', 'like', "%{$search}%")
          ->orWhere('farmacias.razon_social', 'like', "%{$search}%")
          ->orWhere('farmacias.ruc_ein', 'like', "%{$search}%")
          ->orWhere('farmacias.direccion_linea_1', 'like', "%{$search}%")
          ->orWhere('farmacias.ciudad', 'like', "%{$search}%")
          ->orWhere('farmacias.estado_region', 'like', "%{$search}%")
          ->orWhere('farmacias.contacto_responsable', 'like', "%{$search}%")
          ->orWhere('farmacias.cadena', 'like', "%{$search}%");
      });
    }

    $query->orderBy($orderBy, $orderDirection);

    $pagination = $query->paginate(
      perPage: $perPage,
      page: $currentPage,
    );

    return ApiResponder::success(
      message: 'Mostrando lista de farmacias.',
      data: FarmaciaResource::collection($pagination->items()),
      pagination: $pagination
    );
  }

  public function store(StoreFarmaciaRequest $request)
  {
    $validatedData = $request->validated();

    $farmacia = Farmacia::create($validatedData);

    return ApiResponder::created(
      message: 'Farmacia creada exitosamente.',
      data: FarmaciaResource::make($farmacia),
    );
  }

  public function show(Farmacia $farmacia)
  {
    return ApiResponder::success(
      message: 'Mostrando datos de la farmacia.',
      data: FarmaciaResource::make($farmacia)
    );
  }

  public function listUsers(Farmacia $farmacia)
  {
    $relationName = RolesEnum::FARMACIA->getProfileRelationName();

    $users = User::whereHas($relationName, function ($query) use ($farmacia) {
      $query->where('farmacia_id', $farmacia->id);
    })
      ->with($relationName)
      ->get();

    return ApiResponder::success(
      message: 'Mostrando los usuarios que pertenecen a la farmacia.',
      data: UserResource::collection($users)
    );
  }

  public function update(UpdateFarmaciaRequest $request, Farmacia $farmacia)
  {
    $validatedData = $request->validated();

    if (sizeof($validatedData) === 0) {
      throw CustomException::badRequest('No se recibió información para actualizar');
    }

    $farmacia->update($validatedData);

    return ApiResponder::success(
      message: 'Farmacia creada exitosamente.',
      data: FarmaciaResource::make($farmacia),
    );
  }

  public function updateEstado(Request $request, Farmacia $farmacia)
  {
    $key = 'estado';

    $request->validate([$key => ['required', 'string', Rule::in(EstadosFarmaciaEnum::cases())]]);

    $farmacia->update([$key => $request->input($key)]);

    return ApiResponder::success(
      message: 'El estado de la farmacia ha sido actualizado',
      data: FarmaciaResource::make($farmacia),
    );
  }

  public function destroy(Farmacia $farmacia)
  {
    $farmacia->delete();

    return ApiResponder::noContent('Farmacia eliminada correctamente.');
  }
}

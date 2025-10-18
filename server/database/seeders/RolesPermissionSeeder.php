<?php

namespace Database\Seeders;

use App\Enums\PermissionsEnum;
use App\Enums\RolesEnum;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolesPermissionSeeder extends Seeder
{
  /**
   * Run the database seeds.
   */
  public function run(): void
  {
    foreach (RolesEnum::cases() as $role) {
      Role::findOrCreate($role->value);
    }

    app()[PermissionRegistrar::class]->forgetCachedPermissions();

    foreach (PermissionsEnum::cases() as $permission) {
      Permission::findOrCreate($permission->value);
    }

    $adminRole = Role::findByName(RolesEnum::ADMINISTRADOR->value);
    if ($adminRole) {
      $adminRole->givePermissionTo(array_column(PermissionsEnum::cases(), 'value'));
    }

    $repartidorRole = Role::findByName(RolesEnum::REPARTIDOR->value);
    if ($repartidorRole) {
      $repartidorRole->givePermissionTo([
        PermissionsEnum::PEDIDOS_VIEW_RELATED,
        PermissionsEnum::PEDIDOS_UPDATE_RELATED,
        PermissionsEnum::FARMACIAS_VIEW_RELATED,
        PermissionsEnum::RUTAS_VIEW_RELATED,
        PermissionsEnum::RUTAS_CREATE_RELATED,
        PermissionsEnum::RUTAS_UPDATE_RELATED,
        PermissionsEnum::RUTAS_DELETE_RELATED,
      ]);
    }

    $farmaciaRole = Role::findByName(RolesEnum::FARMACIA->value);
    if ($farmaciaRole) {
      $farmaciaRole->givePermissionTo([
        PermissionsEnum::PEDIDOS_VIEW_RELATED,
        PermissionsEnum::PEDIDOS_UPDATE_RELATED,
        PermissionsEnum::FARMACIAS_VIEW_RELATED,
        PermissionsEnum::FARMACIAS_UPDATE_RELATED,
      ]);
    }
  }
}

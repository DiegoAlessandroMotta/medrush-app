<?php

namespace App\Models;

use App\Casts\AsPoint;
use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosFarmaciaEnum;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property string $id
 * @property string $nombre
 * @property string|null $razon_social
 * @property string|null $ruc_ein
 * @property string $direccion_linea_1
 * @property string|null $direccion_linea_2
 * @property string $ciudad
 * @property string|null $estado_region
 * @property string|null $codigo_postal
 * @property CodigosIsoPaisEnum $codigo_iso_pais
 * @property \MatanYadaev\EloquentSpatial\Objects\Point|null $ubicacion
 * @property string|null $telefono
 * @property string|null $email
 * @property string|null $contacto_responsable
 * @property string|null $telefono_responsable
 * @property string|null $cadena
 * @property string|null $horario_atencion
 * @property bool $delivery_24h
 * @property EstadosFarmaciaEnum $estado
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Pedido> $pedidos
 * @property-read int|null $pedidos_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\PerfilRepartidor> $repartidores
 * @property-read int|null $repartidores_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\PerfilFarmacia> $usuariosFarmacia
 * @property-read int|null $usuarios_farmacia_count
 * @method static \Database\Factories\FarmaciaFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereCadena($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereCiudad($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereCodigoIsoPais($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereCodigoPostal($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereContactoResponsable($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereDelivery24h($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereDireccionLinea1($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereDireccionLinea2($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereEmail($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereEstado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereEstadoRegion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereHorarioAtencion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereNombre($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereRazonSocial($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereRucEin($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereTelefono($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereTelefonoResponsable($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereUbicacion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Farmacia whereUpdatedAt($value)
 * @mixin \Eloquent
 */
class Farmacia extends Model
{
  use HasUuids, HasFactory;

  protected $table = 'farmacias';
  protected $keyType = 'string';
  public $incrementing = false;

  protected $fillable = [
    'nombre',
    'razon_social',
    'ruc_ein',
    'direccion_linea_1',
    'direccion_linea_2',
    'ciudad',
    'estado_region',
    'codigo_postal',
    'codigo_iso_pais',
    'ubicacion',
    'telefono',
    'email',
    'contacto_responsable',
    'telefono_responsable',
    'cadena',
    'horario_atencion',
    'delivery_24h',
    'estado'
  ];

  protected function casts(): array
  {
    return [
      'delivery_24h' => 'boolean',
      'estado' => EstadosFarmaciaEnum::class,
      'codigo_iso_pais' => CodigosIsoPaisEnum::class,
      'ubicacion' => AsPoint::class
    ];
  }

  public function repartidores(): HasMany
  {
    return $this->hasMany(PerfilRepartidor::class, 'farmacia_id');
  }

  public function usuariosFarmacia(): HasMany
  {
    return $this->hasMany(PerfilFarmacia::class, 'farmacia_id');
  }

  public function pedidos(): HasMany
  {
    return $this->hasMany(Pedido::class, 'farmacia_id');
  }
}

<?php

namespace App\Models;

use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosRepartidorEnum;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property string $id
 * @property string|null $farmacia_id
 * @property CodigosIsoPaisEnum $codigo_iso_pais
 * @property string|null $dni_id_numero
 * @property string|null $foto_dni_id_path
 * @property string|null $telefono
 * @property string|null $licencia_numero
 * @property \Illuminate\Support\Carbon|null $licencia_vencimiento
 * @property string|null $foto_licencia_path
 * @property string|null $foto_seguro_vehiculo_path
 * @property string|null $vehiculo_placa
 * @property string|null $vehiculo_marca
 * @property string|null $vehiculo_modelo
 * @property int|null $vehiculo_anio
 * @property string|null $vehiculo_color
 * @property string|null $vehiculo_vin_chasis
 * @property string|null $vehiculo_tipo
 * @property float|null $vehiculo_capacidad_carga
 * @property string|null $vehiculo_codigo_registro
 * @property string|null $soat_numero
 * @property \Illuminate\Support\Carbon|null $soat_vencimiento
 * @property string|null $foto_soat_path
 * @property string|null $revision_tecnica_numero
 * @property \Illuminate\Support\Carbon|null $revision_tecnica_vencimiento
 * @property string|null $foto_revision_tecnica_path
 * @property string|null $tarjeta_circulacion_numero
 * @property string|null $foto_tarjeta_circulacion_path
 * @property string|null $registro_estatal_numero
 * @property \Illuminate\Support\Carbon|null $registro_estatal_vencimiento
 * @property string|null $foto_registro_estatal_path
 * @property string|null $inspeccion_numero
 * @property \Illuminate\Support\Carbon|null $inspeccion_vencimiento
 * @property string|null $foto_inspeccion_path
 * @property EstadosRepartidorEnum $estado
 * @property bool $verificado
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property \Illuminate\Support\Carbon|null $deleted_at
 * @property-read \App\Models\Farmacia|null $farmacia
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Pedido> $pedidos
 * @property-read int|null $pedidos_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Ruta> $rutas
 * @property-read int|null $rutas_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\UbicacionRepartidor> $ubicacionesRepartidor
 * @property-read int|null $ubicaciones_repartidor_count
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor onlyTrashed()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereCodigoIsoPais($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereDeletedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereDniIdNumero($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereEstado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereFarmaciaId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereFotoDniIdPath($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereFotoLicenciaPath($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereFotoSeguroVehiculoPath($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereLicenciaNumero($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereLicenciaVencimiento($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereTelefono($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereVehiculoMarca($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereVehiculoModelo($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereVehiculoPlaca($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor whereVerificado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor withTrashed(bool $withTrashed = true)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilRepartidor withoutTrashed()
 * @mixin \Eloquent
 */
class PerfilRepartidor extends Model
{
  use HasUuids, HasFactory, SoftDeletes;

  protected $table = 'perfiles_repartidor';
  protected $keyType = 'string';
  public $incrementing = false;

  protected $fillable = [
    'id',
    'farmacia_id',
    'codigo_iso_pais',
    'dni_id_numero',
    'foto_dni_id_path',
    'telefono',
    'licencia_numero',
    'licencia_vencimiento',
    'foto_licencia_path',
    'foto_seguro_vehiculo_path',
    'vehiculo_placa',
    'vehiculo_marca',
    'vehiculo_modelo',
    'vehiculo_codigo_registro',
    'estado',
    'verificado',
  ];

  protected function casts(): array
  {
    return [
      'codigo_iso_pais' => CodigosIsoPaisEnum::class,
      'licencia_vencimiento' => 'date',
      'estado' => EstadosRepartidorEnum::class,
      'verificado' => 'boolean',
    ];
  }

  public function user(): BelongsTo
  {
    return $this->belongsTo(User::class, 'id');
  }

  public function farmacia(): BelongsTo
  {
    return $this->belongsTo(Farmacia::class, 'farmacia_id');
  }

  public function pedidos(): HasMany
  {
    return $this->hasMany(Pedido::class, 'repartidor_id');
  }

  public function rutas(): HasMany
  {
    return $this->hasMany(Ruta::class, 'repartidor_id');
  }

  public function ubicacionesRepartidor(): HasMany
  {
    return $this->hasMany(UbicacionRepartidor::class, 'repartidor_id');
  }
}

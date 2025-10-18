<?php

namespace App\Models;

use App\Casts\AsPoint;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property string $repartidor_id
 * @property string|null $pedido_id
 * @property string|null $ruta_id
 * @property \MatanYadaev\EloquentSpatial\Objects\Point $ubicacion
 * @property float|null $precision_m
 * @property float|null $velocidad_ms
 * @property float|null $direccion
 * @property \Illuminate\Support\Carbon|null $fecha_registro
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property-read \App\Models\Pedido|null $pedido
 * @property-read \App\Models\PerfilRepartidor $repartidor
 * @property-read \App\Models\Ruta|null $ruta
 * @method static \Database\Factories\UbicacionRepartidorFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereDireccion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereFechaRegistro($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor wherePedidoId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor wherePrecisionM($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereRepartidorId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereRutaId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereUbicacion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|UbicacionRepartidor whereVelocidadMs($value)
 * @mixin \Eloquent
 */
class UbicacionRepartidor extends Model
{
  use HasFactory;

  protected $table = 'ubicaciones_repartidor';
  const UPDATED_AT = null;

  protected $fillable = [
    'repartidor_id',
    'pedido_id',
    'ruta_id',
    'ubicacion',
    'precision_m',
    'velocidad_ms',
    'direccion',
    'fecha_registro',
  ];

  protected function casts(): array
  {
    return [
      'ubicacion' => AsPoint::class,
      'precision_m' => 'float',
      'velocidad_ms' => 'float',
      'direccion' => 'float',
      'fecha_registro' => 'datetime',
    ];
  }

  public function repartidor(): BelongsTo
  {
    return $this->belongsTo(PerfilRepartidor::class, 'repartidor_id');
  }

  public function pedido(): BelongsTo
  {
    return $this->belongsTo(Pedido::class, 'pedido_id');
  }

  public function ruta(): BelongsTo
  {
    return $this->belongsTo(Ruta::class, 'ruta_id');
  }
}

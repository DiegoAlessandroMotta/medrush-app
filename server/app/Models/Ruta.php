<?php

namespace App\Models;

use App\Casts\AsPoint;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;

/**
 * @property string $id
 * @property string $repartidor_id
 * @property string|null $nombre
 * @property \MatanYadaev\EloquentSpatial\Objects\Point|null $punto_inicio
 * @property \MatanYadaev\EloquentSpatial\Objects\Point|null $punto_final
 * @property string|null $polyline_encoded
 * @property float|null $distancia_total_estimada
 * @property int|null $tiempo_total_estimado
 * @property int|null $cantidad_pedidos
 * @property \Illuminate\Support\Carbon|null $fecha_hora_calculo
 * @property \Illuminate\Support\Carbon|null $fecha_inicio
 * @property \Illuminate\Support\Carbon|null $fecha_completado
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\EntregaPedido> $entregasPedido
 * @property-read int|null $entregas_pedido_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Pedido> $pedidos
 * @property-read int|null $pedidos_count
 * @property-read \App\Models\PerfilRepartidor $repartidor
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\UbicacionRepartidor> $ubicacionesRepartidor
 * @property-read int|null $ubicaciones_repartidor_count
 * @method static \Database\Factories\RutaFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereCantidadPedidos($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereDistanciaTotalEstimada($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereFechaCompletado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereFechaHoraCalculo($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereFechaInicio($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereNombre($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta wherePolylineEncoded($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta wherePuntoFinal($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta wherePuntoInicio($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereRepartidorId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereTiempoTotalEstimado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Ruta whereUpdatedAt($value)
 * @mixin \Eloquent
 */
class Ruta extends Model
{
  use HasUuids, HasFactory;

  protected $table = 'rutas';
  protected $keyType = 'string';
  public $incrementing = false;

  protected $fillable = [
    'repartidor_id',
    'nombre',
    'punto_inicio',
    'punto_final',
    'polyline_encoded',
    'distancia_total_estimada',
    'tiempo_total_estimado',
    'cantidad_pedidos',
    'fecha_hora_calculo',
    'fecha_inicio',
    'fecha_completado',
  ];

  protected function casts(): array
  {
    return [
      'punto_inicio' => AsPoint::class,
      'punto_final' => AsPoint::class,
      'distancia_total_estimada' => 'float',
      'tiempo_total_estimado' => 'integer',
      'cantidad_pedidos' => 'integer',
      'fecha_hora_calculo' => 'datetime',
      'fecha_inicio' => 'datetime',
      'fecha_completado' => 'datetime',
    ];
  }

  public function repartidor(): BelongsTo
  {
    return $this->belongsTo(PerfilRepartidor::class, 'repartidor_id');
  }

  public function entregasPedido(): HasMany
  {
    return $this->hasMany(EntregaPedido::class, 'ruta_id');
  }

  public function pedidos(): HasManyThrough
  {
    return $this->hasManyThrough(
      Pedido::class,
      EntregaPedido::class,
      'ruta_id',
      'id',
      'id',
      'pedido_id'
    );
  }

  public function ubicacionesRepartidor(): HasMany
  {
    return $this->hasMany(UbicacionRepartidor::class, 'ruta_id');
  }
}

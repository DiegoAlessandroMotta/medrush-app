<?php

namespace App\Models;

use App\Traits\MassUpdatable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property string $ruta_id
 * @property string $pedido_id
 * @property int|null $orden_optimizado
 * @property int $orden_personalizado
 * @property int|null $orden_recojo
 * @property bool $optimizado
 * @property-read \App\Models\Pedido $pedido
 * @property-read \App\Models\Ruta $ruta
 * @method static \Database\Factories\EntregaPedidoFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido massUpdate(\Illuminate\Support\Enumerable|array $values, array|string|null $uniqueBy = null)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido whereOptimizado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido whereOrdenOptimizado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido whereOrdenPersonalizado($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido whereOrdenRecojo($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido wherePedidoId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EntregaPedido whereRutaId($value)
 * @mixin \Eloquent
 */
class EntregaPedido extends Model
{
  use HasFactory, MassUpdatable;

  protected $table = 'entregas_pedido';
  public $timestamps = false;

  protected $fillable = [
    'ruta_id',
    'pedido_id',
    'orden_optimizado',
    'orden_personalizado',
    'orden_recojo',
    'optimizado',
  ];

  protected $casts = [
    'orden_optimizado' => 'integer',
    'orden_personalizado' => 'integer',
    'orden_recojo' => 'integer',
    'optimizado' => 'boolean',
  ];

  public function ruta(): BelongsTo
  {
    return $this->belongsTo(Ruta::class, 'ruta_id');
  }

  public function pedido(): BelongsTo
  {
    return $this->belongsTo(Pedido::class, 'pedido_id');
  }
}

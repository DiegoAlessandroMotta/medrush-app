<?php

namespace App\Models;

use App\Casts\AsPoint;
use App\Enums\EventosPedidoEnum;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use MatanYadaev\EloquentSpatial\Objects\Point;

/**
 * @property int $id
 * @property string $pedido_id
 * @property string|null $user_id
 * @property EventosPedidoEnum $tipo_evento
 * @property string|null $descripcion
 * @property array<array-key, mixed>|null $metadata
 * @property \MatanYadaev\EloquentSpatial\Objects\Point|null $ubicacion
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Pedido $pedido
 * @property-read \App\Models\User|null $user
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereDescripcion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereMetadata($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido wherePedidoId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereTipoEvento($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereUbicacion($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|EventoPedido whereUserId($value)
 * @mixin \Eloquent
 */
class EventoPedido extends Model
{
  use HasFactory;

  protected $table = 'eventos_pedido';

  protected $fillable = [
    'pedido_id',
    'user_id',
    'tipo_evento',
    'descripcion',
    'metadata',
    'ubicacion',
  ];

  protected function casts(): array
  {
    return  [
      'metadata' => 'array',
      'tipo_evento' => EventosPedidoEnum::class,
      'ubicacion' => AsPoint::class,
    ];
  }

  public function pedido(): BelongsTo
  {
    return $this->belongsTo(Pedido::class, 'pedido_id');
  }

  public function user(): BelongsTo
  {
    return $this->belongsTo(User::class, 'user_id');
  }
}

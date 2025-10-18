<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * @property string $id
 * @property string $farmacia_id
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property \Illuminate\Support\Carbon|null $deleted_at
 * @property-read \App\Models\Farmacia $farmacia
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia onlyTrashed()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia whereDeletedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia whereFarmaciaId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia withTrashed(bool $withTrashed = true)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|PerfilFarmacia withoutTrashed()
 * @mixin \Eloquent
 */
class PerfilFarmacia extends Model
{
  use HasUuids, HasFactory, SoftDeletes;

  protected $table = 'perfiles_farmacia';
  protected $keyType = 'string';
  public $incrementing = false;

  protected $fillable = [
    'id',
    'farmacia_id'
  ];

  public function user(): BelongsTo
  {
    return $this->belongsTo(User::class, 'id');
  }

  public function farmacia(): BelongsTo
  {
    return $this->belongsTo(Farmacia::class, 'farmacia_id');
  }
}

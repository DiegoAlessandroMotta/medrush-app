<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property string $id
 * @property string|null $user_id
 * @property array<array-key, mixed>|null $context
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User|null $user
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError whereContext($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|ClientError whereUserId($value)
 * @mixin \Eloquent
 */
class ClientError extends Model
{
  use HasUuids;

  protected $fillable = [
    'user_id',
    'context',
  ];

  protected $casts = [
    'context' => 'array',
  ];

  public function user(): BelongsTo
  {
    return $this->belongsTo(User::class);
  }
}

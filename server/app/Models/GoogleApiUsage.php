<?php

namespace App\Models;

use App\Enums\GoogleApiServiceType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property string|null $user_id
 * @property GoogleApiServiceType $type
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User|null $user
 * @method static \Database\Factories\GoogleApiUsageFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage whereType($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|GoogleApiUsage whereUserId($value)
 * @mixin \Eloquent
 */
class GoogleApiUsage extends Model
{
  use HasFactory;

  protected $table = 'google_api_usages';

  protected $fillable = [
    'user_id',
    'type'
  ];

  protected function casts(): array
  {
    return [
      'type' => GoogleApiServiceType::class
    ];
  }

  public function user(): BelongsTo
  {
    return $this->belongsTo(User::class);
  }
}

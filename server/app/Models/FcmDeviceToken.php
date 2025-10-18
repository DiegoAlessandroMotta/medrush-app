<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property string|null $user_id
 * @property int|null $session_id
 * @property string $token
 * @property string $platform
 * @property \Illuminate\Support\Carbon|null $last_used_at
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User|null $user
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken whereLastUsedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken wherePlatform($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken whereSessionId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken whereToken($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|FcmDeviceToken whereUserId($value)
 * @mixin \Eloquent
 */
class FcmDeviceToken extends Model
{
  protected $table = 'fcm_device_tokens';

  protected $fillable = [
    'user_id',
    'session_id',
    'token',
    'platform',
    'last_used_at',
  ];

  protected function casts(): array
  {
    return [
      'last_used_at' => 'datetime',
    ];
  }

  public function user(): BelongsTo
  {
    return $this->belongsTo(User::class, 'user_id');
  }
}

<?php

namespace App\Models;

use App\Enums\GoogleApiServiceType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

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

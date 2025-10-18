<?php

namespace App\DTOs;

use Illuminate\Contracts\Support\Arrayable;

class CursorItemDto implements Arrayable
{
  public function __construct(
    public int|string $id,
    public string $key,
    public string|int|float $value,
  ) {}

  public function toArray(): array
  {
    return [
      'id' => $this->id,
      $this->key => $this->value,
    ];
  }
}

<?php

namespace App\DTOs;

use Illuminate\Contracts\Support\Arrayable;

class CursorPaginationDto implements Arrayable
{
  public function __construct(
    public int $limit,
    public bool $hasMore,
    public ?string $nextCursor = null,
    public ?CursorItemDto $lastItem = null,
  ) {}

  public function toArray(): array
  {
    return [
      'limit' => $this->limit,
      'has_more' => $this->hasMore,
      'next_cursor' => $this->nextCursor,
      'last_item' => $this->lastItem?->toArray(),
    ];
  }
}

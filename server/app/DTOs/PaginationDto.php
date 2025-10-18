<?php

namespace App\DTOs;

use Illuminate\Contracts\Support\Arrayable;
use Illuminate\Pagination\LengthAwarePaginator;

final class PaginationDto implements Arrayable
{
  public function __construct(
    public int $total,
    public int $perPage,
    public int $currentPage,
    public int $lastPage,
    public ?string $nextPageUrl,
    public ?string $prevPageUrl,
    public ?int $from,
    public ?int $to,
    public array $items = [],
  ) {}

  public static function fromLengthAwarePaginator(
    LengthAwarePaginator $paginator
  ): self {
    return new self(
      total: $paginator->total(),
      perPage: $paginator->perPage(),
      currentPage: $paginator->currentPage(),
      lastPage: $paginator->lastPage(),
      nextPageUrl: $paginator->nextPageUrl(),
      prevPageUrl: $paginator->previousPageUrl(),
      from: $paginator->firstItem(),
      to: $paginator->lastItem(),
      items: $paginator->items()
    );
  }

  public function toArray(): array
  {
    return [
      'total' => $this->total,
      'per_page' => $this->perPage,
      'current_page' => $this->currentPage,
      'last_page' => $this->lastPage,
      'next_page_url' => $this->nextPageUrl,
      'prev_page_url' => $this->prevPageUrl,
      'from' => $this->from,
      'to' => $this->to,
    ];
  }
}

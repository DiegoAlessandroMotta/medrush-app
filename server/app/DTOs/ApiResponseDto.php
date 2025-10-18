<?php

namespace App\DTOs;

use App\DTOs\CursorPaginationDto;
use App\Enums\ResponseStatusEnum;
use Illuminate\Contracts\Support\Arrayable;

final class ApiResponseDto implements Arrayable
{
  public function __construct(
    public ResponseStatusEnum $status,
    public ?string $message = null,
    public mixed $data = null,
    public ?PaginationDto $pagination = null,
    public ?CursorPaginationDto $cursorPagination = null,
    public array $metadata = [],
    public ?ErrorDto $error = null,
  ) {}

  public function toArray(): array
  {
    $response = [
      'status' => $this->status->value,
      'message' => $this->message,
    ];

    if ($this->data !== null) {
      $response['data'] = $this->data;
    }

    if ($this->pagination !== null) {
      if ($this->data === null) {
        $response['data'] = $this->pagination->items;
      }

      $response['pagination'] = $this->pagination->toArray();
    }

    if ($this->cursorPagination !== null) {
      $response['cursor_pagination'] = $this->cursorPagination->toArray();
    }

    if (!empty($this->metadata)) {
      $response['metadata'] = $this->metadata;
    }

    if ($this->error !== null) {
      $response['error'] = $this->error->toArray();
    }

    return $response;
  }
}

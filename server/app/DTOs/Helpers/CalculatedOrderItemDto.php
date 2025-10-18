<?php

namespace App\DTOs\Helpers;

class CalculatedOrderItemDto
{
  public function __construct(
    public int|string $id,
    public int $newOrder,
  ) {}
}

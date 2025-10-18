<?php

namespace App\DTOs;

use App\Enums\ErrorCodesEnum;
use Illuminate\Contracts\Support\Arrayable;

final class ErrorDto implements Arrayable
{
  public function __construct(
    public ErrorCodesEnum $code,
    public ?array $errors = null,
  ) {}

  public function toArray(): array
  {
    $error = ['code' => $this->code->value];

    if (!empty($this->errors)) {
      $error['errors'] = $this->errors;
    }

    return $error;
  }
}

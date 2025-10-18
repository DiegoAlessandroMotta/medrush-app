<?php

namespace App\Http\Requests\User\List;

use App\Http\Requests\BasePaginationRequest;
use Illuminate\Validation\Rule;

class IndexBaseUserRequest extends BasePaginationRequest
{
  public const USER_TABLE = 'users';
  public const ORDER_BY_FIELDS = [
    'created_at',
    'updated_at',
    'name',
    'email',
    'is_active',
  ];

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'is_active' => ['sometimes', 'nullable', 'boolean'],
      'order_by' => ['sometimes', 'string', Rule::in(self::ORDER_BY_FIELDS)],
    ]);
  }

  protected function prepareForValidation(): void
  {
    parent::prepareForValidation();

    $this->preprocessBooleanField('is_active');
  }

  public function hasIsActive(): bool
  {
    return $this->has('is_active');
  }

  public function getIsActive(): ?bool
  {
    return $this->input('is_active');
  }

  public function getRawOrderBy(): string
  {
    return $this->input('order_by');
  }
}

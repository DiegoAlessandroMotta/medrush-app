<?php

namespace App\Http\Requests\Notificacion;

use App\Http\Requests\BasePaginationRequest;
use Illuminate\Validation\Rule;

class IndexNotificacionRequest extends BasePaginationRequest
{
  public const ORDER_BY_FIELDS = [
    'created_at',
    'updated_at',
    'read_at',
  ];

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'unread_only' => ['sometimes', 'nullable', 'boolean'],
      'type' => ['sometimes', 'nullable', 'string', 'max:255'],
      'order_by' => ['sometimes', 'string', Rule::in(self::ORDER_BY_FIELDS)],
    ]);
  }

  protected function prepareForValidation(): void
  {
    parent::prepareForValidation();

    $this->preprocessBooleanField('unread_only');
  }

  public function hasUnreadOnly(): bool
  {
    return $this->has('unread_only');
  }

  public function getUnreadOnly(): ?bool
  {
    return $this->input('unread_only');
  }

  public function hasType(): bool
  {
    return $this->filled('type');
  }

  public function getType(): ?string
  {
    return $this->input('type');
  }

  public function getRawOrderBy(): string
  {
    return $this->input('order_by');
  }
}

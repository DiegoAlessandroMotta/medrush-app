<?php

namespace App\Http\Requests\User\List;

class IndexFarmaciaUserRequest extends IndexBaseUserRequest
{
  private ?string $orderBy = null;

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'farmacia_id' => ['sometimes', 'string', 'uuid'],
    ]);
  }

  protected function prepareForValidation(): void
  {
    parent::prepareForValidation();
  }

  public function passedValidation(): void
  {
    $this->computeOrderBy();
  }

  private function computeOrderBy(): void
  {
    $orderBy = $this->getRawOrderBy();
    $prefix = 'perfiles_farmacia';

    if (in_array($orderBy, parent::ORDER_BY_FIELDS)) {
      $prefix = parent::USER_TABLE;
    }

    $this->orderBy = $prefix . '.' . $orderBy;
  }

  public function getOrderBy(): string
  {
    return $this->orderBy;
  }

  public function getFarmaciaId(): ?bool
  {
    return $this->input('farmacia_id');
  }
}

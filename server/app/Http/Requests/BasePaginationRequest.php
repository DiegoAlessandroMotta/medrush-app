<?php

namespace App\Http\Requests;

use App\Helpers\PrepareData;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class BasePaginationRequest extends FormRequest
{
  protected int $defaultPerPage = 20;
  protected int $maxPerPage = 50;
  protected int $minPerPage = 1;
  protected int $defaultCurrentPage = 1;
  protected string $defaultOrderDirection = 'desc';
  protected string $defaultOrderBy = 'created_at';
  private array $orderDirections = ['asc', 'desc'];

  public function rules(): array
  {
    return [
      'per_page' => ['sometimes', 'integer', 'min:' . $this->minPerPage, 'max:' . $this->maxPerPage],
      'current_page' => ['sometimes', 'integer', 'min:1'],
      'order_direction' => ['sometimes', 'string',  Rule::in($this->orderDirections)],
      'fecha_desde' => ['sometimes', 'date'],
      'fecha_hasta' => ['sometimes', 'date'],
      'search' => ['sometimes', 'string', 'max:255'],
    ];
  }

  protected function prepareForValidation(): void
  {
    $perPage = $this->input('per_page', $this->defaultPerPage);
    if ($perPage > $this->maxPerPage) {
      $perPage = $this->maxPerPage;
    } elseif ($perPage < $this->minPerPage) {
      $perPage = $this->minPerPage;
    }

    $this->merge([
      'per_page' => $perPage,
      'current_page' => $this->input('current_page', $this->defaultCurrentPage),
      'order_direction' => $this->input('order_direction', $this->defaultOrderDirection),
      'order_by' => $this->input('order_by', $this->defaultOrderBy)
    ]);
  }

  public function replaceNullString(string $field): void
  {
    if ($this->has($field) && $this->input($field) === 'null') {
      $this->merge([$field => null]);
    }
  }

  public function preprocessBooleanField(string $field): void
  {
    if ($this->has($field)) {
      if ($this->input($field) === 'null') {
        $this->merge([$field => null]);
      } else {
        $this->merge([$field => PrepareData::boolean($this->input($field))]);
      }
    }
  }

  public function getPerPage(): int
  {
    return (int) $this->input('per_page');
  }

  public function getCurrentPage(): int
  {
    return (int) $this->input('current_page');
  }

  public function getOrderDirection(): string
  {
    return $this->input('order_direction');
  }

  public function getOrderBy(): string
  {
    return $this->input('order_by');
  }

  public function getFechaDesde(): ?string
  {
    return $this->input('fecha_desde');
  }

  public function getFechaHasta(): ?string
  {
    return $this->input('fecha_hasta');
  }

  public function hasSearch(): ?bool
  {
    return $this->has('search');
  }

  public function getSearch(): ?string
  {
    return $this->input('search');
  }
}

<?php

namespace App\Http\Requests;

use Illuminate\Validation\Rule;

class ClientErrorIndexRequest extends BasePaginationRequest
{
  protected int $defaultPerPage = 15;
  protected int $maxPerPage = 100;

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'error_type' => 'sometimes|string|max:255',
      'platform' => 'sometimes|string|in:web,android,ios',
      'user_id' => 'sometimes|uuid|exists:users,id',
      'from_date' => 'sometimes|date',
      'to_date' => 'sometimes|date|after_or_equal:from_date',
    ]);
  }

  public function messages(): array
  {
    return [
      'platform.in' => 'La plataforma debe ser web, android o ios.',
      'user_id.exists' => 'El usuario especificado no existe.',
      'to_date.after_or_equal' => 'La fecha hasta debe ser mayor o igual a la fecha desde.',
    ];
  }

  public function getErrorType(): ?string
  {
    return $this->input('error_type');
  }

  public function getPlatform(): ?string
  {
    return $this->input('platform');
  }

  public function getUserId(): ?string
  {
    return $this->input('user_id');
  }

  public function getFromDate(): ?string
  {
    return $this->input('from_date');
  }

  public function getToDate(): ?string
  {
    return $this->input('to_date');
  }
}

<?php

namespace App\Http\Requests\User\Register;

use App\Models\Farmacia;
use Arr;
use Illuminate\Validation\Rule;

class RegisterFarmaciaUserRequest extends RegisterBaseUserRequest
{
  protected const FARMACIA_USER_FIELDS = [
    'farmacia_id',
  ];

  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'farmacia_id' => ['required', 'uuid', Rule::exists(Farmacia::class, 'id')],
    ]);
  }

  public function getFarmaciaUserData(): array
  {
    return Arr::only($this->validated(), self::FARMACIA_USER_FIELDS);
  }
}

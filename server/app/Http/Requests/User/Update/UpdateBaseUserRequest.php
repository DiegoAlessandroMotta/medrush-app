<?php

namespace App\Http\Requests\User\Update;

use Arr;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules;

class UpdateBaseUserRequest extends FormRequest
{
  protected const USER_FIELDS = [
    'name',
    'email',
    'password',
  ];

  public function rules(): array
  {
    return [
      'name' => ['sometimes', 'required', 'string', 'max:255'],
      'email' => ['sometimes', 'required', 'string', 'email', 'max:255', Rule::unique('users')],
      'password' => ['sometimes', 'required', 'confirmed', Rules\Password::defaults()],
    ];
  }

  public function hasPassword()
  {
    return $this->has('password');
  }

  public function getUserData(): array
  {
    return Arr::only($this->validated(), self::USER_FIELDS);
  }
}

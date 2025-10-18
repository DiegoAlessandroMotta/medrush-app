<?php

namespace App\Http\Requests\User\Register;

use Arr;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules;

class RegisterBaseUserRequest extends FormRequest
{
  protected const USER_FIELDS = [
    'name',
    'email',
    'password'
  ];

  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'name' => ['required', 'string', 'max:255'],
      'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
      'password' => ['required', 'confirmed', Rules\Password::defaults()],
      'device_name' => ['required', 'string'],
    ];
  }

  public function getUserData(): array
  {
    return Arr::only($this->validated(), self::USER_FIELDS);
  }

  public function getDeviceName(): string
  {
    return $this->input('device_name');
  }
}

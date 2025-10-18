<?php

namespace App\Http\Requests\User\Register;

class RegisterAdminUserRequest extends RegisterBaseUserRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return parent::rules();
  }
}

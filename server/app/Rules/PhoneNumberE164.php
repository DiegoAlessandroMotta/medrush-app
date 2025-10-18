<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class PhoneNumberE164 implements ValidationRule
{
  public function validate(string $attribute, mixed $value, Closure $fail): void
  {
    if (!is_string($value)) {
      $fail('El número de teléfono debe ser una cadena de texto.');
      return;
    }

    if (!preg_match('/^\+[1-9]\d{1,14}$/', $value)) {
      $fail('El número de teléfono debe estar en formato E.164 (ejemplo: +51999999999).');
    }
  }
}

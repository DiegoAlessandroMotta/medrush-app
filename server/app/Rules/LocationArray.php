<?php

namespace App\Rules;

use App\Helpers\PrepareData;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class LocationArray implements ValidationRule
{
  public function validate(string $attribute, mixed $value, Closure $fail): void
  {
    $parsedLocation = PrepareData::location($value);

    if (is_null($parsedLocation)) {
      $fail('El campo :attribute debe ser un array válido con claves latitude y longitude, o una cadena de texto "latitud,longitud".');
      return;
    }

    if (
      !isset($parsedLocation['latitude']) ||
      !is_numeric($parsedLocation['latitude']) ||
      $parsedLocation['latitude'] < -90 ||
      $parsedLocation['latitude'] > 90
    ) {
      $fail('La latitud en :attribute es inválida. Debe ser un número entre -90 y 90.');
    }

    if (
      !isset($parsedLocation['longitude']) ||
      !is_numeric($parsedLocation['longitude']) ||
      $parsedLocation['longitude'] < -180 ||
      $parsedLocation['longitude'] > 180
    ) {
      $fail('La longitud en :attribute es inválida. Debe ser un número entre -180 y 180.');
    }
  }
}

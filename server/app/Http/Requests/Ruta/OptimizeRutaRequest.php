<?php

namespace App\Http\Requests\Ruta;

use App\Rules\LocationArray;
use Illuminate\Foundation\Http\FormRequest;

class OptimizeRutaRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'inicio_jornada' => ['required', 'date'],
      'fin_jornada' => ['required', 'date'],
      'ubicacion_actual' => ['sometimes', new LocationArray],
      'ignorar_recojos' => ['sometimes', 'boolean'],
    ];
  }

  protected function prepareForValidation(): void
  {
    $this->merge([
      'ignorar_recojos' => false,
    ]);
  }
}

<?php

namespace App\Http\Requests\Ruta;

use App\Enums\CodigosIsoPaisEnum;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class OptimizeAllRutaRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'codigo_iso_pais' => ['required', Rule::in(CodigosIsoPaisEnum::cases())],
      'inicio_jornada' => ['required', 'date'],
      'fin_jornada' => ['required', 'date'],
      'codigo_postal' => ['sometimes', 'nullable', 'string', 'max:20'],
    ];
  }
}

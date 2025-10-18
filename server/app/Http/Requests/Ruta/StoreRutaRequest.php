<?php

namespace App\Http\Requests\Ruta;

use App\Models\PerfilRepartidor;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreRutaRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'repartidor_id' => ['required', 'uuid', Rule::exists(PerfilRepartidor::class, 'id')],
      'nombre' => ['sometimes', 'nullable', 'string', 'max:255'],
    ];
  }
}

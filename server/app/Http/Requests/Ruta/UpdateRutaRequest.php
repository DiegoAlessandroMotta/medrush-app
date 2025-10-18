<?php

namespace App\Http\Requests\Ruta;

use App\Models\PerfilRepartidor;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateRutaRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'repartidor_id' => ['sometimes', 'required', 'uuid', Rule::exists(PerfilRepartidor::class, 'id')],
      'nombre' => ['sometimes', 'nullable', 'string', 'max:255'],
    ];
  }

  public function hasRepartidorId(): ?string
  {
    return $this->has('repartidor_id');
  }

  public function getRepartidorId(): ?string
  {
    return $this->input('repartidor_id');
  }
}

<?php

namespace App\Http\Requests\Farmacia;

use App\Enums\CodigosIsoPaisEnum;
use App\Helpers\PrepareData;
use App\Rules\LocationArray;
use App\Rules\PhoneNumberE164;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateFarmaciaRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'nombre' => ['sometimes', 'required', 'string', 'max:255'],
      'razon_social' => ['sometimes', 'nullable', 'string', 'max:255'],
      // EIN, opcional
      'ruc_ein' => ['sometimes', 'nullable', 'string', 'max:255', Rule::unique('farmacias')->ignore($this->route('farmacia'))],
      'direccion_linea_1' => ['sometimes', 'required', 'string', 'max:255'],
      'direccion_linea_2' => ['sometimes', 'nullable', 'string', 'max:255'],
      'ciudad' => ['sometimes', 'required', 'string', 'max:255'],
      'estado_region' => ['sometimes', 'nullable', 'string', 'max:255'],
      'codigo_postal' => ['sometimes', 'nullable', 'string', 'max:20'],
      'codigo_iso_pais' => ['sometimes', 'required', 'string', Rule::in(CodigosIsoPaisEnum::cases())],
      'ubicacion' => ['sometimes', 'required', new LocationArray],
      'telefono' => ['sometimes', 'nullable', 'string', new PhoneNumberE164],
      'email' => ['sometimes', 'nullable', 'string', 'email', 'max:255'],
      'contacto_responsable' => ['sometimes', 'nullable', 'string', 'max:255'],
      'telefono_responsable' => ['sometimes', 'nullable', 'string', new PhoneNumberE164],
      'cadena' => ['sometimes', 'nullable', 'string', 'max:255'],
      'horario_atencion' => ['sometimes', 'nullable', 'string'],
      'delivery_24h' => ['sometimes', 'boolean'],
    ];
  }

  protected function prepareForValidation(): void
  {
    $ubicacionField = 'ubicacion';
    if ($this->has($ubicacionField)) {
      $ubicacion = PrepareData::location($this->input($ubicacionField));
      if (!is_null($ubicacion)) {
        $this->merge([$ubicacionField => $ubicacion]);
      }
    }
  }
}

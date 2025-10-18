<?php

namespace App\Http\Requests\User\Register;

use App\Enums\CodigosIsoPaisEnum;
use App\Rules\PhoneNumberE164;
use Arr;
use Illuminate\Validation\Rule;

class RegisterRepartidorUserRequest extends RegisterBaseUserRequest
{
  protected const REPARTIDOR_USER_FIELDS = [
    'codigo_iso_pais',
    'dni_id_numero',
    'telefono',
    'licencia_numero',
    'licencia_vencimiento',
    'vehiculo_placa',
    'vehiculo_marca',
    'vehiculo_modelo',
  ];

  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      // 'farmacia_id' => ['required', 'uuid', Rule::exists(Farmacia::class, 'id')],
      'codigo_iso_pais' => ['required', 'string', Rule::in(CodigosIsoPaisEnum::cases())],
      'dni_id_numero' => ['sometimes', 'nullable', 'string', 'max:20'],
      'telefono' => ['sometimes', 'nullable', new PhoneNumberE164],
      'licencia_numero' => ['sometimes', 'nullable', 'string', 'max:20'],
      'licencia_vencimiento' => ['sometimes', 'nullable', 'date', 'after:today'],
      'vehiculo_placa' => ['sometimes', 'nullable', 'string', 'max:255'],
      'vehiculo_marca' => ['sometimes', 'nullable', 'string', 'max:255'],
      'vehiculo_modelo' => ['sometimes', 'nullable', 'string', 'max:255'],
    ]);
  }

  public function getRepartidorUserData(): array
  {
    return Arr::only($this->validated(), self::REPARTIDOR_USER_FIELDS);
  }
}

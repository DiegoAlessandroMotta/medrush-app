<?php

namespace App\Http\Requests\User\Update;

use App\Enums\CodigosIsoPaisEnum;
use App\Models\Farmacia;
use App\Rules\PhoneNumberE164;
use Arr;
use Illuminate\Validation\Rule;

class UpdateRepartidorUserRequest extends UpdateBaseUserRequest
{
  protected const REPARTIDOR_FIELDS = [
    'farmacia_id',
    'codigo_iso_pais',
    'dni_id_numero',
    'telefono',
    'licencia_numero',
    'licencia_vencimiento',
    'vehiculo_placa',
    'vehiculo_marca',
    'vehiculo_modelo',
    'vehiculo_codigo_registro'
  ];

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'farmacia_id' => ['sometimes', 'required', 'uuid', Rule::exists(Farmacia::class, 'id')],
      'codigo_iso_pais' => ['sometimes', 'required', 'string', Rule::in(CodigosIsoPaisEnum::cases())],
      'dni_id_numero' => ['sometimes', 'nullable', 'string', 'max:20'],
      // 'dni_id_imagen' => ['sometimes', 'nullable', 'file', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
      'telefono' => ['sometimes', 'nullable', new PhoneNumberE164],
      'licencia_numero' => ['sometimes', 'nullable', 'string', 'max:20'],
      'licencia_vencimiento' => ['sometimes', 'nullable', 'date', 'after:today'],
      // 'licencia_imagen' => ['sometimes', 'nullable', 'file', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
      // 'seguro_vehiculo' => ['sometimes', 'nullable', 'file', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
      'vehiculo_placa' => ['sometimes', 'nullable', 'string', 'max:255'],
      'vehiculo_marca' => ['sometimes', 'nullable', 'string', 'max:255'],
      'vehiculo_modelo' => ['sometimes', 'nullable', 'string', 'max:255'],
      'vehiculo_codigo_registro' => ['sometimes', 'nullable', 'string', 'max:255'],
    ]);
  }

  public function getRepartidorData(): array
  {
    return Arr::only($this->validated(), self::REPARTIDOR_FIELDS);
  }
}

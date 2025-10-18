<?php

namespace App\Http\Requests\Pedido;

use App\Casts\AsPoint;
use App\Enums\TiposPedidoEnum;
use App\Helpers\OrderCodeGenerator;
use App\Models\Farmacia;
use App\Rules\LocationArray;
use App\Rules\PhoneNumberE164;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StorePedidoRequest extends FormRequest
{
  public const FARMACIA_ID_FIELD_KEY = 'farmacia_id';
  public const UBICACION_RECOJO_FIELD_KEY = 'ubicacion_recojo';

  private ?Farmacia $farmacia = null;

  public function rules(): array
  {
    return [
      self::FARMACIA_ID_FIELD_KEY => ['required', 'uuid'],
      'paciente_nombre' => ['required', 'string', 'max:255'],
      'paciente_telefono' => ['required', new PhoneNumberE164],
      'paciente_email' => ['sometimes', 'nullable', 'email', 'max:255'],
      'direccion_entrega_linea_1' => ['required', 'string', 'max:255'],
      'direccion_entrega_linea_2' => ['sometimes', 'nullable', 'string', 'max:255'],
      'ciudad_entrega' => ['required', 'string', 'max:255'],
      'estado_region_entrega' => ['sometimes', 'nullable', 'string', 'max:255'],
      'codigo_postal_entrega' => ['sometimes', 'nullable', 'string', 'max:20'],
      self::UBICACION_RECOJO_FIELD_KEY => ['sometimes', 'nullable', new LocationArray],
      'ubicacion_entrega' => ['sometimes', 'nullable', new LocationArray],
      'codigo_acceso_edificio' => ['sometimes', 'nullable', 'string', 'max:20'],
      'medicamentos' => ['sometimes', 'nullable', 'string', 'max:1000'],
      'tipo_pedido' => ['required', 'string', 'max:255'],
      'observaciones' => ['sometimes', 'nullable', 'string', 'max:1000'],
      'requiere_firma_especial' => ['sometimes', 'nullable', 'boolean'],
      'tiempo_entrega_estimado' => ['sometimes', 'nullable', 'integer', 'min:1'],
      'distancia_estimada' => ['sometimes', 'nullable', 'numeric', 'min:0'],
    ];
  }

  public function after(): array
  {
    return [
      function (Validator $validator) {
        if (!$validator->messages()->isEmpty()) {
          return;
        }

        $farmacia = $this->getFarmacia();

        if ($farmacia === null) {
          $validator->errors()
            ->add(self::FARMACIA_ID_FIELD_KEY, 'The selected farmacia id is invalid.');
          return;
        }

        if (!$this->has(self::UBICACION_RECOJO_FIELD_KEY)) {
          $this->merge([
            self::UBICACION_RECOJO_FIELD_KEY => AsPoint::serializeValue($farmacia->ubicacion)
          ]);
        }
      }
    ];
  }

  public function getFarmaciaId(): string
  {
    return $this->input(self::FARMACIA_ID_FIELD_KEY);
  }

  public function getFarmacia(): ?Farmacia
  {
    if ($this->farmacia === null) {
      $this->farmacia = Farmacia::find($this->getFarmaciaId());
    }

    return $this->farmacia;
  }
}

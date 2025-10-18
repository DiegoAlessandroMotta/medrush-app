<?php

namespace App\Http\Requests\Pedido;

use App\Enums\TiposPedidoEnum;
use App\Rules\LocationArray;
use App\Rules\PhoneNumberE164;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePedidoRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'paciente_nombre' => ['sometimes', 'required', 'string', 'max:255'],
      'paciente_telefono' => ['sometimes', 'required', new PhoneNumberE164],
      'paciente_email' => ['sometimes', 'nullable', 'email', 'max:255'],
      // 'codigo_iso_pais_entrega' => ['sometimes', 'required', 'string', 'size:3'],
      'direccion_entrega_linea_1' => ['sometimes', 'required', 'string', 'max:255'],
      'direccion_entrega_linea_2' => ['sometimes', 'nullable', 'string', 'max:255'],
      'ciudad_entrega' => ['sometimes', 'required', 'string', 'max:255'],
      'estado_region_entrega' => ['sometimes', 'nullable', 'string', 'max:255'],
      'codigo_postal_entrega' => ['sometimes', 'nullable', 'string', 'max:20'],
      'ubicacion_recojo' => ['sometimes', 'nullable', new LocationArray],
      'ubicacion_entrega' => ['sometimes', 'nullable', new LocationArray],
      'codigo_acceso_edificio' => ['sometimes', 'nullable', 'string', 'max:20'],
      'medicamentos' => ['sometimes', 'nullable', 'string', 'max:1000'],
      'tipo_pedido' => ['sometimes', 'required', 'string', 'max:255'],
      'observaciones' => ['sometimes', 'nullable', 'string', 'max:1000'],
      'requiere_firma_especial' => ['sometimes', 'boolean'],
      'tiempo_entrega_estimado' => ['sometimes', 'nullable', 'integer', 'min:1'],
      'distancia_estimada' => ['sometimes', 'nullable', 'numeric', 'min:0'],
    ];
  }
}

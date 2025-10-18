<?php

namespace App\Http\Requests\UbicacionRepartidor;

use App\Models\Pedido;
use App\Models\PerfilRepartidor;
use App\Rules\LocationArray;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUbicacionRepartidor extends FormRequest
{
  public function rules(): array
  {
    return [
      'pedido_id' => ['sometimes', 'required', 'uuid', Rule::exists(Pedido::class, 'id')],
      'repartidor_id' => ['required', 'uuid', Rule::exists(PerfilRepartidor::class, 'id')],
      'ubicacion' => ['required', new LocationArray],
      'precision_m' => ['sometimes', 'nullable', 'numeric', 'min:0'],
      'velocidad_ms' => ['sometimes', 'nullable', 'numeric', 'min:0'],
      'direccion' => ['sometimes', 'nullable', 'numeric', 'between:0,360'],
      'fecha_registro' => ['sometimes', 'datetime', Rule::date()->beforeOrEqual(now())],
    ];
  }

  public function hasPedidoId()
  {
    return $this->has('pedido_id');
  }

  public function getPedidoId()
  {
    return $this->input('pedido_id');
  }

  public function getRepartidorId()
  {
    return $this->input('repartidor_id');
  }
}

<?php

namespace App\Http\Requests\Ruta;

use App\Models\Pedido;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AddPedidoRutaRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'pedido_id' => ['required', 'uuid'],
    ];
  }

  public function getPedidoId(): string
  {
    return $this->input('pedido_id');
  }

  public function pedidoIdNotFound(): array
  {
    return [
      'pedido_id' => 'El pedido seleccionado no existe',
    ];
  }
}

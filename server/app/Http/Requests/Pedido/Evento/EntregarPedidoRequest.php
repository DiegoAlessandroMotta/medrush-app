<?php

namespace App\Http\Requests\Pedido\Evento;

use App\Helpers\PrepareData;
use App\Rules\LocationArray;
use Arr;
use Illuminate\Foundation\Http\FormRequest;

class EntregarPedidoRequest extends FormRequest
{
  protected const PEDIDO_FIELDS = [
    'firma_digital',
    'firma_documento_consentimiento',
  ];

  public function rules(): array
  {
    return [
      'ubicacion' => ['required', new LocationArray],
      'foto_entrega' => ['sometimes', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
      'firma_digital' => ['sometimes', 'string', 'max:65535'], // svg
      'firma_documento_consentimiento' => ['sometimes', 'string', 'max:65535'], // svg
    ];
  }

  public function getUbicacion(): ?array
  {
    return PrepareData::location($this->input('ubicacion'));
  }

  public function getPedidoData(): array
  {
    return Arr::only($this->validated(), self::PEDIDO_FIELDS);
  }
}

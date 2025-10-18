<?php

namespace App\Http\Requests\Api;

use App\Helpers\PrepareData;
use App\Rules\LocationArray;
use Illuminate\Foundation\Http\FormRequest;

class ReverseGeocodeRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'ubicacion' => ['required', new LocationArray],
    ];
  }

  /**
   * @return array{latitude: float, longitude: float}
   */
  public function getUbicacion(): array
  {
    return PrepareData::location($this->validated('ubicacion'));
  }
}

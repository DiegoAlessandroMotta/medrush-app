<?php

namespace App\Http\Requests\User\UploadFiles;

use Illuminate\Foundation\Http\FormRequest;

class UploadFotoSeguroVehiculoRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'foto_seguro_vehiculo' => ['sometimes', 'nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
    ];
  }
}

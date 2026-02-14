<?php

namespace App\Http\Requests\User\UploadFiles;

use Illuminate\Foundation\Http\FormRequest;

class UploadFotoLicenciaRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'foto_licencia' => ['sometimes', 'nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
    ];
  }
}

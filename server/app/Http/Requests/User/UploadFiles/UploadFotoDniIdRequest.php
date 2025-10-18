<?php

namespace App\Http\Requests\User\UploadFiles;

use Illuminate\Foundation\Http\FormRequest;

class UploadFotoDniIdRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'foto_dni_id' => ['required', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
    ];
  }
}

<?php

namespace App\Http\Requests\User\Update;

use Illuminate\Foundation\Http\FormRequest;

class UploadProfilePictureRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'avatar' => ['nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:5120'],
    ];
  }


  public function messages(): array
  {
    return [
      'avatar.image' => 'El archivo subido debe ser una imagen válida.',
      'avatar.mimes' => 'El formato de imagen debe ser JPEG, PNG, JPG o WEBP.',
      'avatar.max' => 'La imagen de perfil no debe superar los 5 MB.',
    ];
  }
}

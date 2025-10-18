<?php

namespace App\Http\Requests;

use App\Models\Farmacia;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UploadCsvFileRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'pedidos_csv' => ['required', 'file', 'mimes:csv,txt', 'max:10240'],
      'farmacia_id' => ['required', 'uuid', Rule::exists(Farmacia::class, 'id')]
    ];
  }

  public function messages(): array
  {
    return [
      'pedidos_csv.required' => 'Debes seleccionar un archivo CSV.',
      'pedidos_csv.file' => 'El archivo subido no es válido.',
      'pedidos_csv.mimes' => 'El archivo debe ser de tipo CSV.',
      'pedidos_csv.max' => 'El archivo CSV no debe exceder los 10 MB.',
    ];
  }

  public function hasFarmaciaId(): bool
  {
    return $this->has('farmacia_id');
  }

  public function getFarmaciaId(): ?string
  {
    return $this->input('farmacia_id');
  }
}

<?php

namespace App\Http\Requests;

use App\Enums\CodigosIsoPaisEnum;
use App\Models\Farmacia;
use App\Rules\LocationArray;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UploadCsvFileRequest extends FormRequest
{
  private ?Farmacia $farmacia = null;

  public function rules(): array
  {
    return [
      'pedidos_csv' => ['required', 'file', 'mimes:csv,txt', 'max:10240'],
      'farmacia_id' => ['sometimes', 'nullable', 'uuid'],
      'codigo_iso_pais_entrega' => [Rule::requiredIf(fn() => $this->getFarmaciaId() === null), 'string', Rule::enum(CodigosIsoPaisEnum::class)],
      'ubicacion_recojo' => [Rule::requiredIf(fn() => $this->getFarmaciaId() === null), new LocationArray],
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

  public function after(): array
  {
    return [
      function (Validator $validator) {
        if (!$validator->messages()->isEmpty()) {
          return;
        }

        $farmacia = $this->getFarmacia();
        $farmaciaId = $this->getFarmaciaId();

        if ($farmacia === null && $farmaciaId !== null) {
          $validator->errors()
            ->add('farmacia_id', 'The selected farmacia id is invalid.');
          return;
        }
      }
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

  public function getCodigoIsoPaisEntrega(): ?string
  {
    return $this->input('codigo_iso_pais_entrega');
  }

  public function getUbicacionRecojo(): ?array
  {
    return $this->input('ubicacion_recojo');
  }

  public function getFarmacia(): ?Farmacia
  {
    $farmaciaId = $this->getFarmaciaId();
    if ($this->farmacia === null && $farmaciaId !== null) {
      $this->farmacia = Farmacia::find($farmaciaId);
    }

    return $this->farmacia;
  }
}

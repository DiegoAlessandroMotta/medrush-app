<?php

namespace App\Http\Requests\Farmacia;

use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosFarmaciaEnum;
use App\Helpers\ArrayHelper;
use App\Http\Requests\BasePaginationRequest;
use Illuminate\Validation\Rule;

class IndexFarmaciaRequest extends BasePaginationRequest
{
  public const ORDER_BY_FIELDS = [
    'created_at',
    'updated_at',
    'nombre',
    'razon_social',
    'ciudad',
    'estado_region',
    'cadena',
    'estado',
  ];

  private ?array $estadoFilter = null;
  private ?array $codigoIsoPaisFilter = null;
  private ?array $codigoPostalFilter = null;

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'ciudad' => ['sometimes', 'string'],
      'estado_region' => ['sometimes', 'string'],
      'codigo_postal' => ['sometimes', 'string'],
      'codigo_iso_pais' => ['sometimes', 'string'],
      'cadena' => ['sometimes', 'string'],
      'delivery_24h' => ['sometimes', 'nullable', 'boolean'],
      'estado' => ['sometimes', 'string'],
      'order_by' => ['sometimes', 'string', Rule::in(self::ORDER_BY_FIELDS)],
    ]);
  }

  protected function prepareForValidation(): void
  {
    parent::prepareForValidation();

    $this->replaceNullString('estado');
    $this->replaceNullString('codigo_iso_pais');
    $this->replaceNullString('codigo_postal');
    $this->preprocessBooleanField('delivery_24h');
  }

  public function passedValidation(): void
  {
    $estadoInput = $this->input('estado');
    if ($estadoInput !== null) {
      $this->estadoFilter = ArrayHelper::filterStringArrayByBackedEnum($estadoInput, EstadosFarmaciaEnum::class);
      $this->merge(['estado' => $this->estadoFilter]);
    }

    $codigoIsoPaisInput = $this->input('codigo_iso_pais');
    if ($codigoIsoPaisInput !== null) {
      $this->codigoIsoPaisFilter = ArrayHelper::filterStringArrayByBackedEnum($codigoIsoPaisInput, CodigosIsoPaisEnum::class);
      $this->merge(['codigo_iso_pais' => $this->codigoIsoPaisFilter]);
    }

    if ($this->hasCodigoPostal()) {
      $values = ArrayHelper::arrayFromString($this->input('codigo_postal'));
      $this->codigoPostalFilter = empty($values) ? null : $values;
      $this->merge(['codigo_postal' => $this->codigoPostalFilter]);
    }
  }

  public function getCiudad(): ?string
  {
    return $this->input('ciudad');
  }

  public function getEstadoRegion(): ?string
  {
    return $this->input('estado_region');
  }

  public function hasCodigoPostal(): bool
  {
    return $this->has('codigo_postal');
  }

  public function getCodigoPostalFilter(): ?array
  {
    return $this->codigoPostalFilter;
  }

  public function getCodigoIsoPaisFilter(): ?array
  {
    return $this->codigoIsoPaisFilter;
  }

  public function getCadena(): ?string
  {
    return $this->input('cadena');
  }

  public function hasDelivery24h(): bool
  {
    return $this->has('delivery_24h');
  }

  public function getDelivery24h(): ?bool
  {
    return $this->input('delivery_24h');
  }

  public function getEstadoFilter(): ?array
  {
    return $this->estadoFilter;
  }
}

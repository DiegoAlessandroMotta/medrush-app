<?php

namespace App\Http\Requests\User\List;

use App\Enums\CodigosIsoPaisEnum;
use App\Enums\EstadosRepartidorEnum;
use App\Helpers\ArrayHelper;
use Illuminate\Validation\Rule;

class IndexRepartidorUserRequest extends IndexBaseUserRequest
{
  public const REPARTIDOR_TABLE = 'perfiles_repartidor';
  public const ORDER_BY_FIELDS = [
    'codigo_iso_pais',
    'licencia_vencimiento',
    'estado',
    'verificado',
  ];

  private ?string $orderBy = null;
  private ?array $estadoFilter = null;
  private ?array $codigoIsoPaisFilter = null;

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'codigo_iso_pais' => ['sometimes', 'string'],
      'estado' => ['sometimes', 'nullable', 'string'],
      'verificado' => ['sometimes', 'nullable', 'boolean'],
      'order_by' => ['sometimes', 'string', Rule::in(array_merge(self::ORDER_BY_FIELDS, parent::ORDER_BY_FIELDS))],
    ]);
  }

  protected function prepareForValidation(): void
  {
    parent::prepareForValidation();

    $this->preprocessBooleanField('verificado');
  }

  public function passedValidation(): void
  {
    $this->computeOrderBy();

    $estadoInput = $this->input('estado');
    if ($estadoInput !== null) {
      $this->estadoFilter = ArrayHelper::filterStringArrayByBackedEnum($estadoInput, EstadosRepartidorEnum::class);
      $this->merge(['estado' => $this->estadoFilter]);
    }

    $codigoIsoPaisInput = $this->input('codigo_iso_pais');
    if ($codigoIsoPaisInput !== null) {
      $this->codigoIsoPaisFilter = ArrayHelper::filterStringArrayByBackedEnum($codigoIsoPaisInput, CodigosIsoPaisEnum::class);
      $this->merge(['codigo_iso_pais' => $this->codigoIsoPaisFilter]);
    }
  }

  private function computeOrderBy(): void
  {
    $orderBy = $this->getRawOrderBy();
    $prefix = self::REPARTIDOR_TABLE;

    if (in_array($orderBy, parent::ORDER_BY_FIELDS)) {
      $prefix = parent::USER_TABLE;
    }

    $this->orderBy = $prefix . '.' . $orderBy;
  }

  public function getOrderBy(): string
  {
    return $this->orderBy;
  }

  public function getCodigoIsoPaisFilter(): ?array
  {
    return $this->codigoIsoPaisFilter;
  }

  public function getEstadoFilter(): ?array
  {
    return $this->estadoFilter;
  }

  public function getVerificado(): ?bool
  {
    return $this->input('verificado');
  }
}

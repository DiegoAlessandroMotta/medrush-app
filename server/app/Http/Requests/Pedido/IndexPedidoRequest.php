<?php

namespace App\Http\Requests\Pedido;

use App\Enums\EstadosPedidoEnum;
use App\Helpers\ArrayHelper;
use App\Http\Requests\BasePaginationRequest;
use Illuminate\Validation\Rule;

class IndexPedidoRequest extends BasePaginationRequest
{
  protected int $maxPerPage = 100;

  public const ORDER_BY_FIELDS = [
    'created_at',
    'updated_at',
    'tipo_pedido',
    'estado',
    'fecha_asignacion',
    'fecha_recogida',
    'fecha_entrega',
    'tiempo_entrega_estimado',
    'distancia_estimada',
  ];

  private ?array $estadoFilter = null;

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'estado' => ['sometimes', 'string'],
      'estados' => ['sometimes', 'string'],
      'order_by' => ['sometimes', 'string', Rule::in(self::ORDER_BY_FIELDS)],
      'repartidor_id' => ['sometimes', 'nullable', 'uuid'],
      'farmacia_id' => ['sometimes', 'nullable', 'uuid'],
    ]);
  }

  protected function prepareForValidation(): void
  {
    parent::prepareForValidation();

    $this->replaceNullString('estado');
    $this->replaceNullString('repartidor_id');
    $this->replaceNullString('farmacia_id');
  }

  public function passedValidation(): void
  {
    $estadoInput = $this->input('estados') ?? $this->input('estado');
    if ($estadoInput !== null && is_string($estadoInput)) {
      $this->estadoFilter = ArrayHelper::filterStringArrayByBackedEnum($estadoInput, EstadosPedidoEnum::class);
      $this->merge(['estado' => $this->estadoFilter]);
    }
  }

  public function getEstadoFilter(): ?array
  {
    return $this->estadoFilter;
  }

  public function hasRepartidorId(): bool
  {
    return $this->has('repartidor_id');
  }

  public function getRepartidorId(): ?string
  {
    return $this->input('repartidor_id');
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

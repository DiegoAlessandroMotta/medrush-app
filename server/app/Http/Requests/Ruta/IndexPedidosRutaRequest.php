<?php

namespace App\Http\Requests\Ruta;

use App\Enums\EstadosPedidoEnum;
use App\Helpers\PrepareData;
use App\Http\Requests\BasePaginationRequest;
use Illuminate\Validation\Rule;

class IndexPedidosRutaRequest extends BasePaginationRequest
{
  protected string $defaultOrderBy = 'orden_personalizado';
  protected string $defaultOrderDirection = 'asc';

  public const ORDER_BY_FIELDS = [
    'tipo_pedido',
    'estado',
    'updated_at',
    'orden_optimizado',
    'orden_personalizado',
    'orden_recojo',
  ];

  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'estado' => ['sometimes', 'string', Rule::in(EstadosPedidoEnum::cases())],
      'order_by' => ['sometimes', 'string', Rule::in(self::ORDER_BY_FIELDS)],
      'optimizado' => ['sometimes', 'boolean'],
    ]);
  }

  protected function prepareForValidation(): void
  {
    parent::prepareForValidation();

    $optimizadoKey = 'optimizado';
    if ($this->has($optimizadoKey)) {
      $optimizado = PrepareData::boolean($this->input($optimizadoKey));
      if (!is_null($optimizado)) {
        $this->merge([$optimizadoKey => $optimizado]);
      }
    }
  }

  public function getEstado(): ?string
  {
    return $this->input('estado');
  }

  public function getOptimizado(): ?string
  {
    return $this->input('optimizado');
  }

  public function getRawOrderBy(): string
  {
    return $this->input('order_by');
  }

  public function getOrderBy(): string
  {
    $orderBy = $this->getRawOrderBy();
    $prefix = 'entregas_pedido';

    if (in_array($orderBy, ['tipo_pedido', 'estado'])) {
      $prefix = 'pedidos';
    }

    return $prefix . '.' . $orderBy;
  }
}

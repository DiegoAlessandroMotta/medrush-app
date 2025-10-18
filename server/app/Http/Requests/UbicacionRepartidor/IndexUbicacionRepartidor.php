<?php

namespace App\Http\Requests\UbicacionRepartidor;

use Carbon\Carbon;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class IndexUbicacionRepartidor extends FormRequest
{
  private int $defaultLimit = 100;
  private int $maxLimit = 500;
  private int $minLimit = 1;
  private int $defaultInterval = 60;
  private int $maxDateRangeInDays = 90;
  private string $defaultOrderDirection = 'asc';
  private string $defaultOrderBy = 'fecha_registro';
  private string $tieBreakerOrderByField = 'id';

  private const ORDER_DIRECTIONS = ['asc', 'desc'];
  private const ALLOWED_INTERVALS = [30, 60, 120, 300, 600, 900, 1800];
  private const ORDER_BY_FIELDS = [
    'created_at',
    'fecha_registro',
  ];

  public function rules(): array
  {
    return [
      'limit' => ['sometimes', 'integer', 'min:' . $this->minLimit, 'max:' . $this->maxLimit],
      'interval' => ['sometimes', 'integer', Rule::in(self::ALLOWED_INTERVALS)],
      'cursor' => ['sometimes', 'string'],
      'order_direction' => ['sometimes', 'string', Rule::in(self::ORDER_DIRECTIONS)],
      'order_by' => ['sometimes', 'string', Rule::in(self::ORDER_BY_FIELDS)],
      'start_ts' => ['sometimes', 'date'],
      'end_ts' => ['sometimes', 'date'],
      'repartidor_id' => ['sometimes', 'uuid'],
      'pedido_id' => ['sometimes', 'uuid'],
      'ruta_id' => ['sometimes', 'uuid'],
    ];
  }

  protected function prepareForValidation(): void
  {
    $limit = $this->input('limit', $this->defaultLimit);
    if ($limit > $this->maxLimit) {
      $limit = $this->maxLimit;
    } elseif ($limit < $this->minLimit) {
      $limit = $this->minLimit;
    }

    $this->merge([
      'limit' => $limit,
      'interval' => $this->input('interval', $this->defaultInterval),
      'order_direction' => $this->input('order_direction', $this->defaultOrderDirection),
      'order_by' => $this->input('order_by', $this->defaultOrderBy)
    ]);
  }

  public function after(): array
  {
    return [
      function (Validator $validator) {
        if (!$validator->messages()->isEmpty()) {
          return;
        }

        if (!$this->hasEntityFilter()) {
          $validator->errors()
            ->add('repartidor_id', 'Debe especificar al menos un filtro de entidad (repartidor_id, pedido_id o ruta_id).');
        }

        $hasAfterTs = $this->getStartTimestamp() !== null;
        $hasBeforeTs = $this->getEndTimestamp() !== null;
        if ($hasAfterTs && $hasBeforeTs) {
          $after = Carbon::parse($this->getStartTimestamp());
          $before = Carbon::parse($this->getEndTimestamp());

          if ($after->isAfter($before)) {
            $validator->errors()
              ->add('before_ts', 'La fecha final (before_ts) no puede ser anterior a la fecha inicial (after_ts).');
          }

          if ($after->diffInDays($before) > $this->maxDateRangeInDays) {
            $validator->errors()
              ->add('date_range', "El rango máximo permitido entre 'after_ts' y 'before_ts' es de {$this->maxDateRangeInDays} días.");
          }
        }
      }
    ];
  }

  public function getLimit(): int
  {
    return (int) $this->input('limit');
  }

  public function getInterval(): int
  {
    return (int) $this->input('interval');
  }

  public function getDecodedCursor(): ?array
  {
    $cursor = $this->input('cursor');

    if ($cursor == null) {
      return null;
    }

    return json_decode(base64_decode($cursor), true);
  }

  public function getStartTimestamp(): ?string
  {
    return $this->input('start_ts');
  }

  public function getEndTimestamp(): ?string
  {
    return $this->input('end_ts');
  }

  public function getOrderDirection(): string
  {
    return $this->input('order_direction');
  }

  public function getOrderBy(): string
  {
    return $this->input('order_by');
  }

  public function getTieBreakerOrderByField(): string
  {
    return $this->tieBreakerOrderByField;
  }

  public function getRepartidorId(): ?string
  {
    return $this->input('repartidor_id');
  }

  public function getPedidoId(): ?string
  {
    return $this->input('pedido_id');
  }

  public function getRutaId(): ?string
  {
    return $this->input('ruta_id');
  }

  public function hasEntityFilter(): bool
  {
    return $this->getRepartidorId() != null
      || $this->getPedidoId() != null
      || $this->getRutaId() != null;
  }
}

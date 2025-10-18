<?php

namespace App\Http\Requests\Ruta;

use App\Http\Requests\BasePaginationRequest;

class IndexRutaRequest extends BasePaginationRequest
{
  // protected int $maxPerPage = 100;

  public const ORDER_BY_FIELDS = [
    'created_at',
    'updated_at',
    'nombre',
    'distancia_total_estimada',
    'tiempo_total_estimado',
    'fecha_hora_calculo',
    'fecha_inicio',
    'fecha_completado',
  ];

  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return array_merge(parent::rules(), [
      'repartidor_id' => ['sometimes', 'nullable', 'uuid'],
    ]);
  }

  public function hasRepartidorId(): bool
  {
    return $this->has('repartidor_id');
  }

  public function getRepartidorId(): ?string
  {
    return $this->input('repartidor_id');
  }
}

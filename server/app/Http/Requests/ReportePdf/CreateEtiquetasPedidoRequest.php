<?php

namespace App\Http\Requests\ReportePdf;

use App\Models\Pedido;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class CreateEtiquetasPedidoRequest extends FormRequest
{
  public function rules(): array
  {
    return [
      'pedidos' => [
        'required',
        'array',
        'min:1',
        'max:500',
      ],
      'pedidos.*' => [
        'required',
        'string',
        'uuid',
      ],
    ];
  }

  public function messages(): array
  {
    return [
      'pedidos.required' => 'Debe proporcionar al menos un pedido.',
      'pedidos.array' => 'Los pedidos deben ser un array.',
      'pedidos.min' => 'Debe seleccionar al menos un pedido.',
      'pedidos.max' => 'No puede seleccionar más de 500 pedidos a la vez.',
      'pedidos.*.required' => 'Cada pedido debe tener un ID válido.',
      'pedidos.*.string' => 'El ID del pedido debe ser una cadena de texto.',
      'pedidos.*.uuid' => 'El ID del pedido debe ser un UUID válido.',
    ];
  }

  public function after(): array
  {
    return [
      function (Validator $validator) {
        if (!$validator->messages()->isEmpty()) {
          return;
        }

        $this->validateDuplicatesAndExistence($validator);
      }
    ];
  }

  protected function validateDuplicatesAndExistence(Validator $validator): void
  {
    $pedidosIds = $this->input('pedidos', []);

    if (empty($pedidosIds)) {
      return;
    }

    $uniquePedidosIds = array_unique($pedidosIds);
    $duplicatesCount = count($pedidosIds) - count($uniquePedidosIds);

    if ($duplicatesCount > 0) {
      $duplicateIds = array_diff_assoc($pedidosIds, $uniquePedidosIds);
      $duplicateIds = array_unique($duplicateIds);

      if ($duplicatesCount === 1) {
        $validator->errors()->add(
          'pedidos',
          "Se detectó 1 pedido duplicado. Los pedidos deben ser únicos."
        );
      } else {
        $validator->errors()->add(
          'pedidos',
          "Se detectaron {$duplicatesCount} pedidos duplicados. Los pedidos deben ser únicos."
        );
      }
    }

    $existingPedidosIds = Pedido::whereIn('id', $uniquePedidosIds)
      ->select('id')
      ->pluck('id')
      ->toArray();

    $missingPedidosIds = array_diff($uniquePedidosIds, $existingPedidosIds);

    if (!empty($missingPedidosIds)) {
      $missingCount = count($missingPedidosIds);

      $firstFewMissing = array_slice($missingPedidosIds, 0, 3);
      $displayIds = implode(', ', $firstFewMissing);

      if ($missingCount > 3) {
        $remaining = $missingCount - 3;
        $displayIds .= " y {$remaining} más";
      }

      $validator->errors()->add(
        'pedidos',
        "Los siguientes pedidos no existen: {$displayIds}."
      );
    }
  }

  public function getValidatedPedidosIds(): array
  {
    return $this->validated('pedidos', []);
  }

  public function getUniquePedidosIds(): array
  {
    $pedidosIds = $this->validated('pedidos', []);
    return array_values(array_unique($pedidosIds));
  }

  public function getDuplicatesInfo(): array
  {
    $pedidosIds = $this->input('pedidos', []);
    $uniqueIds = array_unique($pedidosIds);

    return [
      'has_duplicates' => count($pedidosIds) !== count($uniqueIds),
      'total_count' => count($pedidosIds),
      'unique_count' => count($uniqueIds),
      'duplicates_count' => count($pedidosIds) - count($uniqueIds),
    ];
  }
}

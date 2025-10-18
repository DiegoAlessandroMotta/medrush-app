<?php

namespace App\Http\Requests\Ruta;

use App\Models\EntregaPedido;
use App\Models\Ruta;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Collection;
use Illuminate\Validation\Validator;

class ReorderPedidosRutaRequest extends FormRequest
{
  public const UPDATES_FIELD_KEY = 'cambios';
  public const PEDIDO_ID_FIELD_KEY = 'pedido_id';
  public const NEW_ORDER_FIELD_KEY = 'orden_personalizado';

  /** @var Collection<int, EntregaPedido>|null */
  private ?Collection $existingEntregas = null;

  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      self::UPDATES_FIELD_KEY => ['required', 'array', 'min:1'],
      self::UPDATES_FIELD_KEY . '.*.' . self::PEDIDO_ID_FIELD_KEY => ['required', 'uuid'],
      self::UPDATES_FIELD_KEY . '.*.' . self::NEW_ORDER_FIELD_KEY => ['required', 'integer', 'min:1'],
    ];
  }

  public function after(): array
  {
    return [
      function (Validator $validator) {
        if (!$validator->messages()->isEmpty()) {
          return;
        }

        $clientUpdates = collect($this->validated(self::UPDATES_FIELD_KEY));
        $clientPedidoIds = $clientUpdates->pluck(self::PEDIDO_ID_FIELD_KEY);

        if ($clientPedidoIds->count() !== $clientPedidoIds->unique()->count()) {
          $duplicates = $clientPedidoIds->duplicates()->unique();
          $validator->errors()
            ->add(self::UPDATES_FIELD_KEY, 'El mismo pedido_id ha sido especificado para actualización múltiples veces: ' . $duplicates->implode(', '));
          return;
        }

        $existingEntregas = $this->getExistingEntregas();
        $existingPedidoIds = $existingEntregas->pluck('pedido_id')->unique();

        $totalPedidosEnRuta = $existingEntregas->count();
        if ($totalPedidosEnRuta === 0) {
          if ($clientUpdates->isNotEmpty()) {
            $validator->errors()
              ->add(self::UPDATES_FIELD_KEY, 'Esta ruta no contiene pedidos. No se pueden aplicar actualizaciones.');
          }
          return;
        }

        $pedidosNoPertenecenARuta = $clientPedidoIds->diff($existingPedidoIds);
        if ($pedidosNoPertenecenARuta->isNotEmpty()) {
          $validator->errors()
            ->add(self::UPDATES_FIELD_KEY, 'Los siguientes pedidos no pertenecen a esta ruta: ' . $pedidosNoPertenecenARuta->implode(', '));
          return;
        }

        $pedidosNoPertenecenARuta = $clientPedidoIds->diff($existingPedidoIds);
        if ($pedidosNoPertenecenARuta->isNotEmpty()) {
          $validator->errors()
            ->add(self::UPDATES_FIELD_KEY, 'Los siguientes pedidos no pertenecen a esta ruta: ' . $pedidosNoPertenecenARuta->implode(', '));
          return;
        }

        $maxNewOrderRequested = $clientUpdates->max(self::NEW_ORDER_FIELD_KEY);
        if ($maxNewOrderRequested > $totalPedidosEnRuta) {
          $validator->errors()
            ->add(self::UPDATES_FIELD_KEY, 'Una o más nuevas posiciones exceden el número total de pedidos en la ruta (' . $totalPedidosEnRuta . ').');
          return;
        }
      }
    ];
  }

  /**
   * @return Collection<string, array{pedido_id: string, orden_personalizado: int}>
   */
  public function getClientUpdatesMapped(): Collection
  {
    return collect($this->validated(self::UPDATES_FIELD_KEY))->keyBy(self::PEDIDO_ID_FIELD_KEY);
  }

  /**
   * @return Collection<int, EntregaPedido>
   */
  public function getExistingEntregas(): Collection
  {
    if ($this->existingEntregas === null) {
      /** @var Ruta $ruta */
      $ruta = $this->ruta;
      $this->existingEntregas = $ruta->entregasPedido()->orderBy(self::NEW_ORDER_FIELD_KEY, 'asc')->get();
    }

    return $this->existingEntregas;
  }

  public function hasPedidosInRoute(): bool
  {
    return $this->getExistingEntregas()->isNotEmpty();
  }

  public function getTotalPedidosInRoute(): int
  {
    return $this->getExistingEntregas()->count();
  }
}

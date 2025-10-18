<?php

namespace App\Helpers;

use App\DTOs\Helpers\CalculatedOrderItemDto;
use Illuminate\Support\Collection;

class CollectionOrderManager
{
  /**
   * Calcula los nuevos órdenes para una colección de elementos.
   *
   * @param Collection<TKey, TItem> $collection La colección de elementos a reordenar.
   * @param array<string|int, int> $changesMap Un mapa de itemId => newOrder para asignaciones explícitas.
   * @param callable(TItem): (string|int) $getIdCallback Un callback para obtener el ID único de cada elemento.
   * @param int $baseOrder El orden inicial a partir del cual se asignarán los órdenes libres.
   * @return Collection<int, CalculatedOrderItem> Una colección de objetos CalculatedOrderItem.
   * @throws \RuntimeException
   */
  public static function calculateNewOrders(
    Collection $collection,
    array $changesMap,
    callable $getIdCallback,
    int $baseOrder = 1
  ): Collection {
    if ($collection->isEmpty()) {
      return new Collection();
    }

    $totalItems = $collection->count();
    $maxPossibleOrder = $baseOrder + $totalItems - 1;

    $explicitlyAssignedOrdersSet = [];
    foreach ($changesMap as $itemId => $newOrder) {
      if (isset($explicitlyAssignedOrdersSet[$newOrder])) {
        throw new \RuntimeException(
          "Un orden duplicado ({$newOrder}) fue asignado explícitamente a múltiples elementos."
        );
      }
      $explicitlyAssignedOrdersSet[$newOrder] = true;
    }

    $explicitlyAssignedOrderValues = array_keys($explicitlyAssignedOrdersSet);
    $allPossibleOrders = range($baseOrder, $maxPossibleOrder);

    $freeOrders = [];
    $explicitlyAssignedMap = array_flip($explicitlyAssignedOrderValues);

    foreach ($allPossibleOrders as $order) {
      if (!isset($explicitlyAssignedMap[$order])) {
        $freeOrders[] = $order;
      }
    }

    $freeOrders = array_values($freeOrders);

    $resultCollection = $collection->map(function ($item) use (
      $changesMap,
      &$freeOrders,
      $getIdCallback,
    ) {
      $itemId = $getIdCallback($item);
      $newOrder = null;

      if (array_key_exists($itemId, $changesMap)) {
        $newOrder = $changesMap[$itemId];
      } else {
        if (!empty($freeOrders)) {
          $newOrder = array_shift($freeOrders);
        } else {
          throw new \RuntimeException("No hay órdenes libres suficientes para asignar a todos los elementos.");
        }
      }

      return new CalculatedOrderItemDto(
        id: $itemId,
        newOrder: $newOrder
      );
    });

    $calculatedOrders = $resultCollection->pluck('newOrder');
    if ($calculatedOrders->count() !== $calculatedOrders->unique()->count()) {
      $duplicates = $calculatedOrders->duplicates();
      throw new \RuntimeException(
        "Se detectaron órdenes calculados duplicados: " . $duplicates->implode(', ') . ". "
      );
    }

    return $resultCollection->sortBy('newOrder')->values();
  }
}

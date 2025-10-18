<?php

namespace Tests\Unit\Helpers;

use App\Helpers\CollectionOrderManager;
use Illuminate\Support\Collection;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

class CollectionOrderManagerTest extends TestCase
{
  private function createTestItem(
    int|string $id,
    int $order
  ): object {
    return (object) ['id' => $id, 'order' => $order];
  }

  #[Test]
  public function it_returns_empty_collection_for_empty_input(): void
  {
    $collection = new Collection();
    $changesMap = ['some-id' => 1];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertTrue($newCollection->isEmpty());
  }

  #[Test]
  public function it_calculates_orders_correctly_when_no_changes(): void
  {
    $item1 = $this->createTestItem('id-1', 1);
    $item2 = $this->createTestItem('id-2', 2);
    $item3 = $this->createTestItem('id-3', 3);

    $collection = Collection::make([$item1, $item2, $item3]);
    $changesMap = [];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(3, $newCollection);
    $this->assertEquals('id-1', $newCollection->get(0)->id);
    $this->assertEquals(1, $newCollection->get(0)->newOrder);
    $this->assertEquals('id-2', $newCollection->get(1)->id);
    $this->assertEquals(2, $newCollection->get(1)->newOrder);
    $this->assertEquals('id-3', $newCollection->get(2)->id);
    $this->assertEquals(3, $newCollection->get(2)->newOrder);
  }

  #[Test]
  public function it_calculates_orders_correctly_with_one_change(): void
  {
    $item1 = $this->createTestItem('id-1', 1);
    $item2 = $this->createTestItem('id-2', 2);
    $item3 = $this->createTestItem('id-3', 3);
    $item4 = $this->createTestItem('id-4', 4);

    $collection = Collection::make([$item1, $item2, $item3, $item4]);
    $changesMap = ['id-3' => 1];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(4, $newCollection);
    $this->assertEquals('id-3', $newCollection->get(0)->id);
    $this->assertEquals(1, $newCollection->get(0)->newOrder);
    $this->assertEquals('id-1', $newCollection->get(1)->id);
    $this->assertEquals(2, $newCollection->get(1)->newOrder);
    $this->assertEquals('id-2', $newCollection->get(2)->id);
    $this->assertEquals(3, $newCollection->get(2)->newOrder);
    $this->assertEquals('id-4', $newCollection->get(3)->id);
    $this->assertEquals(4, $newCollection->get(3)->newOrder);
  }

  #[Test]
  public function it_calculates_orders_correctly_with_multiple_changes(): void
  {
    $item1 = $this->createTestItem('id-1', 1);
    $item2 = $this->createTestItem('id-2', 2);
    $item3 = $this->createTestItem('id-3', 3);
    $item4 = $this->createTestItem('id-4', 4);

    $collection = Collection::make([$item1, $item2, $item3, $item4]);
    $changesMap = [
      'id-4' => 1,
      'id-1' => 4,
    ];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(4, $newCollection);
    $this->assertEquals('id-4', $newCollection->get(0)->id);
    $this->assertEquals(1, $newCollection->get(0)->newOrder);
    $this->assertEquals('id-2', $newCollection->get(1)->id);
    $this->assertEquals(2, $newCollection->get(1)->newOrder);
    $this->assertEquals('id-3', $newCollection->get(2)->id);
    $this->assertEquals(3, $newCollection->get(2)->newOrder);
    $this->assertEquals('id-1', $newCollection->get(3)->id);
    $this->assertEquals(4, $newCollection->get(3)->newOrder);
  }

  #[Test]
  public function it_handles_base_order_correctly(): void
  {
    $itemA = $this->createTestItem('item-A', 5);
    $itemB = $this->createTestItem('item-B', 6);

    $collection = Collection::make([$itemA, $itemB]);
    $changesMap = [];
    $baseOrder = 10;

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
      $baseOrder,
    );

    $this->assertCount(2, $newCollection);
    $this->assertEquals('item-A', $newCollection->get(0)->id);
    $this->assertEquals(10, $newCollection->get(0)->newOrder);
    $this->assertEquals('item-B', $newCollection->get(1)->id);
    $this->assertEquals(11, $newCollection->get(1)->newOrder);
  }

  #[Test]
  public function it_assigns_explicit_orders_and_uses_free_orders_for_others(): void
  {
    $itemA = $this->createTestItem('A', 1);
    $itemB = $this->createTestItem('B', 2);
    $itemC = $this->createTestItem('C', 3);
    $itemD = $this->createTestItem('D', 4);

    $collection = Collection::make([$itemA, $itemB, $itemC, $itemD]);
    $changesMap = [
      'A' => 4,
      'C' => 1,
    ];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(4, $newCollection);
    $this->assertEquals('C', $newCollection->get(0)->id);
    $this->assertEquals(1, $newCollection->get(0)->newOrder);

    $this->assertEquals('B', $newCollection->get(1)->id);
    $this->assertEquals(2, $newCollection->get(1)->newOrder);

    $this->assertEquals('D', $newCollection->get(2)->id);
    $this->assertEquals(3, $newCollection->get(2)->newOrder);

    $this->assertEquals('A', $newCollection->get(3)->id);
    $this->assertEquals(4, $newCollection->get(3)->newOrder);
  }

  #[Test]
  public function it_throws_exception_if_not_enough_free_orders(): void
  {
    $item1 = $this->createTestItem('id-1', 1);
    $item2 = $this->createTestItem('id-2', 2);

    $collection = Collection::make([$item1, $item2]);
    $changesMap = [
      'id-1' => 1,
      'id-2' => 1,
    ];

    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessage("Un orden duplicado (1) fue asignado explícitamente a múltiples elementos.");

    CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );
  }

  #[Test]
  public function it_handles_assigned_orders_outside_initial_range_gracefully(): void
  {
    $item1 = $this->createTestItem('id-1', 1);
    $item2 = $this->createTestItem('id-2', 2);
    $item3 = $this->createTestItem('id-3', 3);

    $collection = Collection::make([$item1, $item2, $item3]);
    $changesMap = [
      'id-1' => 5,
    ];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(3, $newCollection);
    $this->assertEquals('id-2', $newCollection->get(0)->id);
    $this->assertEquals(1, $newCollection->get(0)->newOrder);
    $this->assertEquals('id-3', $newCollection->get(1)->id);
    $this->assertEquals(2, $newCollection->get(1)->newOrder);
    $this->assertEquals('id-1', $newCollection->get(2)->id);
    $this->assertEquals(5, $newCollection->get(2)->newOrder);
  }

  #[Test]
  public function it_uses_correct_free_orders_when_middle_order_is_freed(): void
  {
    $item1 = $this->createTestItem('id-1', 1);
    $item2 = $this->createTestItem('id-2', 2);
    $item3 = $this->createTestItem('id-3', 3);
    $item4 = $this->createTestItem('id-4', 4);

    $collection = Collection::make([$item1, $item2, $item3, $item4]);
    $changesMap = [
      'id-2' => 4,
    ];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(4, $newCollection);
    $this->assertEquals('id-1', $newCollection->get(0)->id);
    $this->assertEquals(1, $newCollection->get(0)->newOrder);
    $this->assertEquals('id-3', $newCollection->get(1)->id);
    $this->assertEquals(2, $newCollection->get(1)->newOrder);
    $this->assertEquals('id-4', $newCollection->get(2)->id);
    $this->assertEquals(3, $newCollection->get(2)->newOrder);
    $this->assertEquals('id-2', $newCollection->get(3)->id);
    $this->assertEquals(4, $newCollection->get(3)->newOrder);
  }

  #[Test]
  public function it_works_with_integer_item_ids(): void
  {
    $item10 = $this->createTestItem(10, 1);
    $item20 = $this->createTestItem(20, 1);
    $item30 = $this->createTestItem(30, 1);

    $collection = Collection::make([$item10, $item20, $item30]);
    $changesMap = [
      10 => 3,
    ];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(3, $newCollection);
    $this->assertEquals(20, $newCollection->get(0)->id);
    $this->assertEquals(1, $newCollection->get(0)->newOrder);
    $this->assertEquals(30, $newCollection->get(1)->id);
    $this->assertEquals(2, $newCollection->get(1)->newOrder);
    $this->assertEquals(10, $newCollection->get(2)->id);
    $this->assertEquals(3, $newCollection->get(2)->newOrder);
  }

  #[Test]
  public function it_ignores_changes_for_non_existent_items(): void
  {
    $item1 = $this->createTestItem('id-1', 1);
    $collection = Collection::make([$item1]);
    $changesMap = ['id-1' => 2, 'non-existent-id' => 10];

    $newCollection = CollectionOrderManager::calculateNewOrders(
      $collection,
      $changesMap,
      fn($item) => $item->id,
    );

    $this->assertCount(1, $newCollection);
    $this->assertEquals('id-1', $newCollection->get(0)->id);
    $this->assertEquals(2, $newCollection->get(0)->newOrder);
  }
}

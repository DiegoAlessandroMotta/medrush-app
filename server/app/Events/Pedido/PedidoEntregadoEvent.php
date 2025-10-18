<?php

namespace App\Events\Pedido;

use App\Models\Pedido;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PedidoEntregadoEvent
{
  use Dispatchable, InteractsWithSockets, SerializesModels;

  public function __construct(
    public Pedido $pedido
  ) {}

  /**
   * @return array<int, \Illuminate\Broadcasting\Channel>
   */
  public function broadcastOn(): array
  {
    return [
      new PrivateChannel('pedido.' . $this->pedido->id),
    ];
  }
}

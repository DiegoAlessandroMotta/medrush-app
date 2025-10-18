<?php

namespace App\Events\UbicacionRepartidor;

use App\Casts\AsPoint;
use App\Models\UbicacionRepartidor;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UbicacionRepartidorUpdatedEvent implements ShouldBroadcast
{
  use Dispatchable, InteractsWithSockets, SerializesModels;

  private UbicacionRepartidor $ubicacionRepartidor;

  public function __construct(UbicacionRepartidor $ubicacionRepartidor)
  {
    $this->ubicacionRepartidor = $ubicacionRepartidor->load(['repartidor.user']);
  }

  /**
   * @return array<int, \Illuminate\Broadcasting\Channel>
   */
  public function broadcastOn(): array
  {
    return [
      new PrivateChannel('ubicaciones-repartidor'),
      new PrivateChannel('ubicaciones-repartidor.' . $this->ubicacionRepartidor->repartidor_id),
    ];
  }

  public function broadcastAs(): string
  {
    return 'ubicacion-repartidor.updated';
  }

  public function broadcastWith(): array
  {
    return [
      'id' => $this->ubicacionRepartidor->id,
      'repartidor_id' => $this->ubicacionRepartidor->repartidor_id,
      'pedido_id' => $this->ubicacionRepartidor->pedido_id,
      'ruta_id' => $this->ubicacionRepartidor->ruta_id,
      'ubicacion' => AsPoint::serializeValue($this->ubicacionRepartidor->ubicacion),
      'precision_m' => $this->ubicacionRepartidor->precision_m,
      'velocidad_ms' => $this->ubicacionRepartidor->velocidad_ms,
      'direccion' => $this->ubicacionRepartidor->direccion,
      'fecha_registro' => $this->ubicacionRepartidor->fecha_registro,
      'created_at' => $this->ubicacionRepartidor->fecha_registro,
      'repartidor' => [
        'id' => $this->ubicacionRepartidor->repartidor_id,
        'verificado' => $this->ubicacionRepartidor->repartidor->verificado,
        'nombre' => $this->ubicacionRepartidor->repartidor->user->name,
      ],
    ];
  }
}

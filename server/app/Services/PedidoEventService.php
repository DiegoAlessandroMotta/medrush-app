<?php

namespace App\Services;

use App\Models\Pedido;
use App\Models\EventoPedido;
use App\Enums\EventosPedidoEnum;
use App\Enums\EstadosPedidoEnum;
use App\Exceptions\CustomException;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class PedidoEventService
{
  public static function logEventoPedido(
    Pedido $pedido,
    EventosPedidoEnum $tipoEvento,
    ?User $user = null,
    ?string $descripcion = null,
    array $metadata = [],
    ?array $ubicacion = null,
    ?EstadosPedidoEnum $nuevoEstado = null,
    ?bool $clearRepartidor = false,
    ?string $repartidorId = null,
  ): EventoPedido|null {
    $estadoCalculado = $nuevoEstado ?? self::determinarNuevoEstado($tipoEvento);
    $estadoPedidoOriginal = $pedido->estado;
    $descripcionEvento = $descripcion ?? $tipoEvento->getDescription();

    if ($estadoCalculado !== null) {
      self::validarTransicionEstado($estadoPedidoOriginal, $estadoCalculado);
    }

    if ($estadoCalculado === EstadosPedidoEnum::ASIGNADO && $pedido->repartidor_id === $repartidorId) {
      return null;
    }

    /** @var EventoPedido $evento  */
    $evento = DB::transaction(
      function () use (
        $pedido,
        $tipoEvento,
        $user,
        $descripcionEvento,
        $metadata,
        $ubicacion,
        $estadoCalculado,
        $estadoPedidoOriginal,
        $clearRepartidor,
        $repartidorId,
      ) {
        if ($estadoCalculado !== null && $estadoCalculado !== $estadoPedidoOriginal) {
          $pedido->estado = $estadoCalculado;

          if ($estadoCalculado === EstadosPedidoEnum::ASIGNADO) {
            $pedido->fecha_asignacion = now();
          } elseif ($estadoCalculado === EstadosPedidoEnum::RECOGIDO) {
            $pedido->fecha_recogida = now();
          } elseif ($estadoCalculado === EstadosPedidoEnum::ENTREGADO) {
            $pedido->fecha_entrega = now();
          } elseif ($estadoCalculado === EstadosPedidoEnum::FALLIDO) {
            $pedido->motivo_fallo = isset($metadata['motivo_fallo']) ? $metadata['motivo_fallo'] : null;
            $pedido->observaciones_fallo = isset($metadata['observaciones_fallo']) ? $metadata['observaciones_fallo'] : null;
          }
        }

        if ($repartidorId !== null) {
          $pedido->repartidor_id = $repartidorId;
        } elseif ($clearRepartidor) {
          $pedido->repartidor_id = null;
          $pedido->fecha_asignacion = null;
          $pedido->fecha_recogida = null;
        }

        if ($pedido->isDirty()) {
          $pedido->save();
        }

        /** @var EventoPedido $evento  */
        $evento = EventoPedido::create([
          'pedido_id' => $pedido->id,
          'user_id' => $user->id ?? null,
          'tipo_evento' => $tipoEvento,
          'descripcion' => $descripcionEvento,
          'metadata' => $metadata,
          'ubicacion' => $ubicacion,
        ]);

        return $evento;
      }
    );

    return $evento;
  }

  protected static function determinarNuevoEstado(EventosPedidoEnum $tipoEvento): ?EstadosPedidoEnum
  {
    return match ($tipoEvento) {
      EventosPedidoEnum::PEDIDO_CREADO, EventosPedidoEnum::PEDIDO_ASIGNACION_AUTOMATICA_FALLIDA, EventosPedidoEnum::PEDIDO_ASIGNACION_RETIRADA => EstadosPedidoEnum::PENDIENTE,
      EventosPedidoEnum::PEDIDO_ASIGNADO, EventosPedidoEnum::PEDIDO_REASIGNADO => EstadosPedidoEnum::ASIGNADO,
      EventosPedidoEnum::PEDIDO_RECOGIDO => EstadosPedidoEnum::RECOGIDO,
      EventosPedidoEnum::PEDIDO_EN_RUTA => EstadosPedidoEnum::EN_RUTA,
      EventosPedidoEnum::PEDIDO_ENTREGADO => EstadosPedidoEnum::ENTREGADO,
      EventosPedidoEnum::PEDIDO_ENTREGA_FALLIDA => EstadosPedidoEnum::FALLIDO,
      EventosPedidoEnum::PEDIDO_CANCELADO => EstadosPedidoEnum::CANCELADO,
    };
  }

  protected static function validarTransicionEstado(
    ?EstadosPedidoEnum $estadoActual,
    EstadosPedidoEnum $nuevoEstado
  ): void {
    if ($estadoActual === null) {
      return;
    }

    $transicionesValidas = match ($estadoActual) {
      EstadosPedidoEnum::PENDIENTE => [EstadosPedidoEnum::ASIGNADO, EstadosPedidoEnum::CANCELADO],
      EstadosPedidoEnum::ASIGNADO => [EstadosPedidoEnum::PENDIENTE, EstadosPedidoEnum::ASIGNADO, EstadosPedidoEnum::RECOGIDO, EstadosPedidoEnum::CANCELADO],
      EstadosPedidoEnum::RECOGIDO => [EstadosPedidoEnum::FALLIDO, EstadosPedidoEnum::EN_RUTA, EstadosPedidoEnum::FALLIDO, EstadosPedidoEnum::CANCELADO],
      EstadosPedidoEnum::EN_RUTA => [EstadosPedidoEnum::ENTREGADO, EstadosPedidoEnum::FALLIDO, EstadosPedidoEnum::CANCELADO],
      EstadosPedidoEnum::FALLIDO => [EstadosPedidoEnum::PENDIENTE, EstadosPedidoEnum::CANCELADO],
      default => [],
    };

    if (!in_array($nuevoEstado, $transicionesValidas)) {
      throw CustomException::badRequest("Transición de estado inválida de {$estadoActual->value} a {$nuevoEstado->value}.");
    }
  }
}

<?php

namespace App\Enums;

enum EventosPedidoEnum: string
{
  case PEDIDO_CREADO = 'pedido_creado';
  case PEDIDO_ASIGNADO = 'pedido_asignado';
  case PEDIDO_REASIGNADO = 'pedido_reasignado';
  case PEDIDO_ASIGNACION_RETIRADA = 'pedido_asignacion_retirada';

    // case REPARTIDOR_ACEPTO_ORDEN = 'repartidor_acepto_orden';
    // case REPARTIDOR_RECHAZO_ORDEN = 'repartidor_rechazo_orden';
  case PEDIDO_RECOGIDO = 'pedido_recogido';
  case PEDIDO_EN_RUTA = 'pedido_en_ruta';
    // case PEDIDO_LLEGO_UBICACION = 'pedido_llego_ubicacion';

  case PEDIDO_ENTREGADO = 'pedido_entregado';
  case PEDIDO_ENTREGA_FALLIDA = 'pedido_entrega_fallida';
    // case PEDIDO_DEVUELTO_FARMACIA = 'pedido_devuelto_farmacia';
    // case PEDIDO_DEVUELTO_FARMACIA_CONFIRMADO = 'pedido_devuelto_farmacia_confirmado';

  case PEDIDO_CANCELADO = 'pedido_cancelado';
    // case PEDIDO_ACTUALIZADO = 'pedido_actualizado';
    // case PEDIDO_PAUSADO = 'pedido_pausado';
    // case PEDIDO_REANUDADO = 'pedido_reanudado';

  case PEDIDO_ASIGNACION_AUTOMATICA_FALLIDA = 'pedido_asignacion_automatica_fallida';

  public function getDescription(): string
  {
    return match ($this) {
      self::PEDIDO_CREADO => 'El pedido fue creado en el sistema.',
      self::PEDIDO_ASIGNADO => 'Pedido asignado a un repartidor.',
      self::PEDIDO_REASIGNADO => 'Pedido reasignado a un repartidor diferente.',
      self::PEDIDO_ASIGNACION_RETIRADA => 'La asignación del pedido a un repartidor ha sido retirada.',

      // self::REPARTIDOR_ACEPTO_ORDEN => 'El repartidor aceptó la asignación del pedido.',
      // self::REPARTIDOR_RECHAZO_ORDEN => 'El repartidor rechazó la asignación del pedido.',
      self::PEDIDO_RECOGIDO => 'El pedido ha sido recogido de la farmacia.',
      self::PEDIDO_EN_RUTA => 'El repartidor está en ruta hacia el punto de entrega.',
      // self::PEDIDO_LLEGO_UBICACION => 'El repartidor ha llegado al punto de entrega.',

      self::PEDIDO_ENTREGADO => 'El pedido fue entregado exitosamente.',
      self::PEDIDO_ENTREGA_FALLIDA => 'Un intento de entrega ha fallado.',
      // self::PEDIDO_DEVUELTO_FARMACIA => 'El pedido no entregado ha sido devuelto a la farmacia.',
      // self::PEDIDO_DEVUELTO_FARMACIA_CONFIRMADO => 'La farmacia confirmó que el pedido no entregado fue devuelto.',

      self::PEDIDO_CANCELADO => 'El pedido ha sido cancelado.',
      // self::PEDIDO_ACTUALIZADO => 'Los detalles del pedido han sido actualizados.',
      // self::PEDIDO_PAUSADO => 'El pedido ha sido puesto en espera.',
      // self::PEDIDO_REANUDADO => 'El pedido ha sido reanudado desde el estado de espera.',

      self::PEDIDO_ASIGNACION_AUTOMATICA_FALLIDA => 'La asignación automática del pedido a un repartidor ha fallado.',
    };
  }
}

<?php

namespace App\Enums;

enum EstadosPedidoEnum: string
{
  case PENDIENTE = 'pendiente';
  case ASIGNADO = 'asignado';
  case RECOGIDO = 'recogido';
  case EN_RUTA = 'en_ruta';
  case ENTREGADO = 'entregado';
  case FALLIDO = 'fallido';
    // case DEVUELTO = 'devuelto';
    // case PAUSADO = 'pausado';
  case CANCELADO = 'cancelado';
}

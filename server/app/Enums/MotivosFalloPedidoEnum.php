<?php

namespace App\Enums;

enum MotivosFalloPedidoEnum: string
{
  case NO_SE_ENCONTRABA = 'no_se_encontraba';
  case DIRECCION_INCORRECTA = 'direccion_incorrecta';
  case NO_RECIBIO_LLAMADAS = 'no_recibio_llamadas';
  case RECHAZO_ENTREGA = 'rechazo_entrega';
  case ACCESO_DENEGADO = 'acceso_denegado';
  case OTRO = 'otro';
}

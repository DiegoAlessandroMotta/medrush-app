<?php

namespace App\Enums;

enum EstadosRepartidorEnum: string
{
  case DISPONIBLE = 'disponible';
  case EN_RUTA = 'en_ruta';
  case DESCONECTADO = 'desconectado';
}

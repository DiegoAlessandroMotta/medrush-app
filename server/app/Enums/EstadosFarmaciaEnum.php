<?php

namespace App\Enums;

enum EstadosFarmaciaEnum: string
{
  case ACTIVA = 'activa';
  case INACTIVA = 'inactiva';
  case SUSPENDIDA = 'suspendida';
  case EN_REVISION = 'en_revision';
}

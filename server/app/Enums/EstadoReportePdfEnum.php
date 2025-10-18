<?php

namespace App\Enums;

enum EstadoReportePdfEnum: string
{
  case EN_PROCESO = 'en_proceso';
  case CREADO = 'creado';
  case FALLIDO = 'fallido';
  case EXPIRADO = 'expirado';
}

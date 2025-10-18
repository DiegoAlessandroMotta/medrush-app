<?php

namespace App\Listeners\Pedido;

use App\Events\Pedido\PedidoEntregadoEvent;
use App\Mail\PedidoEntregadoMail;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class EnviarNotificacionPaciente implements ShouldQueue
{
  use InteractsWithQueue;

  public function __construct() {}

  public function handle(PedidoEntregadoEvent $event): void
  {
    try {
      if (empty($event->pedido->paciente_email) || !filter_var($event->pedido->paciente_email, FILTER_VALIDATE_EMAIL)) {
        return;
      }

      Mail::to($event->pedido->paciente_email)
        ->send(new PedidoEntregadoMail($event->pedido));

      Log::info('Email de pedido entregado enviado exitosamente', [
        'pedido_id' => $event->pedido->id,
        'email' => $event->pedido->paciente_email,
        'codigo_barra' => $event->pedido->codigo_barra
      ]);
    } catch (\Exception $e) {
      Log::error('Error al enviar email de pedido entregado', [
        'pedido_id' => $event->pedido->id,
        'email' => $event->pedido->paciente_email,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
      ]);

      throw $e;
    }
  }
}

<?php

namespace App\Mail;

use App\Models\Pedido;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class PedidoEntregadoMail extends Mailable implements ShouldQueue
{
  use Queueable, SerializesModels;

  public function __construct(
    public Pedido $pedido
  ) {}

  public function envelope(): Envelope
  {
    return new Envelope(
      subject: 'Tu pedido #' . $this->pedido->codigo_barra . ' ha sido entregado exitosamente',
    );
  }

  public function content(): Content
  {
    return new Content(
      markdown: 'mail.pedido-entregado',
      with: [
        'pedido' => $this->pedido,
        'pacienteNombre' => $this->pedido->paciente_nombre,
        'codigoBarra' => $this->pedido->codigo_barra,
        'fechaEntrega' => $this->pedido->fecha_entrega,
        'farmacia' => $this->pedido->farmacia,
        'direccionEntrega' => $this->pedido->direccion_entrega_linea_1 .
          ($this->pedido->direccion_entrega_linea_2 ? ', ' . $this->pedido->direccion_entrega_linea_2 : '') .
          ', ' . $this->pedido->ciudad_entrega . ', ' . $this->pedido->estado_region_entrega
      ]
    );
  }

  /**
   * @return array<int, \Illuminate\Mail\Mailables\Attachment>
   */
  public function attachments(): array
  {
    return [];
  }
}

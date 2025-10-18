@component('mail::message')
  # ¡Tu pedido ha sido entregado exitosamente!

  Hola **{{ $pacienteNombre }}**,

  Nos complace informarte que tu pedido de medicamentos ha sido entregado exitosamente.

  ## Detalles del Pedido

  - **Número de Pedido:** {{ $codigoBarra }}
  - **Dirección de Entrega:** {{ $direccionEntrega }}

  ## ¿Qué sigue?

  - Si tienes alguna pregunta sobre tu pedido, no dudes en contactarnos

  @component('mail::panel')
    **Importante:** Si tienes algún problema con tu pedido o necesitas asistencia adicional, por favor contáctanos lo antes
    posible.
  @endcomponent

  ¡Gracias por confiar en nosotros para el cuidado de tu salud!

  Saludos cordiales,<br>
  El equipo de {{ config('app.name') }}
@endcomponent

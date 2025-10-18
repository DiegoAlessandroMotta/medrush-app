<?php

namespace App\Http\Controllers\Entities;

use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Models\Pedido;

class EventoPedidoController extends Controller
{
  public function index(Pedido $pedido)
  {
    $eventos = $pedido->eventosPedido()->orderBy('created_at', 'desc')->get();

    return ApiResponder::success(
      message: 'Mostrando los eventos del pedido',
      data: $eventos
    );
  }
}

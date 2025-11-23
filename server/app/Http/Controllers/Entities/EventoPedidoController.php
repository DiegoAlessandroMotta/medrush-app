<?php

namespace App\Http\Controllers\Entities;

use App\Helpers\ApiResponder;
use App\Http\Controllers\Controller;
use App\Models\Pedido;

class EventoPedidoController extends Controller
{
  /**
   * @OA\Get(
   *     path="/api/pedidos/{pedido}/eventos",
   *     operationId="eventosPedidoIndex",
   *     tags={"Pedidos","Eventos"},
   *     summary="Obtener eventos de un pedido",
   *     description="Obtiene el historial completo de eventos asociados a un pedido específico, ordenados por fecha de creación descendente. Los eventos registran cambios de estado, asignaciones, entregas y otras acciones importantes del pedido.",
   *     security={{"sanctum":{}}},
   *     @OA\Parameter(
   *         name="pedido",
   *         in="path",
   *         required=true,
   *         description="UUID del pedido",
   *         @OA\Schema(type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000"),
   *     ),
   *     @OA\Response(
   *         response=200,
   *         description="Eventos del pedido obtenidos exitosamente",
   *         @OA\JsonContent(
   *             @OA\Property(property="status", type="string", enum={"success"}, example="success"),
   *             @OA\Property(property="message", type="string", example="Mostrando los eventos del pedido"),
   *             @OA\Property(property="data", type="array", description="Array de eventos del pedido",
   *                 items=@OA\Items(type="object",
   *                     @OA\Property(property="id", type="integer", example=1, description="ID único del evento"),
   *                     @OA\Property(property="pedido_id", type="string", format="uuid", example="550e8400-e29b-41d4-a716-446655440000", description="UUID del pedido al que pertenece el evento"),
   *                     @OA\Property(property="user_id", type="string", format="uuid", nullable=true, example="550e8400-e29b-41d4-a716-446655440001", description="UUID del usuario que causó el evento (nullable)"),
   *                     @OA\Property(property="tipo_evento", type="string", enum={"pedido_creado","pedido_asignado","pedido_reasignado","pedido_asignacion_retirada","pedido_recogido","pedido_en_ruta","pedido_entregado","pedido_entrega_fallida","pedido_cancelado","pedido_asignacion_automatica_fallida"}, example="pedido_asignado", description="Tipo de evento (Estado del pedido)"),
   *                     @OA\Property(property="descripcion", type="string", nullable=true, example="Pedido asignado a repartidor XYZ", description="Descripción adicional del evento"),
   *                     @OA\Property(property="metadata", type="object", nullable=true, example={"repartidor_id":"123","razon":"disponibilidad"}, description="Datos adicionales asociados al evento (estructura variable según el tipo)"),
   *                     @OA\Property(property="ubicacion", type="object", nullable=true, description="Ubicación geográfica del evento (punto GIS)",
   *                         @OA\Property(property="type", type="string", enum={"Point"}, example="Point"),
   *                         @OA\Property(property="coordinates", type="array", items=@OA\Items(type="number"), example={-74.0087,4.7110}, description="[longitude, latitude]"),
   *                     ),
   *                     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-22T15:30:00.000000Z"),
   *                     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-22T15:30:00.000000Z"),
   *                 )
   *             ),
   *         ),
   *     ),
   *     @OA\Response(
   *         response=401,
   *         description="No autenticado",
   *         @OA\JsonContent(ref="#/components/schemas/UnauthorizedResponse")
   *     ),
   *     @OA\Response(
   *         response=403,
   *         description="No autorizado para ver este pedido",
   *         @OA\JsonContent(ref="#/components/schemas/ForbiddenResponse")
   *     ),
   *     @OA\Response(
   *         response=404,
   *         description="Pedido no encontrado",
   *         @OA\JsonContent(ref="#/components/schemas/NotFoundResponse")
   *     ),
   * )
   */
  public function index(Pedido $pedido)
  {
    $eventos = $pedido->eventosPedido()->orderBy('created_at', 'desc')->get();

    return ApiResponder::success(
      message: 'Mostrando los eventos del pedido',
      data: $eventos
    );
  }
}

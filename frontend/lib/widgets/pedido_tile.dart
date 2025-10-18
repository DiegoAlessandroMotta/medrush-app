import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/utils/status_helpers.dart';

class PedidoTile extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onTap;
  final VoidCallback? onRecoger;
  final VoidCallback? onEntregar;
  final VoidCallback? onVerRuta;

  const PedidoTile({
    super.key,
    required this.pedido,
    this.onTap,
    this.onRecoger,
    this.onEntregar,
    this.onVerRuta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ID y estado
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: StatusHelpers.estadoPedidoColor(pedido.estado),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${pedido.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: StatusHelpers.estadoPedidoColor(pedido.estado)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StatusHelpers.estadoPedidoColor(pedido.estado)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      StatusHelpers.estadoPedidoTexto(pedido.estado),
                      style: TextStyle(
                        color: StatusHelpers.estadoPedidoColor(pedido.estado),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (pedido.prioridad > 1)
                    Icon(
                      Icons.priority_high,
                      color: pedido.prioridad >= 3 ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del paciente
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pedido.pacienteNombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dirección
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pedido.direccion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Teléfono
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    pedido.pacienteTelefono,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tipo y fecha
              Row(
                children: [
                  const Icon(Icons.medical_services,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    StatusHelpers.tipoPedidoTexto(pedido.tipo),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(pedido.createdAt ?? DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              // Medicamentos
              if (pedido.medicamentos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: pedido.medicamentos.take(3).map((medicamento) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        medicamento['nombre'] ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (pedido.medicamentos.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${pedido.medicamentos.length - 3} más',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],

              // Observaciones
              if (pedido.observaciones != null &&
                  pedido.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pedido.observaciones!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botones de acción
              const SizedBox(height: 12),
              Row(
                children: [
                  if (pedido.estado == EstadoPedido.pendiente &&
                      onRecoger != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRecoger,
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: const Text('Recoger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (pedido.estado == EstadoPedido.recogido ||
                      pedido.estado == EstadoPedido.enRuta) ...[
                    if (onVerRuta != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onVerRuta,
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text('Ver Ruta'),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (onEntregar != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEntregar,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Entregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                  if (pedido.estado == EstadoPedido.entregado)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade600, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Entregado',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // TODO: Implementar cuando el backend soporte tracking de fecha de entrega específica
                            // Por ahora usamos createdAt como placeholder
                            Text(
                              DateFormat('HH:mm')
                                  .format(pedido.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (pedido.estado == EstadoPedido.fallido)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error,
                                color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Fallido',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Estado color centralizado via StatusHelpers

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Pedido>('pedido', pedido))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onRecoger', onRecoger))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onEntregar', onEntregar))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onVerRuta', onVerRuta));
  }
}

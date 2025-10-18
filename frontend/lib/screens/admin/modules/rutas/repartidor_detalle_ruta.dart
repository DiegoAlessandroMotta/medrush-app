import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/ruta_optimizada.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/repositories/ruta.repository.dart';
import 'package:medrush/screens/admin/modules/rutas/ruta_detalle.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';

class RepartidorDetalleRutaModal extends StatelessWidget {
  const RepartidorDetalleRutaModal({
    super.key,
    required this.ruta,
  });

  final RutaOptimizada ruta;

  Widget _buildErrorModal(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 600
            ? 600
            : MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(MedRushTheme.borderRadiusLg)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MedRushTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingLg),

            const Row(
              children: [
                Icon(LucideIcons.x, color: MedRushTheme.error),
                SizedBox(width: MedRushTheme.spacingSm),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeTitleMedium,
                    fontWeight: MedRushTheme.fontWeightBold,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MedRushTheme.spacingMd),

            const Text(
              'No hay información del repartidor disponible',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textSecondary,
              ),
            ),

            const SizedBox(height: MedRushTheme.spacingLg),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedRushTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepartidorInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                color: MedRushTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDetallesRuta(
      BuildContext context, RutaOptimizada ruta) async {
    // Mostrar loading mientras se obtienen los detalles completos
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            MedRushTheme.primaryGreen,
          ),
        ),
      ),
    );

    try {
      // Obtener detalles completos de la ruta y sus pedidos
      final rutaRepository = RutaRepository();
      final futures = await Future.wait([
        rutaRepository.obtenerPorId(ruta.id),
        rutaRepository.obtenerPedidosRuta(rutaId: ruta.id),
      ]);

      final rutaResult = futures[0] as RepositoryResult<RutaOptimizada?>;
      final pedidosResult =
          futures[1] as RepositoryResult<List<Map<String, dynamic>>>;

      final rutaCompleta = rutaResult.success ? rutaResult.data : null;
      final pedidosDetallados =
          pedidosResult.success ? (pedidosResult.data ?? []) : [];

      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading

        if (rutaCompleta != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RutaDetalleModal(
              ruta: rutaCompleta,
              pedidosDetallados: pedidosDetallados.cast<Map<String, dynamic>>(),
            ),
          );
        } else {
          _mostrarError(
              context, 'No se pudieron cargar los detalles de la ruta');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        _mostrarError(context, 'Error al cargar detalles: ${e.toString()}');
      }
    }
  }

  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: MedRushTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ruta.repartidor == null) {
      return _buildErrorModal(context);
    }

    final repartidor = ruta.repartidor!;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 600
            ? 600
            : MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(MedRushTheme.borderRadiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: MedRushTheme.spacingMd),
            decoration: BoxDecoration(
              color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          const Padding(
            padding: EdgeInsets.all(MedRushTheme.spacingLg),
            child: Row(
              children: [
                Icon(LucideIcons.user, color: MedRushTheme.primaryGreen),
                SizedBox(width: MedRushTheme.spacingSm),
                Text(
                  'Detalles del Repartidor',
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeTitleMedium,
                    fontWeight: MedRushTheme.fontWeightBold,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRepartidorInfo(
                      'ID', repartidor['id']?.toString() ?? 'N/A'),
                  _buildRepartidorInfo(
                      'Nombre', repartidor['nombre']?.toString() ?? 'N/A'),
                  _buildRepartidorInfo(
                      'Email', repartidor['email']?.toString() ?? 'N/A'),
                  _buildRepartidorInfo(
                      'Teléfono', repartidor['telefono']?.toString() ?? 'N/A'),
                  if (repartidor['verificado'] != null)
                    _buildRepartidorInfo('Verificado',
                        repartidor['verificado'] == true ? 'Sí' : 'No'),
                  if (repartidor['estado'] != null)
                    _buildRepartidorInfo(
                        'Estado', repartidor['estado']?.toString() ?? 'N/A'),
                  if (repartidor['fecha_registro'] != null)
                    _buildRepartidorInfo(
                        'Fecha de Registro',
                        StatusHelpers.formatearFechaCompleta(DateTime.parse(
                            repartidor['fecha_registro'].toString()))),
                  if (repartidor['ultima_actividad'] != null)
                    _buildRepartidorInfo(
                        'Última Actividad',
                        StatusHelpers.formatearFechaCompleta(DateTime.parse(
                            repartidor['ultima_actividad'].toString()))),

                  const SizedBox(height: MedRushTheme.spacingMd),

                  // Información de la ruta actual
                  Container(
                    padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: MedRushTheme.backgroundSecondary,
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ruta Actual',
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                            fontWeight: MedRushTheme.fontWeightBold,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: MedRushTheme.spacingSm),
                        _buildRepartidorInfo('Ruta ID', ruta.id),
                        _buildRepartidorInfo(
                            'Nombre de Ruta', ruta.nombre ?? 'Sin nombre'),
                        if (ruta.distanciaTotalEstimada != null)
                          _buildRepartidorInfo(
                              'Distancia Total',
                              StatusHelpers.formatearDistanciaKm(
                                  ruta.distanciaTotalEstimada!,
                                  decimales: 2)),
                        if (ruta.tiempoTotalEstimado != null)
                          _buildRepartidorInfo(
                              'Tiempo Estimado',
                              StatusHelpers.formatearTiempo(
                                  ruta.tiempoTotalEstimado!)),
                        _buildRepartidorInfo('Pedidos Asignados',
                            '${ruta.cantidadPedidos ?? 0} pedidos'),
                        if (ruta.fechaHoraCalculo != null)
                          _buildRepartidorInfo(
                              'Fecha de Cálculo',
                              StatusHelpers.formatearFechaCompleta(
                                  ruta.fechaHoraCalculo!)),
                        if (ruta.fechaInicio != null)
                          _buildRepartidorInfo(
                              'Fecha de Inicio',
                              StatusHelpers.formatearFechaCompleta(
                                  ruta.fechaInicio!)),
                        if (ruta.fechaCompletado != null)
                          _buildRepartidorInfo(
                              'Fecha de Completado',
                              StatusHelpers.formatearFechaCompleta(
                                  ruta.fechaCompletado!)),
                      ],
                    ),
                  ),

                  const SizedBox(height: MedRushTheme.spacingLg),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(MedRushTheme.spacingLg),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: MedRushTheme.spacingMd),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mostrarDetallesRuta(context, ruta);
                    },
                    icon: const Icon(LucideIcons.eye, size: 16),
                    label: const Text('Ver Ruta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MedRushTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

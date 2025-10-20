import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';

class LimpiezaPedidosWidget extends StatefulWidget {
  const LimpiezaPedidosWidget({super.key});

  @override
  State<LimpiezaPedidosWidget> createState() => _LimpiezaPedidosWidgetState();
}

class _LimpiezaPedidosWidgetState extends State<LimpiezaPedidosWidget> {
  bool _isLoading = false;
  int _semanasSeleccionadas = 3;
  final PedidoRepository _pedidoRepository = PedidoRepository();

  String _getMonthsReference(int weeks) {
    final months = (weeks / 4.33).round(); // 4.33 semanas promedio por mes
    if (months == 0) {
      return 'menos de 1 mes';
    }
    if (months == 1) {
      return '~1 mes';
    }
    return '~$months meses';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedRushTheme.warning.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusSm),
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  color: MedRushTheme.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Limpieza de Archivos de Pedidos Antiguos',
                style: TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyLarge,
                  fontWeight: MedRushTheme.fontWeightSemiBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Descripción
          const Text(
            'Esta acción eliminará permanentemente solo los archivos multimedia (fotos de entrega y firmas digitales) de pedidos entregados hace más del tiempo seleccionado. Los datos del pedido se mantendrán intactos.',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodySmall,
              color: MedRushTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Selector de semanas
          _buildSemanasSelector(),
          const SizedBox(height: 24),

          // Botón de acción
          _buildBotonAccion(),
        ],
      ),
    );
  }

  Widget _buildSemanasSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Semanas hacia atrás',
          style: TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.calendar,
                size: 16,
                color: MedRushTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_semanasSeleccionadas ${_semanasSeleccionadas == 1 ? 'semana' : 'semanas'} hacia atrás',
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.textPrimary,
                        fontWeight: MedRushTheme.fontWeightMedium,
                      ),
                    ),
                    Text(
                      _getMonthsReference(_semanasSeleccionadas),
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeLabelSmall,
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: MedRushTheme.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Selector de semanas
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 2, 3, 4, 6, 8, 12, 24, 52].map((semanas) {
            final isSelected = _semanasSeleccionadas == semanas;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _semanasSeleccionadas = semanas;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MedRushTheme.primaryGreen
                      : MedRushTheme.backgroundSecondary,
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusSm),
                  border: Border.all(
                    color: isSelected
                        ? MedRushTheme.primaryGreen
                        : MedRushTheme.borderLight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$semanas${semanas == 1 ? ' sem' : ' sem'}',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        fontWeight: isSelected
                            ? MedRushTheme.fontWeightMedium
                            : MedRushTheme.fontWeightRegular,
                        color: isSelected
                            ? MedRushTheme.textInverse
                            : MedRushTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _getMonthsReference(semanas),
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeLabelSmall,
                        fontWeight: MedRushTheme.fontWeightRegular,
                        color: isSelected
                            ? MedRushTheme.textInverse.withValues(alpha: 0.8)
                            : MedRushTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBotonAccion() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _mostrarDialogoConfirmacion,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(LucideIcons.x, color: Colors.white, size: 16),
        label: Text(_isLoading ? 'Procesando...' : 'Guardar Configuración'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MedRushTheme.warning,
          foregroundColor: MedRushTheme.textInverse,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.info, color: MedRushTheme.warning),
            SizedBox(width: 8),
            Text('Confirmar Limpieza'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar solo los archivos multimedia (fotos y firmas) de pedidos entregados hace más de $_semanasSeleccionadas ${_semanasSeleccionadas == 1 ? 'semana' : 'semanas'}?',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingSm),
              decoration: BoxDecoration(
                color: MedRushTheme.error.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusSm),
                border: Border.all(
                  color: MedRushTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: MedRushTheme.error,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción eliminará permanentemente solo los archivos multimedia (fotos y firmas). Los datos del pedido se mantendrán intactos.',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _ejecutarLimpieza();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarLimpieza() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await _pedidoRepository
          .eliminarPedidosAntiguos(_semanasSeleccionadas);

      if (resultado.success && resultado.data == true) {
        if (mounted) {
          NotificationService.showSuccess(
            'La limpieza de archivos multimedia de pedidos antiguos ha sido iniciada exitosamente',
            context: context,
          );
        }
      } else {
        throw Exception(resultado.error ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          'Error al iniciar la limpieza: ${e.toString()}',
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

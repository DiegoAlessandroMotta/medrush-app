import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
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

  String _getMonthsReference(BuildContext context, int weeks) {
    final months = (weeks / 4.33).round(); // 4.33 semanas promedio por mes
    if (months == 0) {
      return AppLocalizations.of(context).lessThanOneMonth;
    }
    if (months == 1) {
      return AppLocalizations.of(context).aboutOneMonth;
    }
    return AppLocalizations.of(context).aboutMonthsCount(months);
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
              Text(
                AppLocalizations.of(context).oldOrdersCleanupTitle,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyLarge,
                  fontWeight: MedRushTheme.fontWeightSemiBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Descripción
          Text(
            AppLocalizations.of(context).oldOrdersCleanupDescription,
            style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).weeksBackLabel,
          style: const TextStyle(
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
                      l10n.weeksBackDisplay(
                        _semanasSeleccionadas,
                        _semanasSeleccionadas == 1 ? l10n.weekLabel : l10n.weeksLabel,
                      ),
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.textPrimary,
                        fontWeight: MedRushTheme.fontWeightMedium,
                      ),
                    ),
                    Text(
                      _getMonthsReference(context, _semanasSeleccionadas),
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
                      '$semanas ${l10n.weekShortLabel}',
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
                      _getMonthsReference(context, semanas),
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
        label: Text(_isLoading ? AppLocalizations.of(context).processing : AppLocalizations.of(context).saveConfiguration),
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
        title: Row(
          children: [
            const Icon(LucideIcons.info, color: MedRushTheme.warning),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).confirmCleanup),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).confirmCleanupWeeksQuestion(
                _semanasSeleccionadas,
                _semanasSeleccionadas == 1
                    ? AppLocalizations.of(context).weekLabel
                    : AppLocalizations.of(context).weeksLabel,
              ),
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
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    color: MedRushTheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).confirmCleanupDescription,
                      style: const TextStyle(
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
            child: Text(AppLocalizations.of(context).cancel),
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
            child: Text(AppLocalizations.of(context).confirm),
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
            AppLocalizations.of(context).cleanupStartedSuccess,
            context: context,
          );
        }
      } else {
        if (!mounted) {
          return;
        }
        throw Exception(
            resultado.error ?? AppLocalizations.of(context).unknownError);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      NotificationService.showError(
        '${AppLocalizations.of(context).errorStartingCleanup}: ${e.toString()}',
        context: context,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/google_api_usage.model.dart';
import 'package:medrush/repositories/google_api_usage.repository.dart';
import 'package:medrush/theme/theme.dart';

class GoogleApiMetricsWidget extends StatefulWidget {
  const GoogleApiMetricsWidget({super.key});

  @override
  State<GoogleApiMetricsWidget> createState() => _GoogleApiMetricsWidgetState();
}

class _GoogleApiMetricsWidgetState extends State<GoogleApiMetricsWidget> {
  GoogleApiUsageStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await GoogleApiUsageRepository.getCurrentMonthStats();

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.all(
          isMobile ? MedRushTheme.spacingMd : MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                LucideIcons.activity,
                color: MedRushTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              Expanded(
                child: Text(
                  'Métricas de Google API',
                  style: TextStyle(
                    fontSize: isMobile
                        ? MedRushTheme.fontSizeBodyMedium
                        : MedRushTheme.fontSizeBodyLarge,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 20),
                onPressed: _loadStats,
                tooltip: 'Actualizar métricas',
              ),
            ],
          ),
          SizedBox(
              height:
                  isMobile ? MedRushTheme.spacingMd : MedRushTheme.spacingLg),

          // Contenido
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(MedRushTheme.spacingXl),
                child: CircularProgressIndicator(
                  color: MedRushTheme.primaryGreen,
                ),
              ),
            ),
          ] else if (_error != null) ...[
            _buildErrorState(),
          ] else if (_stats != null) ...[
            _buildStatsContent(isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(
          color: MedRushTheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.settings,
            color: MedRushTheme.error,
            size: 32,
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          const Text(
            'Error al cargar las métricas',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              fontWeight: MedRushTheme.fontWeightMedium,
              color: MedRushTheme.error,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodySmall,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(bool isMobile) {
    final stats = _stats!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Período
        Container(
          padding: EdgeInsets.all(
              isMobile ? MedRushTheme.spacingSm : MedRushTheme.spacingMd),
          decoration: BoxDecoration(
            color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            border: Border.all(
              color: MedRushTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.calendar,
                color: MedRushTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              Expanded(
                child: Text(
                  'Período: ${stats.period.formattedPeriod}',
                  style: TextStyle(
                    fontSize: isMobile
                        ? MedRushTheme.fontSizeBodySmall
                        : MedRushTheme.fontSizeBodyMedium,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
            height: isMobile ? MedRushTheme.spacingMd : MedRushTheme.spacingLg),

        // Resumen general
        _buildSummaryCard(stats.summary, isMobile),
        SizedBox(
            height: isMobile ? MedRushTheme.spacingMd : MedRushTheme.spacingLg),

        // Servicios individuales
        if (stats.services.isNotEmpty) ...[
          Text(
            'Servicios',
            style: TextStyle(
              fontSize: isMobile
                  ? MedRushTheme.fontSizeBodyMedium
                  : MedRushTheme.fontSizeBodyLarge,
              fontWeight: MedRushTheme.fontWeightMedium,
              color: MedRushTheme.textPrimary,
            ),
          ),
          SizedBox(
              height:
                  isMobile ? MedRushTheme.spacingSm : MedRushTheme.spacingMd),
          ...stats.services
              .map((service) => _buildServiceCard(service, isMobile)),
        ] else ...[
          _buildEmptyState(),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(GoogleApiUsageSummary summary, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
          isMobile ? MedRushTheme.spacingMd : MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildSummaryItem(
                  icon: LucideIcons.activity,
                  label: 'Total de solicitudes',
                  value: summary.totalRequests.toString(),
                  color: MedRushTheme.primaryGreen,
                  isMobile: isMobile,
                ),
                const SizedBox(height: MedRushTheme.spacingMd),
                _buildSummaryItem(
                  icon: LucideIcons.dollarSign,
                  label: 'Costo estimado',
                  value: summary.formattedCost,
                  color: MedRushTheme.warning,
                  isMobile: isMobile,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: LucideIcons.activity,
                    label: 'Total de solicitudes',
                    value: summary.totalRequests.toString(),
                    color: MedRushTheme.primaryGreen,
                    isMobile: isMobile,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: MedRushTheme.borderLight,
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: LucideIcons.dollarSign,
                    label: 'Costo estimado',
                    value: summary.formattedCost,
                    color: MedRushTheme.warning,
                    isMobile: isMobile,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: isMobile ? 20 : 24),
        SizedBox(
            height: isMobile ? MedRushTheme.spacingXs : MedRushTheme.spacingSm),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile
                ? MedRushTheme.fontSizeBodyLarge
                : MedRushTheme.fontSizeTitleMedium,
            fontWeight: MedRushTheme.fontWeightBold,
            color: color,
          ),
        ),
        SizedBox(height: isMobile ? 2 : MedRushTheme.spacingXs),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile
                ? MedRushTheme.fontSizeLabelSmall
                : MedRushTheme.fontSizeBodySmall,
            color: MedRushTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildServiceCard(GoogleApiService service, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(
          bottom: isMobile ? MedRushTheme.spacingSm : MedRushTheme.spacingMd),
      padding: EdgeInsets.all(
          isMobile ? MedRushTheme.spacingSm : MedRushTheme.spacingMd),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.cpu,
                color: MedRushTheme.primaryGreen,
                size: isMobile ? 18 : 20,
              ),
              SizedBox(
                  width: isMobile
                      ? MedRushTheme.spacingXs
                      : MedRushTheme.spacingSm),
              Expanded(
                child: Text(
                  service.serviceName,
                  style: TextStyle(
                    fontSize: isMobile
                        ? MedRushTheme.fontSizeBodySmall
                        : MedRushTheme.fontSizeBodyMedium,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
              height:
                  isMobile ? MedRushTheme.spacingSm : MedRushTheme.spacingMd),
          if (isMobile) Column(
                  children: [
                    _buildServiceMetric(
                      'Solicitudes',
                      service.totalRequests.toString(),
                      LucideIcons.activity,
                      isMobile,
                    ),
                    const SizedBox(height: MedRushTheme.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceMetric(
                            'Costo por solicitud',
                            service.formattedCostPerRequest,
                            LucideIcons.dollarSign,
                            isMobile,
                          ),
                        ),
                        const SizedBox(width: MedRushTheme.spacingSm),
                        Expanded(
                          child: _buildServiceMetric(
                            'Costo total',
                            service.formattedCost,
                            LucideIcons.calculator,
                            isMobile,
                          ),
                        ),
                      ],
                    ),
                  ],
                ) else Row(
                  children: [
                    Expanded(
                      child: _buildServiceMetric(
                        'Solicitudes',
                        service.totalRequests.toString(),
                        LucideIcons.activity,
                        isMobile,
                      ),
                    ),
                    Expanded(
                      child: _buildServiceMetric(
                        'Costo por solicitud',
                        service.formattedCostPerRequest,
                        LucideIcons.dollarSign,
                        isMobile,
                      ),
                    ),
                    Expanded(
                      child: _buildServiceMetric(
                        'Costo total',
                        service.formattedCost,
                        LucideIcons.calculator,
                        isMobile,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildServiceMetric(
      String label, String value, IconData icon, bool isMobile) {
    return Column(
      children: [
        Icon(icon, color: MedRushTheme.textSecondary, size: isMobile ? 14 : 16),
        SizedBox(height: isMobile ? 2 : MedRushTheme.spacingXs),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile
                ? MedRushTheme.fontSizeBodySmall
                : MedRushTheme.fontSizeBodyMedium,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 2 : MedRushTheme.spacingXs),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile
                ? MedRushTheme.fontSizeLabelSmall
                : MedRushTheme.fontSizeBodySmall,
            color: MedRushTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingXl),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: const Column(
        children: [
          Icon(
            LucideIcons.activity,
            color: MedRushTheme.textSecondary,
            size: 48,
          ),
          SizedBox(height: MedRushTheme.spacingMd),
          Text(
            'No hay datos de uso disponibles',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
          ),
          SizedBox(height: MedRushTheme.spacingSm),
          Text(
            'Las métricas aparecerán cuando se realicen solicitudes a la API',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodySmall,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

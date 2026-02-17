import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/repositories/google_api_usage.repository.dart';
import 'package:medrush/theme/theme.dart';

class GoogleApiMetricsWidget extends StatefulWidget {
  const GoogleApiMetricsWidget({super.key});

  @override
  State<GoogleApiMetricsWidget> createState() => _GoogleApiMetricsWidgetState();
}

class _GoogleApiMetricsWidgetState extends State<GoogleApiMetricsWidget> {
  GoogleApiUsageStatsDto? _stats;
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

  void _showCostInfoDialog() {
    if (_stats == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).costPerRequest),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _stats!.services
                .map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.serviceName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            s.formattedCostPerRequest,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showServiceCostDetail(GoogleApiServiceDto service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service.serviceName, style: const TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              AppLocalizations.of(context).requestsLabel,
              service.totalRequests.toString(),
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              AppLocalizations.of(context).costPerRequest,
              'x ${service.formattedCostPerRequest}',
              color: MedRushTheme.textSecondary,
            ),
            const Divider(height: 16, thickness: 1),
            _buildDetailRow(
              AppLocalizations.of(context).totalCost,
              service.formattedCost,
              isBold: true,
              color: MedRushTheme.primaryGreen,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: MedRushTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? MedRushTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusSm),
                ),
                child: const Icon(
                  LucideIcons.activity,
                  color: MedRushTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).googleApiUsageTitle,
                  style: TextStyle(
                    fontSize: isMobile
                        ? MedRushTheme.fontSizeBodyMedium
                        : MedRushTheme.fontSizeBodyLarge,
                    fontWeight: MedRushTheme.fontWeightSemiBold,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline,
                    size: 18, color: MedRushTheme.textSecondary),
                onPressed: _showCostInfoDialog,
                tooltip: AppLocalizations.of(context).costPerRequest,
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw,
                    size: 18, color: MedRushTheme.textSecondary),
                onPressed: _loadStats,
                tooltip: AppLocalizations.of(context).refreshMetricsTooltip,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).apiCallsLast30Days,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodySmall,
              color: MedRushTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Contenido
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
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
          Text(
            AppLocalizations.of(context).errorLoadingMetrics,
            style: const TextStyle(
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
            label: Text(AppLocalizations.of(context).retry),
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
        // Período y Total de Solicitudes en la misma línea
        Row(
          children: [
            // Período
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    color: MedRushTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: MedRushTheme.spacingSm),
                  Text(
                    '${AppLocalizations.of(context).periodLabel}: ${stats.period.formattedPeriod}',
                    style: TextStyle(
                      fontSize: isMobile
                          ? MedRushTheme.fontSizeBodySmall
                          : MedRushTheme.fontSizeBodyMedium,
                      fontWeight: MedRushTheme.fontWeightMedium,
                      color: MedRushTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Total de Solicitudes compacto
            Container(
              padding: EdgeInsets.symmetric(
                horizontal:
                    isMobile ? MedRushTheme.spacingSm : MedRushTheme.spacingMd,
                vertical:
                    isMobile ? MedRushTheme.spacingXs : MedRushTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(
                  color: MedRushTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.activity,
                    color: MedRushTheme.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: MedRushTheme.spacingXs),
                  Text(
                    stats.summary.totalRequests.toString(),
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: MedRushTheme.fontWeightBold,
                      color: MedRushTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context).requestsLabel,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: MedRushTheme.fontWeightMedium,
                      color: MedRushTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
            height: isMobile ? MedRushTheme.spacingMd : MedRushTheme.spacingLg),

        // Servicios individuales
        if (stats.services.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context).servicesLabel,
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

  Widget _buildServiceCard(GoogleApiServiceDto service, bool isMobile) {
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
          if (isMobile)
            Column(
              children: [
                _buildServiceMetric(
                  AppLocalizations.of(context).requestsLabel,
                  service.totalRequests.toString(),
                  LucideIcons.activity,
                  isMobile,
                ),
                const SizedBox(height: MedRushTheme.spacingSm),
                _buildServiceMetric(
                  AppLocalizations.of(context).totalCost,
                  service.formattedCost,
                  LucideIcons.calculator,
                  isMobile,
                  onTap: () => _showServiceCostDetail(service),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildServiceMetric(
                    AppLocalizations.of(context).requestsLabel,
                    service.totalRequests.toString(),
                    LucideIcons.activity,
                    isMobile,
                  ),
                ),
                Expanded(
                  child: _buildServiceMetric(
                    AppLocalizations.of(context).totalCost,
                    service.formattedCost,
                    LucideIcons.calculator,
                    isMobile,
                    onTap: () => _showServiceCostDetail(service),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildServiceMetric(
      String label, String value, IconData icon, bool isMobile,
      {VoidCallback? onTap}) {
    Widget content = Column(
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
            decoration: onTap != null ? TextDecoration.underline : null,
            decorationColor: MedRushTheme.textSecondary,
            decorationStyle: TextDecorationStyle.dotted,
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingXl),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.activity,
            color: MedRushTheme.textSecondary,
            size: 48,
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          Text(
            AppLocalizations.of(context).noUsageDataAvailable,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          Text(
            AppLocalizations.of(context).metricsWillAppearWhenRequests,
            style: const TextStyle(
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

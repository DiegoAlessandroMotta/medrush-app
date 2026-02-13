import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/ruta_optimizada.model.dart';
import 'package:medrush/repositories/ruta.repository.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';

class RutaDetalleModal extends StatefulWidget {
  final RutaOptimizada ruta;
  final List<Map<String, dynamic>> pedidosDetallados;

  const RutaDetalleModal({
    super.key,
    required this.ruta,
    required this.pedidosDetallados,
  });

  @override
  State<RutaDetalleModal> createState() => _RutaDetalleModalState();
}

class _RutaDetalleModalState extends State<RutaDetalleModal> {
  List<Map<String, dynamic>> _pedidosDetallados = [];
  bool _isRefreshing = false;
  final RutaRepository _rutaRepository = RutaRepository();

  @override
  void initState() {
    super.initState();
    _pedidosDetallados = widget.pedidosDetallados;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MedRushTheme.borderRadiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle del modal
          Container(
            width: 40,
            height: 4,
            margin:
                const EdgeInsets.symmetric(vertical: MedRushTheme.spacingMd),
            decoration: BoxDecoration(
              color: MedRushTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header mejorado
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingLg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(MedRushTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                  ),
                  child: const Icon(
                    LucideIcons.route,
                    color: MedRushTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: MedRushTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).routeDetailsTitle,
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeTitleLarge,
                          fontWeight: MedRushTheme.fontWeightBold,
                          color: MedRushTheme.textPrimary,
                        ),
                      ),
                      if (widget.ruta.nombre != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.ruta.nombre!,
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                            fontWeight: MedRushTheme.fontWeightMedium,
                            color: MedRushTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    color: MedRushTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MedRushTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la ruta en formato compacto
                  Container(
                    padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: MedRushTheme.backgroundSecondary,
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusLg),
                      border: Border.all(color: MedRushTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        // Primera fila: Nombre y Estado
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCompacta(
                                LucideIcons.route,
                                AppLocalizations.of(context).name,
                                widget.ruta.nombre ?? AppLocalizations.of(context).noName,
                              ),
                            ),
                            const SizedBox(width: MedRushTheme.spacingMd),
                            Expanded(
                              child: _buildInfoCompacta(
                                widget.ruta.fechaCompletado == null
                                    ? LucideIcons.truck
                                    : LucideIcons.check,
                                AppLocalizations.of(context).statusShort,
                                widget.ruta.fechaCompletado == null
                                    ? AppLocalizations.of(context).active
                                    : AppLocalizations.of(context).completed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MedRushTheme.spacingSm),

                        // Segunda fila: Repartidor y Distancia/Tiempo
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCompacta(
                                LucideIcons.user,
                                AppLocalizations.of(context).driverLabel,
                                widget.ruta.repartidor?['nombre']?.toString() ??
                                    AppLocalizations.of(context).unknown,
                              ),
                            ),
                            const SizedBox(width: MedRushTheme.spacingMd),
                            if (widget.ruta.distanciaTotalEstimada != null)
                              Expanded(
                                child: _buildInfoCompacta(
                                  LucideIcons.mapPin,
                                  AppLocalizations.of(context).distanceLabel,
                                  StatusHelpers.formatearDistanciaKm(
                                      widget.ruta.distanciaTotalEstimada!),
                                ),
                              ),
                          ],
                        ),
                        if (widget.ruta.tiempoTotalEstimado != null) ...[
                          const SizedBox(height: MedRushTheme.spacingSm),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCompacta(
                                  LucideIcons.clock,
                                  AppLocalizations.of(context).estimatedTimeLabel,
                                  StatusHelpers.formatearTiempo(
                                      widget.ruta.tiempoTotalEstimado!),
                                ),
                              ),
                              const SizedBox(width: MedRushTheme.spacingMd),
                              const Expanded(child: SizedBox()), // Espaciador
                            ],
                          ),
                        ],

                        // Información adicional colapsable
                        if (widget.ruta.puntoInicio != null ||
                            widget.ruta.puntoFinal != null ||
                            widget.ruta.createdAt != null) ...[
                          const SizedBox(height: MedRushTheme.spacingSm),
                          Theme(
                            data: Theme.of(context).copyWith(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              title: Text(
                                AppLocalizations.of(context).additionalDetailsLabel,
                                style: const TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodySmall,
                                  fontWeight: MedRushTheme.fontWeightMedium,
                                  color: MedRushTheme.textSecondary,
                                ),
                              ),
                              childrenPadding: EdgeInsets.zero,
                              tilePadding: EdgeInsets.zero,
                              collapsedShape: const Border(),
                              shape: const Border(),
                              backgroundColor: Colors.transparent,
                              collapsedBackgroundColor: Colors.transparent,
                              iconColor: MedRushTheme.primaryGreen,
                              collapsedIconColor: MedRushTheme.textSecondary,
                              children: [
                                if (widget.ruta.puntoInicio != null)
                                  _buildInfoCompacta(
                                    LucideIcons.mapPin,
                                    AppLocalizations.of(context).startPointLabel,
                                    (widget.ruta.puntoInicio!['latitude'] !=
                                                null &&
                                            widget.ruta.puntoInicio![
                                                    'longitude'] !=
                                                null)
                                        ? StatusHelpers
                                            .formatearCoordenadasAltaPrecision(
                                                (widget.ruta.puntoInicio![
                                                        'latitude'] as num)
                                                    .toDouble(),
                                                (widget.ruta.puntoInicio![
                                                        'longitude'] as num)
                                                    .toDouble())
                                        : 'N/A',
                                  ),
                                if (widget.ruta.puntoFinal != null)
                                  _buildInfoCompacta(
                                    LucideIcons.flag,
                                    AppLocalizations.of(context).endPointLabel,
                                    (widget.ruta.puntoFinal!['latitude'] !=
                                                null &&
                                            widget.ruta
                                                    .puntoFinal!['longitude'] !=
                                                null)
                                        ? StatusHelpers
                                            .formatearCoordenadasAltaPrecision(
                                                (widget.ruta.puntoFinal![
                                                        'latitude'] as num)
                                                    .toDouble(),
                                                (widget.ruta.puntoFinal![
                                                        'longitude'] as num)
                                                    .toDouble())
                                        : 'N/A',
                                  ),
                                if (widget.ruta.createdAt != null)
                                  _buildInfoCompacta(
                                    LucideIcons.calendar,
                                    AppLocalizations.of(context).creationDateLabel,
                                    StatusHelpers.formatearFechaCompleta(
                                        widget.ruta.createdAt!),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Mostrar lista de pedidos detallados si existen
                  if (_pedidosDetallados.isNotEmpty) ...[
                    const SizedBox(height: MedRushTheme.spacingLg),

                    // Header de pedidos mejorado
                    Container(
                      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: MedRushTheme.backgroundSecondary,
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                        border: Border.all(color: MedRushTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(MedRushTheme.spacingSm),
                            decoration: BoxDecoration(
                              color: MedRushTheme.primaryGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  MedRushTheme.borderRadiusSm),
                            ),
                            child: const Icon(
                              LucideIcons.package,
                              size: 20,
                              color: MedRushTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: MedRushTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).routeOrdersTitle,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeTitleMedium,
                                    fontWeight: MedRushTheme.fontWeightBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppLocalizations.of(context).ordersInOptimizedOrderCount(_pedidosDetallados.length),
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodySmall,
                                    fontWeight: MedRushTheme.fontWeightMedium,
                                    color: MedRushTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isRefreshing ? null : _refrescarPedidos,
                            icon: _isRefreshing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        MedRushTheme.primaryGreen,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons.refreshCw,
                                    size: 18,
                                    color: MedRushTheme.primaryGreen,
                                  ),
                            tooltip: AppLocalizations.of(context).refreshOrdersTooltip,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: MedRushTheme.spacingMd),

                    // Lista de pedidos compacta con ExpansionTiles
                    ..._pedidosDetallados.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pedido = entry.value;
                      return _buildPedidoCompactoItem(pedido, index + 1);
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCompacta(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: MedRushTheme.primaryGreen,
            ),
            const SizedBox(width: MedRushTheme.spacingXs),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightMedium,
                  color: MedRushTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            fontWeight: MedRushTheme.fontWeightBold,
            color: MedRushTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRowCompactaConColor(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: MedRushTheme.spacingXs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightMedium,
                  color: MedRushTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPedidoCompactoItem(Map<String, dynamic> pedido, int orden) {
    final estado = pedido['estado'] as String?;
    final estadoColor = _getEstadoColor(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: MedRushTheme.spacingMd,
          vertical: MedRushTheme.spacingXs,
        ),
        childrenPadding: const EdgeInsets.only(
          left: MedRushTheme.spacingMd,
          right: MedRushTheme.spacingMd,
          bottom: MedRushTheme.spacingMd,
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: estadoColor,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
          ),
          child: Center(
            child: Text(
              '$orden',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                fontWeight: MedRushTheme.fontWeightBold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            const Icon(
              LucideIcons.user,
              size: 16,
              color: MedRushTheme.primaryGreen,
            ),
            const SizedBox(width: MedRushTheme.spacingXs),
            Expanded(
              child: Text(
                pedido['paciente_nombre'] ?? AppLocalizations.of(context).clientNotSpecified,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(
                LucideIcons.package,
                size: 12,
                color: MedRushTheme.textSecondary,
              ),
              const SizedBox(width: MedRushTheme.spacingXs),
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context).orderIdShort}${pedido['id'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          // Información detallada del pedido
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(MedRushTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado del pedido
                if (estado != null) ...[
                  _buildInfoRowCompactaConColor(
                    StatusHelpers.iconoPorEstadoPedidoString(estado),
                    AppLocalizations.of(context).statusShort,
                    StatusHelpers.estadoPedidoTextoString(estado, AppLocalizations.of(context)),
                    estadoColor,
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                ],
                if (pedido['direccion_entrega_linea_1'] != null) ...[
                  _buildInfoRowCompacta(
                    LucideIcons.mapPin,
                    AppLocalizations.of(context).address,
                    pedido['direccion_entrega_linea_1'],
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                ],
                if (pedido['ubicacion_recojo'] != null) ...[
                  _buildInfoRowCompacta(
                    LucideIcons.building,
                    AppLocalizations.of(context).pickupLocationLabel,
                    (pedido['ubicacion_recojo']['latitude'] != null &&
                            pedido['ubicacion_recojo']['longitude'] != null)
                        ? StatusHelpers.formatearCoordenadasAltaPrecision(
                            (pedido['ubicacion_recojo']['latitude'] as num)
                                .toDouble(),
                            (pedido['ubicacion_recojo']['longitude'] as num)
                                .toDouble())
                        : 'N/A',
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                ],
                if (pedido['ubicacion_entrega'] != null) ...[
                  _buildInfoRowCompacta(
                    LucideIcons.mapPin,
                    AppLocalizations.of(context).deliveryLocationLabel,
                    (pedido['ubicacion_entrega']['latitude'] != null &&
                            pedido['ubicacion_entrega']['longitude'] != null)
                        ? StatusHelpers.formatearCoordenadasAltaPrecision(
                            (pedido['ubicacion_entrega']['latitude'] as num)
                                .toDouble(),
                            (pedido['ubicacion_entrega']['longitude'] as num)
                                .toDouble())
                        : 'N/A',
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                ],
                if (pedido['tipo_pedido'] != null) ...[
                  _buildInfoRowCompacta(
                    LucideIcons.package,
                    AppLocalizations.of(context).typeLabel,
                    pedido['tipo_pedido'].toString(),
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                ],
                if (pedido['observaciones'] != null &&
                    pedido['observaciones'].toString().isNotEmpty) ...[
                  _buildInfoRowCompacta(
                    LucideIcons.messageSquare,
                    AppLocalizations.of(context).observations,
                    pedido['observaciones'].toString(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowCompacta(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            icon,
            size: 12,
            color: MedRushTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: MedRushTheme.spacingXs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightMedium,
                  color: MedRushTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(String? estado) {
    if (estado == null) {
      return MedRushTheme.textSecondary;
    }

    // Mapear string a enum para usar StatusHelpers
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return StatusHelpers.estadoPedidoColor(EstadoPedido.pendiente);
      case 'asignado':
        return StatusHelpers.estadoPedidoColor(EstadoPedido.asignado);
      case 'recogido':
        return StatusHelpers.estadoPedidoColor(EstadoPedido.recogido);
      case 'en_ruta':
        return StatusHelpers.estadoPedidoColor(EstadoPedido.enRuta);
      case 'entregado':
        return StatusHelpers.estadoPedidoColor(EstadoPedido.entregado);
      case 'cancelado':
        return StatusHelpers.estadoPedidoColor(EstadoPedido.cancelado);
      case 'fallido':
        return StatusHelpers.estadoPedidoColor(EstadoPedido.fallido);
      default:
        return MedRushTheme.textSecondary;
    }
  }

  Future<void> _refrescarPedidos() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final result = await _rutaRepository.obtenerPedidosRuta(
        rutaId: widget.ruta.id,
      );

      if (mounted) {
        setState(() {
          _pedidosDetallados = result.data ?? [];
          _isRefreshing = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).ordersUpdatedSuccess),
              backgroundColor: MedRushTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context).errorUpdatingOrders}: ${result.error}'),
              backgroundColor: MedRushTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorUpdatingOrders}: ${e.toString()}'),
            backgroundColor: MedRushTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            ),
          ),
        );
      }
    }
  }
}

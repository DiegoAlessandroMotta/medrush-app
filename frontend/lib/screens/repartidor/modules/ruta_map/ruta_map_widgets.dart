import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/services/polyline_decoding.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';

// Convierte duraciones de Google (en inglés) a formato español breve
String _toSpanishDuration(String durationText) {
  var t = durationText.toLowerCase();
  t = t
      .replaceAll('hours', 'h')
      .replaceAll('hour', 'h')
      .replaceAll('hrs', 'h')
      .replaceAll('hr', 'h')
      .replaceAll('minutes', 'min')
      .replaceAll('minute', 'min')
      .replaceAll('mins', 'min')
      .replaceAll('min', 'min')
      .replaceAll('days', 'd')
      .replaceAll('day', 'd')
      .replaceAll('secs', 's')
      .replaceAll('sec', 's');
  t = t.replaceAll('m', 'min');
  t = t.replaceAll('  ', ' ');
  return t.trim();
}

class RutaMapList extends StatelessWidget {
  final List<Pedido> rutaOptimizada;
  final List<Pedido> pedidosEnCola;
  final Set<String> pedidosConPolyline;
  final Map<String, LegInfo> legInfoByPedidoId;
  final Function(Pedido) onCardTap;
  final Function(Pedido) onFocusPedido;
  final Function(Pedido) onNavegarAEntrega;
  final Function(Pedido) onVerDetallePedido;
  final Function(Pedido) onChangeOrder;
  final Function() onReOptimizarRuta;
  final Function(Pedido) formatDistanceFromMe;

  const RutaMapList({
    super.key,
    required this.rutaOptimizada,
    required this.pedidosEnCola,
    required this.pedidosConPolyline,
    required this.legInfoByPedidoId,
    required this.onCardTap,
    required this.onFocusPedido,
    required this.onNavegarAEntrega,
    required this.onVerDetallePedido,
    required this.onChangeOrder,
    required this.onReOptimizarRuta,
    required this.formatDistanceFromMe,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MedRushTheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: MedRushTheme.spacingSm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón de re-optimización
                IconButton(
                  onPressed: onReOptimizarRuta,
                  icon: const Icon(
                    LucideIcons.refreshCw,
                    color: MedRushTheme.primaryBlue,
                    size: 20,
                  ),
                  tooltip: 'Re-optimizar ruta',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        MedRushTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Título y contador
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.truck,
                      color: MedRushTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: MedRushTheme.spacingSm),
                    const Text(
                      'Entregas programadas',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeTitleSmall,
                        fontWeight: MedRushTheme.fontWeightBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: MedRushTheme.spacingSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MedRushTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${rutaOptimizada.length}',
                        style: const TextStyle(
                          color: MedRushTheme.textInverse,
                          fontSize: MedRushTheme.fontSizeBodySmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Espacio para balancear el layout
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: MedRushTheme.spacingSm),
            Expanded(
              child: ListView.builder(
                itemCount: rutaOptimizada.length,
                itemBuilder: (context, index) {
                  final pedido = rutaOptimizada[index];
                  final tienePolyline = pedidosConPolyline.contains(pedido.id);
                  return _buildEntregaItem(pedido, index + 1,
                      isActive: tienePolyline);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene el icono de navegación (siempre el mismo)
  IconData _getNavigationIcon(EstadoPedido estado) {
    return LucideIcons.navigation; // Siempre el mismo icono de navegación
  }

  /// Obtiene el color de navegación según el estado del pedido
  Color _getNavigationColor(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return MedRushTheme.statusPending; // #FFA000 - Amarillo
      case EstadoPedido.asignado:
        return MedRushTheme.primaryBlue; // #006BBA - Azul principal
      case EstadoPedido.recogido:
        return const Color(0xFF9C27B0); // #9C27B0 - Morado
      case EstadoPedido.enRuta:
        return MedRushTheme.primaryGreen; // #5F9041 - Verde asparagus
      case EstadoPedido.entregado:
        return MedRushTheme.primaryGreenLight; // #7CB459 - Verde claro
      case EstadoPedido.fallido:
        return MedRushTheme.statusFailed; // #D32F2F - Rojo
      case EstadoPedido.cancelado:
        return MedRushTheme.statusCancelled; // #757575 - Gris
    }
  }

  /// Obtiene el tooltip de navegación según el estado del pedido
  String _getNavigationTooltip(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'Navegar a recogida';
      case EstadoPedido.asignado:
        return 'Navegar a punto de recogida';
      case EstadoPedido.recogido:
        return 'Navegar a punto de entrega';
      case EstadoPedido.enRuta:
        return 'Navegar a punto de entrega';
      case EstadoPedido.entregado:
        return 'Pedido entregado';
      case EstadoPedido.fallido:
        return 'Pedido fallido';
      case EstadoPedido.cancelado:
        return 'Pedido cancelado';
    }
  }

  Widget _buildEntregaItem(Pedido pedido, int orden, {bool isActive = true}) {
    final info = legInfoByPedidoId[pedido.id];

    return Card(
      margin: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onCardTap(pedido),
        onLongPress: () => onFocusPedido(pedido),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MedRushTheme.spacingMd,
            vertical: MedRushTheme.spacingSm,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Círculo de orden más pequeño
                  InkWell(
                    onTap: () => onFocusPedido(pedido),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? StatusHelpers.estadoPedidoColor(pedido.estado)
                            : const Color(0xFF757575),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isActive
                                    ? StatusHelpers.estadoPedidoColor(
                                        pedido.estado)
                                    : const Color(0xFF757575))
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          orden.toString(),
                          style: const TextStyle(
                            color: MedRushTheme.textInverse,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MedRushTheme.spacingMd),
                  // Contenido principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del paciente en negrita
                        Text(
                          pedido.pacienteNombre,
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeTitleMedium,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? MedRushTheme.textPrimary
                                : MedRushTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Badge de estado solo para pedidos en cola
                        if (!isActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF757575),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'En Cola',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        // Información de recogida: mostrar km y ETA en lugar de coordenadas
                        if (pedido.latitudRecojo != null &&
                            pedido.longitudRecojo != null) ...[
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.package,
                                size: 12,
                                color:
                                    Color(0xFF9C27B0), // Morado para recogida
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Recoger en: ',
                                style: TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodyMedium,
                                  fontWeight: FontWeight.w500,
                                  color: MedRushTheme.textSecondary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  info != null
                                      ? info.distanceText
                                      : 'Ruta no disponible',
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodyMedium,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9C27B0),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        // Información de tiempo
                        if (info != null) ...[
                          // Tiempo del siguiente segmento
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: MedRushTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_toSpanishDuration(info.durationText)} (${_getTimeLabel(pedido.estado)})',
                                style: const TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodyMedium,
                                  fontWeight: FontWeight.w500,
                                  color: MedRushTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Tiempo acumulativo total (azul - destacado)
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.timer,
                                size: 12,
                                color: MedRushTheme.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_toSpanishDuration(info.cumulativeDurationText)} (total)',
                                style: const TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodyMedium,
                                  fontWeight: FontWeight.bold,
                                  color: MedRushTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Dirección de entrega
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: MedRushTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pedido.direccionEntrega,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodyMedium,
                                    color: MedRushTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Solo dirección si no hay info de ruta
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: MedRushTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pedido.direccionEntrega,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodyMedium,
                                    color: MedRushTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: MedRushTheme.spacingSm),
                  // Botones de acción
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => onNavegarAEntrega(pedido),
                        icon: Icon(
                          _getNavigationIcon(pedido.estado),
                          color: _getNavigationColor(pedido.estado),
                          size: 20,
                        ),
                        tooltip: _getNavigationTooltip(pedido.estado),
                        style: IconButton.styleFrom(
                          backgroundColor: _getNavigationColor(pedido.estado)
                              .withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        onPressed: () => onVerDetallePedido(pedido),
                        icon: const Icon(
                          LucideIcons.eye,
                          color: MedRushTheme.primaryGreen,
                          size: 20,
                        ),
                        tooltip: 'Ver detalles',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Obtiene la etiqueta del tiempo según el estado del pedido
  String _getTimeLabel(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.asignado:
      case EstadoPedido.pendiente:
        return 'a recogida';
      case EstadoPedido.recogido:
      case EstadoPedido.enRuta:
        return 'a entrega';
      case EstadoPedido.entregado:
      case EstadoPedido.fallido:
      case EstadoPedido.cancelado:
        return 'completado';
    }
  }
}

/// Widget para mostrar el carousel de pedidos en la parte inferior del mapa
class RutaMapCarousel extends StatelessWidget {
  final List<Pedido> rutaOptimizada;
  final Map<String, LegInfo> legInfoByPedidoId;
  final Function(Pedido) onCardTap;
  final Function(Pedido) onFocusMeAndPedido;
  final Function(Pedido) onNavegarAEntrega;
  final Function(Pedido) formatDistanceFromMe;

  const RutaMapCarousel({
    super.key,
    required this.rutaOptimizada,
    required this.legInfoByPedidoId,
    required this.onCardTap,
    required this.onFocusMeAndPedido,
    required this.onNavegarAEntrega,
    required this.formatDistanceFromMe,
  });

  @override
  Widget build(BuildContext context) {
    // Mostrar pedidos activos (con polyline) en el carousel - hasta 25 pedidos
    final items = rutaOptimizada.take(24).toList();
    return SizedBox(
      height: 80,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: items.length,
        padEnds: false,
        itemBuilder: (context, index) {
          final pedido = items[index];
          return RutaMapCompactCard(
            pedido: pedido,
            orden: index + 1,
            legInfo: legInfoByPedidoId[pedido.id],
            onCardTap: onCardTap,
            onFocusMeAndPedido: onFocusMeAndPedido,
            onNavegarAEntrega: onNavegarAEntrega,
            formatDistanceFromMe: formatDistanceFromMe,
          );
        },
      ),
    );
  }
}

/// Widget para mostrar una tarjeta compacta de pedido en el carousel
class RutaMapCompactCard extends StatelessWidget {
  final Pedido pedido;
  final int orden;
  final LegInfo? legInfo;
  final Function(Pedido) onCardTap;
  final Function(Pedido) onFocusMeAndPedido;
  final Function(Pedido) onNavegarAEntrega;
  final Function(Pedido) formatDistanceFromMe;

  const RutaMapCompactCard({
    super.key,
    required this.pedido,
    required this.orden,
    this.legInfo,
    required this.onCardTap,
    required this.onFocusMeAndPedido,
    required this.onNavegarAEntrega,
    required this.formatDistanceFromMe,
  });

  /// Obtiene el icono de navegación (siempre el mismo)
  IconData _getNavigationIcon(EstadoPedido estado) {
    return LucideIcons.navigation; // Siempre el mismo icono de navegación
  }

  /// Obtiene el color de navegación según el estado del pedido
  Color _getNavigationColor(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return MedRushTheme.statusPending; // #FFA000 - Amarillo
      case EstadoPedido.asignado:
        return MedRushTheme.primaryBlue; // #006BBA - Azul principal
      case EstadoPedido.recogido:
        return const Color(0xFF9C27B0); // #9C27B0 - Morado
      case EstadoPedido.enRuta:
        return MedRushTheme.primaryGreen; // #5F9041 - Verde asparagus
      case EstadoPedido.entregado:
        return MedRushTheme.primaryGreenLight; // #7CB459 - Verde claro
      case EstadoPedido.fallido:
        return MedRushTheme.statusFailed; // #D32F2F - Rojo
      case EstadoPedido.cancelado:
        return MedRushTheme.statusCancelled; // #757575 - Gris
    }
  }

  /// Obtiene el tooltip de navegación según el estado del pedido
  String _getNavigationTooltip(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return 'Navegar a recogida';
      case EstadoPedido.asignado:
        return 'Navegar a punto de recogida';
      case EstadoPedido.recogido:
        return 'Navegar a punto de entrega';
      case EstadoPedido.enRuta:
        return 'Navegar a punto de entrega';
      case EstadoPedido.entregado:
        return 'Pedido entregado';
      case EstadoPedido.fallido:
        return 'Pedido fallido';
      case EstadoPedido.cancelado:
        return 'Pedido cancelado';
    }
  }

  /// Obtiene la dirección de recogida formateada para el carousel (más compacta)
  String _getDireccionRecojoCompact(Pedido pedido) {
    // Si hay coordenadas de recogida, mostrar coordenadas formateadas más cortas
    if (pedido.latitudRecojo != null && pedido.longitudRecojo != null) {
      return StatusHelpers.formatearCoordenadas(
          pedido.latitudRecojo!, pedido.longitudRecojo!,
          decimales: 3);
    }
    return 'N/A';
  }

  /// Obtiene la etiqueta del tiempo según el estado del pedido
  String _getTimeLabel(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.asignado:
      case EstadoPedido.pendiente:
        return 'a recogida';
      case EstadoPedido.recogido:
      case EstadoPedido.enRuta:
        return 'a entrega';
      case EstadoPedido.entregado:
      case EstadoPedido.fallido:
      case EstadoPedido.cancelado:
        return 'completado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String paciente = pedido.pacienteNombre;
    final String direccion = (pedido.direccionEntrega.isNotEmpty)
        ? pedido.direccionEntrega
        : (pedido.latitudEntrega != null && pedido.longitudEntrega != null)
            ? StatusHelpers.formatearCoordenadas(
                pedido.latitudEntrega!, pedido.longitudEntrega!,
                decimales: 5)
            : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => onCardTap(pedido),
        onLongPress: () => onFocusMeAndPedido(pedido),
        child: Container(
          decoration: BoxDecoration(
            color: MedRushTheme.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border(
              left: BorderSide(
                color: StatusHelpers.estadoPedidoColor(pedido.estado),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MedRushTheme.spacingMd,
            vertical: 4,
          ),
          child: Row(
            children: [
              // Eliminado: franja interna que ocupaba espacio
              // const SizedBox(width: MedRushTheme.spacingMd),
              CircleAvatar(
                radius: 16,
                backgroundColor: StatusHelpers.estadoPedidoColor(pedido.estado),
                child: Text(
                  orden.toString(),
                  style: const TextStyle(
                    color: MedRushTheme.textInverse,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: MedRushTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nombre del paciente en negrita
                    Text(
                      paciente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        fontWeight: FontWeight.bold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                    // Información de recogida (si está disponible) - más compacta
                    if (pedido.latitudRecojo != null &&
                        pedido.longitudRecojo != null) ...[
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.package,
                            size: 8,
                            color: Color(0xFF9C27B0), // Morado para recogida
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'Recoger: ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: MedRushTheme.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getDireccionRecojoCompact(pedido),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color:
                                    Color(0xFF9C27B0), // Morado para recogida
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Información de tiempo y dirección (más compacta)
                    if (legInfo != null) ...[
                      // Tiempo siguiente (gris) - más pequeño
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 8,
                            color: MedRushTheme.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${_toSpanishDuration(legInfo!.durationText)} (${_getTimeLabel(pedido.estado)})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: MedRushTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Dirección de entrega debajo del tiempo - más pequeña
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 8,
                            color: MedRushTheme.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              direccion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: MedRushTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Solo dirección si no hay info de ruta - más pequeña
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 8,
                            color: MedRushTheme.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              direccion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: MedRushTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              // Solo botón de navegación
              IconButton(
                onPressed: () => onNavegarAEntrega(pedido),
                icon: Icon(
                  _getNavigationIcon(pedido.estado),
                  color: _getNavigationColor(pedido.estado),
                  size: 16,
                ),
                tooltip: _getNavigationTooltip(pedido.estado),
                style: IconButton.styleFrom(
                  backgroundColor:
                      _getNavigationColor(pedido.estado).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(28, 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

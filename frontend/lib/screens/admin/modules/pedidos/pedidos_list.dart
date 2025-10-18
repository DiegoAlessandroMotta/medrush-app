import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidosTableView extends StatelessWidget {
  final List<Pedido> pedidos;
  final VoidCallback onRefresh;
  final Function(Pedido) onEdit;
  final Function(Pedido) onView;
  final Function(Pedido) onDelete;
  final bool isLoading;

  const PedidosTableView({
    super.key,
    required this.pedidos,
    required this.onRefresh,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        border: Border.all(color: MedRushTheme.borderLight),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la tabla
          _buildTableHeader(),
          // Contenido de la tabla
          Expanded(
            child: _buildTableContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      decoration: const BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(MedRushTheme.borderRadiusLg),
          topRight: Radius.circular(MedRushTheme.borderRadiusLg),
        ),
      ),
      child: Row(
        children: [
          // N° PEDIDO
          Expanded(
            child: _buildHeaderCell('N° PEDIDO'),
          ),
          // Espacio entre N° PEDIDO y CLIENTE
          const SizedBox(width: MedRushTheme.spacingSm),
          // CLIENTE
          Expanded(
            flex: 2,
            child: _buildHeaderCell('CLIENTE'),
          ),
          // DIRECCIÓN
          Expanded(
            flex: 2,
            child: _buildHeaderCell('DIRECCIÓN'),
          ),
          // REPARTIDOR
          Expanded(
            child: _buildHeaderCell('REPARTIDOR'),
          ),
          // UBICACIÓN
          SizedBox(
            width: 140,
            child: _buildHeaderCell('UBICACIÓN'),
          ),
          // ESTADO
          SizedBox(
            width: 100,
            child: _buildHeaderCell('ESTADO'),
          ),
          // FECHA
          SizedBox(
            width: 120,
            child: _buildHeaderCell('FECHA'),
          ),
          // ACCIONES
          Expanded(
            child: _buildCenteredHeaderCell('ACCIONES'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: MedRushTheme.textPrimary,
        fontSize: MedRushTheme.fontSizeBodySmall,
        fontWeight: MedRushTheme.fontWeightBold,
      ),
    );
  }

  Widget _buildCenteredHeaderCell(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          color: MedRushTheme.textPrimary,
          fontSize: MedRushTheme.fontSizeBodySmall,
          fontWeight: MedRushTheme.fontWeightBold,
        ),
      ),
    );
  }

  Widget _buildTableContent() {
    if (isLoading) {
      return _buildShimmerLoading();
    }

    if (pedidos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(MedRushTheme.spacingLg),
          child: Text(
            'No hay pedidos para mostrar',
            style: TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return _buildTableRow(pedido, index);
      },
    );
  }

  Widget _buildTableRow(Pedido pedido, int index) {
    final isEven = index % 2 == 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isEven ? MedRushTheme.surface : MedRushTheme.backgroundSecondary,
        border: const Border(
          bottom: BorderSide(
            color: MedRushTheme.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MedRushTheme.spacingMd),
        child: Row(
          children: [
            // N° PEDIDO
            Expanded(
              child: Text(
                '#${pedido.id}',
                style: const TextStyle(
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightMedium,
                ),
              ),
            ),
            // Espacio entre N° PEDIDO y CLIENTE
            const SizedBox(width: MedRushTheme.spacingSm),
            // CLIENTE
            Expanded(
              flex: 2,
              child: Text(
                pedido.pacienteNombre,
                style: const TextStyle(
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightSemiBold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // DIRECCIÓN
            Expanded(
              flex: 2,
              child: Text(
                _getDireccionText(pedido),
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // REPARTIDOR
            Expanded(
              child: _buildRepartidorCell(pedido),
            ),
            // UBICACIÓN
            SizedBox(
              width: 140,
              child: _buildUbicacionCell(pedido),
            ),
            // ESTADO
            SizedBox(
              width: 100,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: _buildStatusBadge(pedido.estado),
              ),
            ),
            // FECHA
            SizedBox(
              width: 120,
              child: _buildFechaCell(pedido),
            ),
            // ACCIONES
            Expanded(
              child: Center(child: _buildActionButtons(pedido)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EstadoPedido estado) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingSm,
        vertical: MedRushTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: StatusHelpers.estadoPedidoColor(estado),
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de estado dentro del container
          Icon(
            StatusHelpers.estadoPedidoIcon(estado),
            color: MedRushTheme.textInverse,
            size: 12,
          ),
          const SizedBox(width: MedRushTheme.spacingXs),
          // Texto del estado
          Text(
            StatusHelpers.estadoPedidoTexto(estado),
            style: const TextStyle(
              color: MedRushTheme.textInverse,
              fontSize: MedRushTheme.fontSizeLabelSmall,
              fontWeight: MedRushTheme.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Pedido pedido) {
    final bool esPendiente = pedido.estado == EstadoPedido.pendiente;
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón principal: Asignar si pendiente, de lo contrario Ver
          IconButton(
            icon: Icon(
              esPendiente ? LucideIcons.userPlus : LucideIcons.eye,
              color: MedRushTheme.primaryGreen,
              size: 18,
            ),
            onPressed: () async {
              if (esPendiente) {
                await _showAsignarRepartidorDialog(context, pedido);
              } else {
                onView(pedido);
              }
            },
            tooltip: esPendiente ? 'Asignar repartidor' : 'Ver detalles',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          // Segundo botón: si es pendiente -> Ver; si no -> Editar
          IconButton(
            icon: Icon(
              esPendiente ? LucideIcons.eye : LucideIcons.pencil,
              color: MedRushTheme.primaryGreen,
              size: 18,
            ),
            onPressed: () {
              if (esPendiente) {
                onView(pedido);
              } else {
                onEdit(pedido);
              }
            },
            tooltip: esPendiente ? 'Ver detalles' : 'Editar',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          // Menú desplegable con más opciones
          PopupMenuButton<String>(
            icon: const Icon(
              LucideIcons.ellipsis,
              color: MedRushTheme.textSecondary,
              size: 18,
            ),
            tooltip: 'Más opciones',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            onSelected: (String value) async {
              switch (value) {
                case 'assign':
                  await _showAsignarRepartidorDialog(context, pedido);
                case 'edit':
                  onEdit(pedido);
                case 'cancelar':
                  await _showCancelarPedidoDialog(context, pedido);
                case 'fallo':
                  await _showMarcarFalloDialog(context, pedido);
                case 'barcode':
                  _showBarcodeDialog(context, pedido);
                case 'delete':
                  _showDeleteConfirmation(context, pedido);
              }
            },
            itemBuilder: (BuildContext context) => [
              if (esPendiente)
                const PopupMenuItem<String>(
                  value: 'assign',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.userPlus,
                        color: MedRushTheme.neutralGrey700,
                        size: 16,
                      ),
                      SizedBox(width: MedRushTheme.spacingSm),
                      Text('Asignar Repartidor'),
                    ],
                  ),
                ),
              // Cancelar (solo si está asignado)
              if (pedido.estado == EstadoPedido.asignado)
                const PopupMenuItem<String>(
                  value: 'cancelar',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.x,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: MedRushTheme.spacingSm),
                      Text('Cancelar Pedido'),
                    ],
                  ),
                ),
              // Editar (siempre visible)
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.pencil,
                      color: MedRushTheme.neutralGrey700,
                      size: 16,
                    ),
                    SizedBox(width: MedRushTheme.spacingSm),
                    Text('Editar'),
                  ],
                ),
              ),
              // Opciones para pedidos recogidos y en ruta (pueden ser fallidos)
              if ((pedido.estado == EstadoPedido.recogido ||
                      pedido.estado == EstadoPedido.enRuta) &&
                  pedido.estado != EstadoPedido.entregado &&
                  pedido.estado != EstadoPedido.fallido &&
                  pedido.estado != EstadoPedido.cancelado) ...[
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'cancelar',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.x,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: MedRushTheme.spacingSm),
                      Text('Cancelar Pedido'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'fallo',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.badgeAlert,
                        color: Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: MedRushTheme.spacingSm),
                      Text('Marcar como Fallido'),
                    ],
                  ),
                ),
              ],
              const PopupMenuItem<String>(
                value: 'barcode',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.barcode,
                      color: MedRushTheme.neutralGrey700,
                      size: 16,
                    ),
                    SizedBox(width: MedRushTheme.spacingSm),
                    Text('Generar Código de Barras'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.trash2,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: MedRushTheme.spacingSm),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDireccionText(Pedido pedido) {
    // Mostrar dirección principal y distrito
    return '${pedido.direccionEntrega}, ${pedido.distritoEntrega}';
  }

  Widget _buildRepartidorCell(Pedido pedido) {
    // FIX: Mostrar nombre del repartidor con icono de verificado si aplica
    if (pedido.repartidor != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pedido.repartidor!.nombre,
            style: const TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodySmall,
              fontWeight: MedRushTheme.fontWeightSemiBold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (pedido.repartidor!.verificado) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.check,
              color: MedRushTheme.primaryGreen,
              size: 14,
            ),
          ],
        ],
      );
    }
    return Text(
      pedido.repartidorId != null ? 'Asignado' : 'Sin asignar',
      style: const TextStyle(
        color: MedRushTheme.textSecondary,
        fontSize: MedRushTheme.fontSizeBodySmall,
        fontWeight: MedRushTheme.fontWeightSemiBold,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getUbicacionText(Pedido pedido) {
    // Mostrar coordenadas si están disponibles
    if (pedido.latitudEntrega != null && pedido.longitudEntrega != null) {
      return StatusHelpers.formatearCoordenadasEstandar(
          pedido.latitudEntrega!, pedido.longitudEntrega!);
    }
    return 'No disponible';
  }

  /// Obtiene la fecha correspondiente según el estado del pedido
  /// Usa el sistema de prioridad centralizado de StatusHelpers
  String _getFechaSegunEstado(Pedido pedido) {
    return StatusHelpers.obtenerFechaSegunPrioridad(pedido);
  }

  Widget _buildFechaCell(Pedido pedido) {
    final fechaTexto = _getFechaSegunEstado(pedido);
    final tipoFecha = StatusHelpers.obtenerTipoFechaMostrada(pedido);

    return Tooltip(
      message: 'Fecha de $tipoFecha',
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      textStyle: const TextStyle(
        color: MedRushTheme.textPrimary,
        fontSize: MedRushTheme.fontSizeBodySmall,
        fontWeight: MedRushTheme.fontWeightMedium,
      ),
      child: Text(
        fechaTexto,
        style: const TextStyle(
          color: MedRushTheme.textSecondary,
          fontSize: MedRushTheme.fontSizeBodySmall,
          fontWeight: MedRushTheme.fontWeightMedium,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildUbicacionCell(Pedido pedido) {
    // Si no hay coordenadas, mostrar texto simple
    if (pedido.latitudEntrega == null || pedido.longitudEntrega == null) {
      return const Text(
        'No disponible',
        style: TextStyle(
          color: MedRushTheme.textSecondary,
          fontSize: MedRushTheme.fontSizeBodySmall,
        ),
      );
    }

    // Si hay coordenadas, hacer clickeable para abrir Google Maps
    return InkWell(
      onTap: () =>
          _openGoogleMaps(pedido.latitudEntrega!, pedido.longitudEntrega!),
      borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.mapPin,
            color: MedRushTheme.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              _getUbicacionText(pedido),
              style: const TextStyle(
                color: MedRushTheme.textSecondary,
                fontSize: MedRushTheme.fontSizeBodySmall,
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(double latitud, double longitud) async {
    try {
      // Crear URL para Google Maps
      final url = Uri.parse('https://www.google.com/maps?q=$latitud,$longitud');

      // Verificar si se puede abrir la URL
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: intentar con el esquema de la app de Google Maps
        final fallbackUrl =
            Uri.parse('geo:$latitud,$longitud?q=$latitud,$longitud');
        if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl);
        }
      }
    } catch (e) {
      // Si hay error, mostrar mensaje (opcional)
      debugPrint('Error al abrir Google Maps: $e');
    }
  }

  void _showBarcodeDialog(BuildContext context, Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.barcode,
              color: MedRushTheme.neutralGrey700,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Código de Barras'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pedido #${pedido.id}',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingLg),
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: MedRushTheme.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: MedRushTheme.shadowLight,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Widget real de código de barras
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: pedido.codigoBarra,
                    width: 250,
                    height: 80,
                    color: MedRushTheme.textPrimary,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: MedRushTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MedRushTheme.spacingMd,
                      vertical: MedRushTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: MedRushTheme.backgroundSecondary,
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: Text(
                      pedido.codigoBarra,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        fontWeight: MedRushTheme.fontWeightBold,
                        fontFamily: 'monospace',
                        color: MedRushTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                  const Text(
                    'Código de barras del pedido',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),
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

  void _showDeleteConfirmation(BuildContext context, Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.triangleAlert,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar el pedido #${pedido.id}?',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: MedRushTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer. El pedido será eliminado permanentemente.',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: Colors.red,
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
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePedido(context, pedido);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePedido(BuildContext context, Pedido pedido) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Eliminar pedido usando el repositorio
      final repository = PedidoRepository();
      final result = await repository.eliminarPedido(pedido.id);

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (context.mounted) {
          NotificationService.showSuccess(
            'Pedido #${pedido.id} eliminado exitosamente',
            context: context,
          );
        }

        // Recargar la lista
        onRefresh();
      } else {
        // Mostrar mensaje de error
        if (context.mounted) {
          NotificationService.showError(
            'Error al eliminar pedido: ${result.error}',
            context: context,
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      if (context.mounted) {
        NotificationService.showError(
          'Error al eliminar pedido: $e',
          context: context,
        );
      }
    }
  }

  Future<void> _showAsignarRepartidorDialog(
      BuildContext context, Pedido pedido) async {
    try {
      // Cargar repartidores activos
      final repartidorRepo = RepartidorRepository();
      final res = await repartidorRepo.getRepartidoresActivos();
      final List<Usuario> repartidores = res.data ?? [];

      Usuario? seleccionado;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Asignar Repartidor'),
            content: SizedBox(
              width: 420,
              height: 380,
              child: Column(
                children: [
                  Expanded(
                    child: repartidores.isEmpty
                        ? const Center(
                            child: Text('No hay repartidores activos'))
                        : ListView.builder(
                            itemCount: repartidores.length,
                            itemBuilder: (context, index) {
                              final r = repartidores[index];
                              final isSelected = seleccionado?.id == r.id;
                              return ListTile(
                                leading: _buildRepartidorAvatar(r),
                                title: Text(r.nombre),
                                subtitle: r.telefono != null
                                    ? Text(r.telefono!)
                                    : null,
                                selected: isSelected,
                                onTap: () {
                                  seleccionado = r;
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (seleccionado == null) {
                    Navigator.of(context).pop();
                    return;
                  }
                  final repo = PedidoRepository();
                  final result =
                      await repo.asignarPedido(pedido.id, seleccionado!.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  if (result.success && context.mounted) {
                    NotificationService.showSuccess(
                      'Pedido asignado a ${seleccionado!.nombre}',
                      context: context,
                    );
                    onRefresh();
                  } else if (context.mounted) {
                    NotificationService.showError(
                      'Error al asignar: ${result.error ?? 'Error desconocido'}',
                      context: context,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedRushTheme.primaryGreen,
                  foregroundColor: MedRushTheme.textInverse,
                ),
                child: const Text('Confirmar Asignación'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(
          'Error al cargar repartidores: $e',
          context: context,
        );
      }
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6, // Mostrar 6 filas de shimmer
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: MedRushTheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: MedRushTheme.borderLight,
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              child: Row(
                children: [
                  // N° PEDIDO shimmer
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: MedRushTheme.spacingSm),
                  // CLIENTE shimmer
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // DIRECCIÓN shimmer
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // REPARTIDOR shimmer
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // UBICACIÓN shimmer
                  SizedBox(
                    width: 140,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // ESTADO shimmer
                  SizedBox(
                    width: 100,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // FECHA shimmer
                  SizedBox(
                    width: 120,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // ACCIONES shimmer
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepartidorAvatar(Usuario r) {
    final hasPhoto = r.foto != null && r.foto!.isNotEmpty;
    if (hasPhoto) {
      return CircleAvatar(
        backgroundImage: NetworkImage(r.foto!),
        radius: 18,
      );
    }
    // Fallback: iniciales
    final parts = r.nombre.trim().split(' ');
    final initials =
        parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: MedRushTheme.backgroundSecondary,
      child: Text(
        initials,
        style: const TextStyle(
          color: MedRushTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Muestra el diálogo para cancelar un pedido
  Future<void> _showCancelarPedidoDialog(
      BuildContext context, Pedido pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.x,
              color: Colors.orange,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Cancelar Pedido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas cancelar el pedido #${pedido.id}?',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: MedRushTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Esta acción cambiará el estado del pedido a "Cancelado" y no se podrá revertir.',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: Colors.orange,
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelarPedido(context, pedido);
    }
  }

  /// Cancela un pedido
  Future<void> _cancelarPedido(BuildContext context, Pedido pedido) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Crear repositorio
      final repository = PedidoRepository();

      // Cancelar pedido usando el repositorio
      final result = await repository.cancelarPedido(pedido.id);

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (context.mounted) {
          NotificationService.showSuccess(
            'Pedido #${pedido.id} cancelado exitosamente',
            context: context,
          );
        }

        // Recargar la lista
        onRefresh();
      } else {
        // Mostrar mensaje de error
        if (context.mounted) {
          NotificationService.showError(
            'Error al cancelar pedido: ${result.error}',
            context: context,
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      if (context.mounted) {
        NotificationService.showError(
          'Error al cancelar pedido: $e',
          context: context,
        );
      }
    }
  }

  /// Muestra el diálogo para marcar un pedido como fallido
  Future<void> _showMarcarFalloDialog(
      BuildContext context, Pedido pedido) async {
    MotivoFalla? motivoSeleccionado;
    final TextEditingController observacionesController =
        TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                LucideIcons.badgeAlert,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: MedRushTheme.spacingSm),
              Text('Marcar como Fallido'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el motivo del fallo para el pedido #${pedido.id}',
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingMd),

                // Selector de motivo de fallo
                DropdownButtonFormField<MotivoFalla>(
                  initialValue: motivoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del fallo',
                    border: OutlineInputBorder(),
                  ),
                  items: StatusHelpers.obtenerMotivosFallo().map((motivo) {
                    return DropdownMenuItem<MotivoFalla>(
                      value: motivo,
                      child: Row(
                        children: [
                          Icon(
                            StatusHelpers.motivoFallaIcono(motivo),
                            color: StatusHelpers.motivoFallaColor(motivo),
                            size: 16,
                          ),
                          const SizedBox(width: MedRushTheme.spacingXs),
                          Text(StatusHelpers.motivoFallaTexto(motivo)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (MotivoFalla? value) {
                    setState(() {
                      motivoSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: MedRushTheme.spacingMd),

                // Campo de observaciones
                TextFormField(
                  controller: observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Detalles adicionales sobre el fallo...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: MedRushTheme.spacingMd),

                Container(
                  padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: MedRushTheme.spacingSm),
                      Expanded(
                        child: Text(
                          'Esta acción cambiará el estado del pedido a "Fallido" y registrará la ubicación actual.',
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: motivoSeleccionado != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Fallo'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && motivoSeleccionado != null) {
      await _marcarPedidoFallido(
        context,
        pedido,
        motivoSeleccionado!,
        observacionesController.text.trim(),
      );
    }
  }

  /// Marca un pedido como fallido
  Future<void> _marcarPedidoFallido(
    BuildContext context,
    Pedido pedido,
    MotivoFalla motivo,
    String observaciones,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener ubicación actual (simulada por ahora)
      // TODO: Implementar obtención real de ubicación GPS
      const double latitud = -12.0464; // Lima, Perú
      const double longitud = -77.0428;

      // Crear repositorio
      final repository = PedidoRepository();

      // Marcar como fallido usando el repositorio
      final result = await repository.marcarPedidoFallido(
        pedido.id,
        motivoFallo: StatusHelpers.motivoFallaToBackend(motivo),
        observacionesFallo: observaciones.isNotEmpty ? observaciones : null,
        latitud: latitud,
        longitud: longitud,
      );

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (context.mounted) {
          NotificationService.showSuccess(
            'Pedido #${pedido.id} marcado como fallido',
            context: context,
          );
        }

        // Recargar la lista
        onRefresh();
      } else {
        // Mostrar mensaje de error
        if (context.mounted) {
          NotificationService.showError(
            'Error al marcar pedido como fallido: ${result.error}',
            context: context,
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      if (context.mounted) {
        NotificationService.showError(
          'Error al marcar pedido como fallido: $e',
          context: context,
        );
      }
    }
  }
}

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // import
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/services/location_tracker.dart'; // import
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart'; // import
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/utils/url_launcher_helper.dart';
import 'package:shimmer/shimmer.dart';

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
          _buildTableHeader(context),
          Expanded(
            child: _buildTableContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
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
            child: _buildHeaderCell(AppLocalizations.of(context).orderNumber),
          ),
          const SizedBox(width: MedRushTheme.spacingSm),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(AppLocalizations.of(context).client),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(AppLocalizations.of(context).address),
          ),
          Expanded(
            child: _buildHeaderCell(AppLocalizations.of(context).driver),
          ),
          SizedBox(
            width: 140,
            child: _buildHeaderCell(AppLocalizations.of(context).location),
          ),
          SizedBox(
            width: 100,
            child: _buildHeaderCell(AppLocalizations.of(context).status),
          ),
          SizedBox(
            width: 120,
            child: _buildHeaderCell(AppLocalizations.of(context).date),
          ),
          Expanded(
            child:
                _buildCenteredHeaderCell(AppLocalizations.of(context).actions),
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

  Widget _buildTableContent(BuildContext context) {
    if (isLoading) {
      return _buildShimmerLoading();
    }

    if (pedidos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MedRushTheme.spacingLg),
          child: Text(
            AppLocalizations.of(context).noOrdersToShow,
            style: const TextStyle(
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
        return _buildTableRow(context, pedido, index);
      },
    );
  }

  Widget _buildTableRow(BuildContext context, Pedido pedido, int index) {
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
              child: _buildRepartidorCell(context, pedido),
            ),
            // UBICACIÓN
            SizedBox(
              width: 140,
              child: _buildUbicacionCell(context, pedido),
            ),
            // ESTADO
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(pedido.estado),
              ),
            ),
            // FECHA
            SizedBox(
              width: 120,
              child: _buildFechaCell(context, pedido),
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
          Builder(
            builder: (context) => Text(
              StatusHelpers.estadoPedidoTexto(
                  estado, AppLocalizations.of(context)),
              style: const TextStyle(
                color: MedRushTheme.textInverse,
                fontSize: MedRushTheme.fontSizeLabelSmall,
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
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
            tooltip: esPendiente
                ? AppLocalizations.of(context).assignDriver
                : AppLocalizations.of(context).viewDetails,
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
            tooltip: esPendiente
                ? AppLocalizations.of(context).viewDetails
                : AppLocalizations.of(context).edit,
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
            tooltip: AppLocalizations.of(context).moreOptions,
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
            itemBuilder: (BuildContext context) {
              final l10n = AppLocalizations.of(context);
              return [
                if (esPendiente)
                  PopupMenuItem<String>(
                    value: 'assign',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.userPlus,
                          color: MedRushTheme.neutralGrey700,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingSm),
                        Text(l10n.assignDriver),
                      ],
                    ),
                  ),
                if (pedido.estado == EstadoPedido.asignado)
                  PopupMenuItem<String>(
                    value: 'cancelar',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.x,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingSm),
                        Text(l10n.cancelOrder),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.pencil,
                        color: MedRushTheme.neutralGrey700,
                        size: 16,
                      ),
                      const SizedBox(width: MedRushTheme.spacingSm),
                      Text(l10n.edit),
                    ],
                  ),
                ),
                if ((pedido.estado == EstadoPedido.recogido ||
                        pedido.estado == EstadoPedido.enRuta) &&
                    pedido.estado != EstadoPedido.entregado &&
                    pedido.estado != EstadoPedido.fallido &&
                    pedido.estado != EstadoPedido.cancelado) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'cancelar',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.x,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingSm),
                        Text(l10n.cancelOrder),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'fallo',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.badgeAlert,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingSm),
                        Text(l10n.markAsFailed),
                      ],
                    ),
                  ),
                ],
                PopupMenuItem<String>(
                  value: 'barcode',
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.barcode,
                        color: MedRushTheme.neutralGrey700,
                        size: 16,
                      ),
                      const SizedBox(width: MedRushTheme.spacingSm),
                      Text(l10n.generateBarcode),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.trash2,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: MedRushTheme.spacingSm),
                      Text(l10n.delete),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  String _getDireccionText(Pedido pedido) {
    // Mostrar dirección principal y distrito
    return '${pedido.direccionEntrega}, ${pedido.distritoEntrega}';
  }

  Widget _buildRepartidorCell(BuildContext context, Pedido pedido) {
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
      pedido.repartidorId != null
          ? AppLocalizations.of(context).assigned
          : AppLocalizations.of(context).notAssigned,
      style: const TextStyle(
        color: MedRushTheme.textSecondary,
        fontSize: MedRushTheme.fontSizeBodySmall,
        fontWeight: MedRushTheme.fontWeightSemiBold,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getUbicacionText(BuildContext context, Pedido pedido) {
    if (pedido.latitudEntrega != null && pedido.longitudEntrega != null) {
      return StatusHelpers.formatearCoordenadasEstandar(
          pedido.latitudEntrega!, pedido.longitudEntrega!);
    }
    return AppLocalizations.of(context).notAvailable;
  }

  /// Obtiene la fecha correspondiente según el estado del pedido
  /// Usa el sistema de prioridad centralizado de StatusHelpers
  String _getFechaSegunEstado(Pedido pedido, BuildContext context) {
    return StatusHelpers.obtenerFechaSegunPrioridad(
        pedido, AppLocalizations.of(context));
  }

  Widget _buildFechaCell(BuildContext context, Pedido pedido) {
    final fechaTexto = _getFechaSegunEstado(pedido, context);
    final tipoFecha = StatusHelpers.obtenerTipoFechaMostrada(
        pedido, AppLocalizations.of(context));

    return Tooltip(
      message: AppLocalizations.of(context).dateOfType(tipoFecha),
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

  Widget _buildUbicacionCell(BuildContext context, Pedido pedido) {
    if (pedido.latitudEntrega == null || pedido.longitudEntrega == null) {
      return Text(
        AppLocalizations.of(context).notAvailable,
        style: const TextStyle(
          color: MedRushTheme.textSecondary,
          fontSize: MedRushTheme.fontSizeBodySmall,
        ),
      );
    }

    // Si hay coordenadas, hacer clickeable para abrir Google Maps
    return InkWell(
      onTap: () => UrlLauncherHelper.openGoogleMapsPlace(
          pedido.latitudEntrega!, pedido.longitudEntrega!),
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
              _getUbicacionText(context, pedido),
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

  void _showBarcodeDialog(BuildContext context, Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              LucideIcons.barcode,
              color: MedRushTheme.neutralGrey700,
              size: 24,
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
            Text(AppLocalizations.of(context).barcodeLabel),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.of(context).orderIdShort}${pedido.id}',
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
                  Text(
                    AppLocalizations.of(context).barcodeOrderDescription,
                    style: const TextStyle(
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
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
            Text(AppLocalizations.of(context).confirmDeletion),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)
                  .confirmDeleteOrderQuestion(pedido.id),
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
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: MedRushTheme.spacingSm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).deleteOrderIrreversible,
                      style: const TextStyle(
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
            child: Text(AppLocalizations.of(context).cancel),
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
            child: Text(AppLocalizations.of(context).delete),
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
            AppLocalizations.of(context).orderDeletedSuccess(pedido.id),
            context: context,
          );
        }

        // Recargar la lista
        onRefresh();
      } else {
        // Mostrar mensaje de error
        if (context.mounted) {
          NotificationService.showError(
            AppLocalizations.of(context).errorDeleteOrder(result.error ?? ''),
            context: context,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorDeleteOrder(e.toString()),
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
      if (!context.mounted) {
        return;
      }
      final List<Usuario> repartidores = res.data ?? [];

      Usuario? seleccionado;
      bool isAssigning = false;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (sbContext, localSetState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(
                      LucideIcons.userPlus,
                      color: MedRushTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).assignDriverTitle),
                  ],
                ),
                content: SizedBox(
                  width: 420,
                  height: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .selectDriverForOrder(pedido.pacienteNombre),
                        style: const TextStyle(
                          color: MedRushTheme.textSecondary,
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: repartidores.isEmpty
                            ? Center(
                                child: Text(AppLocalizations.of(context)
                                    .noActiveDrivers))
                            : ListView.separated(
                                itemCount: repartidores.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final r = repartidores[index];
                                  final isSelected = seleccionado?.id == r.id;
                                  return ListTile(
                                    leading: _buildRepartidorAvatar(r),
                                    title: Text(
                                      r.nombre,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? MedRushTheme.primaryGreen
                                            : MedRushTheme.textPrimary,
                                      ),
                                    ),
                                    subtitle: r.telefono != null
                                        ? Text(r.telefono!)
                                        : null,
                                    trailing: isSelected
                                        ? const Icon(LucideIcons.check,
                                            color: MedRushTheme.primaryGreen)
                                        : null,
                                    selected: isSelected,
                                    selectedTileColor: MedRushTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          MedRushTheme.borderRadiusMd),
                                      side: isSelected
                                          ? const BorderSide(
                                              color: MedRushTheme.primaryGreen)
                                          : BorderSide.none,
                                    ),
                                    onTap: isAssigning
                                        ? null
                                        : () {
                                            localSetState(() {
                                              seleccionado = r;
                                            });
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
                    onPressed: isAssigning
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                  ElevatedButton(
                    onPressed: (seleccionado != null && !isAssigning)
                        ? () async {
                            final repartidorNombre = seleccionado!.nombre;
                            localSetState(() {
                              isAssigning = true;
                            });

                            try {
                              final repo = PedidoRepository();
                              final result = await repo.asignarPedido(
                                  pedido.id, seleccionado!.id);

                              if (!dialogContext.mounted) {
                                return;
                              }

                              if (result.success) {
                                Navigator.of(dialogContext).pop();

                                // Usamos el context padre si sigue montado para mostrar notificación
                                if (context.mounted) {
                                  NotificationService.showSuccess(
                                    AppLocalizations.of(context)
                                        .orderAssignedToName(repartidorNombre),
                                    context: context,
                                  );
                                  // Recargar la lista
                                  onRefresh();
                                }
                              } else {
                                localSetState(() {
                                  isAssigning = false;
                                });
                                final l10n = AppLocalizations.of(dialogContext);
                                NotificationService.showError(
                                  '${l10n.errorAssigningOrder}: ${result.error ?? l10n.unknownError}',
                                  context: dialogContext,
                                );
                              }
                            } catch (e) {
                              localSetState(() {
                                isAssigning = false;
                              });
                              if (dialogContext.mounted) {
                                NotificationService.showError(
                                  e.toString(),
                                  context: dialogContext,
                                );
                              }
                            }
                          }
                        : null,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.grey.shade300;
                        }
                        return MedRushTheme.primaryGreen;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.grey.shade600;
                        }
                        return MedRushTheme.textInverse;
                      }),
                    ),
                    child: isAssigning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(AppLocalizations.of(context).confirmAssignment),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorLoadingDrivers(e.toString()),
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
        title: Row(
          children: [
            const Icon(
              LucideIcons.x,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
            Text(AppLocalizations.of(context).cancelOrderTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)
                  .confirmCancelOrderQuestion(pedido.id),
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
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: MedRushTheme.spacingSm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).cancelOrderIrreversible,
                      style: const TextStyle(
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
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).confirmCancellation),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
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
      if (!context.mounted) {
        return;
      }

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (context.mounted) {
          NotificationService.showSuccess(
            AppLocalizations.of(context).orderCancelledSuccess(pedido.id),
            context: context,
          );
        }

        // Recargar la lista
        onRefresh();
      } else {
        // Mostrar mensaje de error
        if (context.mounted) {
          NotificationService.showError(
            AppLocalizations.of(context)
                .errorCancelingOrder(result.error ?? ''),
            context: context,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (!context.mounted) {
        return;
      }
      if (context.mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorCancelingOrder(e.toString()),
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
          title: Row(
            children: [
              const Icon(
                LucideIcons.badgeAlert,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              Text(AppLocalizations.of(context).markAsFailedTitle),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .selectFailureReasonForOrder(pedido.id),
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingMd),

                // Selector de motivo de fallo
                DropdownButtonFormField<MotivoFalla>(
                  initialValue: motivoSeleccionado,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).failureReasonLabel,
                    border: const OutlineInputBorder(),
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
                          Text(StatusHelpers.motivoFallaTexto(
                              motivo, AppLocalizations.of(context))),
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
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context).observationsOptionalLabel,
                    border: const OutlineInputBorder(),
                    hintText: AppLocalizations.of(context).failureDetailsHint,
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
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.info,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: MedRushTheme.spacingSm),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).markAsFailedIrreversible,
                          style: const TextStyle(
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: motivoSeleccionado != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).confirmFailure),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && motivoSeleccionado != null && context.mounted) {
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

      // Obtener ubicación actual
      double latitud = 26.037737; // Default fallback (EEUU)
      double longitud = -80.179550;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        latitud = position.latitude;
        longitud = position.longitude;
      } catch (e) {
        logWarning('⚠️ No se pudo obtener ubicación GPS precisa: $e');
        // Intentar usar última conocida del servicio si existe
        final last = LocationTrackerService.instance.lastPosition;
        if (last != null) {
          latitud = last.latitude;
          longitud = last.longitude;
        }
      }

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

      if (!context.mounted) {
        return;
      }

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        if (context.mounted) {
          NotificationService.showSuccess(
            AppLocalizations.of(context)
                .orderMarkedFailedSuccess(pedido.id.toString()),
            context: context,
          );
        }
        onRefresh();
      } else {
        if (context.mounted) {
          NotificationService.showError(
            AppLocalizations.of(context)
                .errorMarkingOrderFailed(result.error ?? ''),
            context: context,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (!context.mounted) {
        return;
      }
      if (context.mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorMarkingOrderFailed(e.toString()),
          context: context,
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class RepartidoresTableView extends StatelessWidget {
  final List<Usuario> repartidores;
  final VoidCallback onRefresh;
  final Function(Usuario) onEdit;
  final Function(Usuario) onView;
  final Function(Usuario) onDelete;
  final bool isLoading;

  const RepartidoresTableView({
    super.key,
    required this.repartidores,
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
    final l10n = AppLocalizations.of(context);
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
          SizedBox(
            width: 80,
            child: _buildCenteredHeaderCell(l10n.tableHeaderPhoto),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(l10n.tableHeaderName),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(l10n.tableHeaderEmail),
          ),
          Expanded(
            child: _buildHeaderCell(l10n.tableHeaderPhone),
          ),
          Expanded(
            child: _buildHeaderCell(l10n.tableHeaderVehicle),
          ),
          SizedBox(
            width: 140,
            child: _buildHeaderCell(l10n.tableHeaderLastActivity),
          ),
          Expanded(
            child: _buildCenteredHeaderCell(l10n.actions),
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

    if (repartidores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MedRushTheme.spacingLg),
          child: Text(
            AppLocalizations.of(context).noDriversToShow,
            style: const TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: repartidores.length,
      itemBuilder: (context, index) {
        final repartidor = repartidores[index];
        return _buildTableRow(context, repartidor, index);
      },
    );
  }

  Widget _buildTableRow(BuildContext context, Usuario repartidor, int index) {
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
            // FOTO
            SizedBox(
              width: 80,
              child: Center(
                child: _buildRepartidorAvatar(repartidor),
              ),
            ),
            // NOMBRE
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                      height:
                          8), // Más espacio superior para alinear con avatar
                  // Nombre del repartidor
                  Text(
                    repartidor.nombre,
                    style: const TextStyle(
                      color: MedRushTheme.textPrimary,
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      fontWeight: MedRushTheme.fontWeightSemiBold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: MedRushTheme.spacingXs),
                  // Estado debajo del nombre con altura fija
                  SizedBox(
                    height: 18, // Altura fija para el estado
                    child: _buildStatusBadge(context, repartidor),
                  ),
                ],
              ),
            ),
            // EMAIL
            Expanded(
              flex: 2,
              child: Text(
                repartidor.email,
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // TELÉFONO
            Expanded(
              child: Text(
                repartidor.telefono ?? AppLocalizations.of(context).notAvailable,
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // VEHÍCULO
            Expanded(
              child: Text(
                repartidor.vehiculoPlaca ?? AppLocalizations.of(context).notAssigned,
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ÚLTIMA ACTIVIDAD
            SizedBox(
              width: 140,
              child: Text(
                _formatLastSeen(context, repartidor.updatedAt),
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ACCIONES
            Expanded(
              child: Center(child: _buildActionButtons(repartidor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Usuario repartidor) {
    final estado = repartidor.estadoRepartidor ?? EstadoRepartidor.desconectado;
    final color = StatusHelpers.estadoRepartidorColor(estado);
    final texto = StatusHelpers.estadoRepartidorTexto(estado, AppLocalizations.of(context));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de estado dentro del container
          Icon(
            StatusHelpers.estadoRepartidorIcon(estado),
            color: MedRushTheme.textInverse,
            size: 10,
          ),
          const SizedBox(width: 2),
          // Texto del estado
          Text(
            texto,
            style: const TextStyle(
              color: MedRushTheme.textInverse,
              fontSize: 10,
              fontWeight: MedRushTheme.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Usuario repartidor) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón principal: Ver
          IconButton(
            icon: const Icon(
              LucideIcons.eye,
              color: MedRushTheme.primaryGreen,
              size: 18,
            ),
            onPressed: () => onView(repartidor),
            tooltip: AppLocalizations.of(context).viewDetailsTooltip,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          // Botón secundario: Editar
          IconButton(
            icon: const Icon(
              LucideIcons.pencil,
              color: MedRushTheme.primaryGreen,
              size: 18,
            ),
            onPressed: () => onEdit(repartidor),
            tooltip: AppLocalizations.of(context).edit,
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
                case 'call':
                  await _makePhoneCall(context, repartidor);
                case 'copy_email':
                  await _copyEmailToClipboard(context, repartidor);
                case 'delete':
                  _showDeleteConfirmation(context, repartidor);
              }
            },
            itemBuilder: (BuildContext context) => [
              if (repartidor.telefono != null &&
                  repartidor.telefono!.isNotEmpty)
                PopupMenuItem<String>(
                  value: 'call',
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.phone,
                        color: MedRushTheme.neutralGrey700,
                        size: 16,
                      ),
                      const SizedBox(width: MedRushTheme.spacingSm),
                      Text(AppLocalizations.of(context).call),
                    ],
                  ),
                ),
              PopupMenuItem<String>(
                value: 'copy_email',
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.copy,
                      color: MedRushTheme.neutralGrey700,
                      size: 16,
                    ),
                    const SizedBox(width: MedRushTheme.spacingSm),
                    Text(AppLocalizations.of(context).copyEmail),
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
                    Text(AppLocalizations.of(context).delete),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepartidorAvatar(Usuario repartidor) {
    final String imageUrl = BaseApi.getImageUrl(repartidor.foto);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: MedRushTheme.primaryGreen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Image.network(
                imageUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarFallback(repartidor);
                },
              ),
            )
          : _buildAvatarFallback(repartidor),
    );
  }

  Widget _buildAvatarFallback(Usuario repartidor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.user,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(height: 2),
          Text(
            _getInitials(repartidor.nombre),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) {
      return '??';
    }
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatLastSeen(BuildContext context, DateTime? last) {
    final l10n = AppLocalizations.of(context);
    if (last == null) {
      return l10n.lastActivityNoActivity;
    }
    final diff = DateTime.now().difference(last);
    if (diff.inMinutes < 1) {
      return l10n.lastActivityJustNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.lastActivityMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.lastActivityHoursAgo(diff.inHours);
    }
    return l10n.lastActivityDaysAgo(diff.inDays);
  }

  Future<void> _makePhoneCall(BuildContext context, Usuario repartidor) async {
    try {
      final phoneNumber = repartidor.telefono;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (context.mounted) {
          NotificationService.showWarning(
            AppLocalizations.of(context).driverPhoneNotAvailable,
            context: context,
          );
        }
        return;
      }

      // Crear URL para hacer la llamada
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          NotificationService.showError(
            AppLocalizations.of(context).cannotOpenCallApp,
            context: context,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorMakingCallWithError(e),
          context: context,
        );
      }
    }
  }

  Future<void> _copyEmailToClipboard(
      BuildContext context, Usuario repartidor) async {
    try {
      final email = repartidor.email;
      if (email.isEmpty) {
        if (context.mounted) {
          NotificationService.showWarning(
            AppLocalizations.of(context).noEmailAvailable,
            context: context,
          );
        }
        return;
      }

      await Clipboard.setData(ClipboardData(text: email));

      // No mostrar SnackBar de confirmación - es obvio que se copió
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorCopyingEmail(e),
          context: context,
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, Usuario repartidor) {
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
              AppLocalizations.of(context).confirmDeleteDriverQuestion(repartidor.nombre),
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
                      AppLocalizations.of(context).deleteDriverIrreversible,
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
              await _deleteRepartidor(context, repartidor);
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

  Future<void> _deleteRepartidor(
      BuildContext context, Usuario repartidor) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Eliminar repartidor usando el repositorio
      final repository = RepartidorRepository();
      final result = await repository.deleteRepartidor(repartidor.id);

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (context.mounted) {
          NotificationService.showSuccess(
            AppLocalizations.of(context).driverDeletedSuccess(repartidor.nombre),
            context: context,
          );
        }

        // Recargar la lista
        onRefresh();
      } else {
        // Mostrar mensaje de error
        if (context.mounted) {
          NotificationService.showError(
            AppLocalizations.of(context).errorDeleteDriver(result.error!),
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
          AppLocalizations.of(context).errorDeleteDriver(e),
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
                  // FOTO shimmer
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  // NOMBRE shimmer
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                            height:
                                8), // Más espacio superior para alinear con avatar
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: MedRushTheme.spacingXs),
                        // Estado shimmer con altura fija
                        SizedBox(
                          height: 18, // Misma altura fija que el estado real
                          child: Container(
                            height: 16,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // EMAIL shimmer
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
                  // TELÉFONO shimmer
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // VEHÍCULO shimmer
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // ÚLTIMA ACTIVIDAD shimmer
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
}

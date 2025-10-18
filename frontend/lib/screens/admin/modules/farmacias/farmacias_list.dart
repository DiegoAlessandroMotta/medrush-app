import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/repositories/farmacia.repository.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class FarmaciasTableView extends StatelessWidget {
  final List<Farmacia> farmacias;
  final VoidCallback onRefresh;
  final Function(Farmacia) onEdit;
  final Function(Farmacia) onView;
  final Function(Farmacia) onDelete;
  final bool isLoading;

  const FarmaciasTableView({
    super.key,
    required this.farmacias,
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
          // NOMBRE
          Expanded(
            flex: 2,
            child: _buildHeaderCell('NOMBRE'),
          ),
          // DIRECCIÓN
          Expanded(
            flex: 2,
            child: _buildHeaderCell('DIRECCIÓN'),
          ),
          // RESPONSABLE
          Expanded(
            flex: 2,
            child: _buildHeaderCell('RESPONSABLE'),
          ),
          // TELÉFONO
          Expanded(
            child: _buildHeaderCell('TELÉFONO'),
          ),
          // CIUDAD
          SizedBox(
            width: 120,
            child: _buildHeaderCell('CIUDAD'),
          ),
          // UBICACIÓN
          SizedBox(
            width: 140,
            child: _buildHeaderCell('UBICACIÓN'),
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

    if (farmacias.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(MedRushTheme.spacingLg),
          child: Text(
            'No hay farmacias para mostrar',
            style: TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: farmacias.length,
      itemBuilder: (context, index) {
        final farmacia = farmacias[index];
        return _buildTableRow(farmacia, index);
      },
    );
  }

  Widget _buildTableRow(Farmacia farmacia, int index) {
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
            // NOMBRE
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  // Icono de farmacia
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: StatusHelpers.estadoFarmaciaColor(farmacia.estado)
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: Icon(
                      LucideIcons.building2,
                      color: StatusHelpers.estadoFarmaciaColor(farmacia.estado),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: MedRushTheme.spacingSm),
                  // Nombre y estado en columna
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nombre de la farmacia
                        Text(
                          farmacia.nombre,
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
                          height: 18, // Altura fija más pequeña para el estado
                          child: _buildStatusBadge(farmacia),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // DIRECCIÓN
            Expanded(
              flex: 2,
              child: Text(
                farmacia.direccion,
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // RESPONSABLE
            Expanded(
              flex: 2,
              child: Text(
                farmacia.contactoResponsable ?? 'Sin responsable',
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
                farmacia.telefono ?? 'Sin teléfono',
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // CIUDAD
            SizedBox(
              width: 120,
              child: Text(
                farmacia.city ?? 'Sin ciudad',
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // UBICACIÓN
            SizedBox(
              width: 140,
              child: _buildUbicacionCell(farmacia),
            ),
            // ACCIONES
            Expanded(
              child: Center(child: _buildActionButtons(farmacia)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Farmacia farmacia) {
    final color = StatusHelpers.estadoFarmaciaColor(farmacia.estado);
    final texto = StatusHelpers.estadoFarmaciaTexto(farmacia.estado);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
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
            StatusHelpers.estadoFarmaciaIcon(farmacia.estado),
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

  Widget _buildActionButtons(Farmacia farmacia) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón Ver
          IconButton(
            icon: const Icon(
              LucideIcons.eye,
              color: MedRushTheme.primaryGreen,
              size: 18,
            ),
            onPressed: () => onView(farmacia),
            tooltip: 'Ver detalles',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          // Botón Editar
          IconButton(
            icon: const Icon(
              LucideIcons.pencil,
              color: MedRushTheme.primaryGreen,
              size: 18,
            ),
            onPressed: () => onEdit(farmacia),
            tooltip: 'Editar',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          // Botón Eliminar
          IconButton(
            icon: const Icon(
              LucideIcons.trash2,
              color: Colors.red,
              size: 18,
            ),
            onPressed: () => _showDeleteConfirmation(context, farmacia),
            tooltip: 'Eliminar',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  String _getUbicacionText(Farmacia farmacia) {
    // Mostrar coordenadas si están disponibles
    if (farmacia.latitud != 0.0 && farmacia.longitud != 0.0) {
      return StatusHelpers.formatearCoordenadasEstandar(
          farmacia.latitud, farmacia.longitud);
    }
    return 'No disponible';
  }

  Widget _buildUbicacionCell(Farmacia farmacia) {
    // Si no hay coordenadas, mostrar texto simple
    if (farmacia.latitud == 0.0 || farmacia.longitud == 0.0) {
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
      onTap: () => _openGoogleMaps(farmacia.latitud, farmacia.longitud),
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
              _getUbicacionText(farmacia),
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

  void _showDeleteConfirmation(BuildContext context, Farmacia farmacia) {
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
              '¿Estás seguro de que deseas eliminar la farmacia "${farmacia.nombre}"?',
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
                      'Esta acción no se puede deshacer. La farmacia será eliminada permanentemente.',
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
              await _deleteFarmacia(context, farmacia);
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

  Future<void> _deleteFarmacia(BuildContext context, Farmacia farmacia) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Eliminar farmacia usando el repositorio
      final repository = FarmaciaRepository();
      final result = await repository.eliminar(farmacia.id);

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Farmacia "${farmacia.nombre}" eliminada exitosamente'),
              backgroundColor: MedRushTheme.primaryGreen,
            ),
          );
        }

        // Recargar la lista
        onRefresh();
      } else {
        // Mostrar mensaje de error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar farmacia: ${result.error}'),
              backgroundColor: Colors.red,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar farmacia: $e'),
            backgroundColor: Colors.red,
          ),
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
                  // NOMBRE shimmer
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                MedRushTheme.borderRadiusSm),
                          ),
                        ),
                        const SizedBox(width: MedRushTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                height:
                                    18, // Misma altura fija que el estado real
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
                      ],
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
                  // RESPONSABLE shimmer
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
                  // CIUDAD shimmer
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

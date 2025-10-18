import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/mapa_widget.dart';
import 'package:share_plus/share_plus.dart';

// Ancho máximo del bottom sheet en desktop para mejorar legibilidad
const double _kMaxDesktopSheetWidth = 980;

class FarmaciaDetalleBottomSheet extends StatelessWidget {
  final Farmacia farmacia;

  const FarmaciaDetalleBottomSheet({
    super.key,
    required this.farmacia,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxDesktopSheetWidth),
        child: Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Column(
              children: [
                // Header con drag handle y botón de cerrar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  decoration: const BoxDecoration(
                    color: MedRushTheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              MedRushTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header con título y botón de cerrar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detalle de Farmacia',
                                  style: TextStyle(
                                    fontSize: MedRushTheme.fontSizeTitleLarge,
                                    fontWeight: MedRushTheme.fontWeightBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farmacia.nombre,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodySmall,
                                    color: MedRushTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              LucideIcons.x,
                              color: MedRushTheme.textSecondary,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: MedRushTheme.backgroundSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            tooltip: 'Más',
                            onSelected: (value) async {
                              if (value == 'export') {
                                final contenido = _toPrettyString(farmacia);
                                await SharePlus.instance.share(
                                  ShareParams(
                                    text: contenido,
                                    subject: 'Detalle de farmacia',
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'export',
                                  child: Text('Compartir/Exportar')),
                            ],
                            icon: const Icon(LucideIcons.ellipsis,
                                color: MedRushTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contenido del detalle
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: MedRushTheme.spacingMd),

                        // Información principal
                        _buildInfoCard(
                          title: 'Información General',
                          children: [
                            _buildIconRow(
                                'ID', farmacia.id, LucideIcons.idCard),
                            _buildIconRow('Nombre', farmacia.nombre,
                                LucideIcons.building2),
                            _buildIconRow('Razón Social', farmacia.razonSocial,
                                LucideIcons.building),
                            _buildIconRow(
                                'RUC', farmacia.ruc, LucideIcons.shield),
                            if (farmacia.cadena != null)
                              _buildIconRow('Cadena', farmacia.cadena!,
                                  LucideIcons.store),
                            _buildIconRow('Estado', farmacia.estado.name,
                                LucideIcons.flag),
                          ],
                        ),

                        const SizedBox(height: MedRushTheme.spacingMd),

                        // Información de ubicación
                        _buildInfoCard(
                          title: 'Ubicación',
                          children: [
                            _buildIconRow('Dirección', farmacia.direccion,
                                LucideIcons.mapPin),
                            if (farmacia.city != null)
                              _buildIconRow(
                                  'Ciudad', farmacia.city!, LucideIcons.mapPin),
                            if (farmacia.state != null)
                              _buildIconRow(
                                  'Estado', farmacia.state!, LucideIcons.map),
                            if (farmacia.zipCode != null)
                              _buildIconRow(
                                  'ZIP', farmacia.zipCode!, LucideIcons.mapPin),
                            _buildIconRow(
                                'Latitud',
                                farmacia.latitud.toString(),
                                LucideIcons.navigation),
                            _buildIconRow(
                                'Longitud',
                                farmacia.longitud.toString(),
                                LucideIcons.navigation),
                            const SizedBox(height: 12),
                            Stack(
                              children: [
                                MapaWidget(
                                  pedidos: const [],
                                  puntoSeleccionado: LatLng(
                                      farmacia.latitud, farmacia.longitud),
                                  height: 260, // Más alto como en el form
                                  readOnly: true,
                                  markerTitle: farmacia.nombre,
                                  markerSnippet: farmacia.direccion,
                                ),
                                // Botón de pantalla completa (arriba)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: FloatingActionButton.small(
                                    heroTag: 'fab_mapa_farmacia_detalle',
                                    onPressed: () =>
                                        _abrirMapaPantallaCompleta(context),
                                    backgroundColor: MedRushTheme.primaryGreen,
                                    foregroundColor: MedRushTheme.textInverse,
                                    child: const Icon(LucideIcons.maximize),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: MedRushTheme.spacingMd),

                        // Información de contacto
                        _buildInfoCard(
                          title: 'Contacto',
                          children: [
                            if (farmacia.telefono != null)
                              _buildIconRow('Teléfono', farmacia.telefono!,
                                  LucideIcons.phone),
                            if (farmacia.email != null)
                              _buildIconRow(
                                  'Email', farmacia.email!, LucideIcons.mail),
                            if (farmacia.contactoResponsable != null)
                              _buildIconRow(
                                  'Responsable',
                                  farmacia.contactoResponsable!,
                                  LucideIcons.user),
                            if (farmacia.telefonoResponsable != null)
                              _buildIconRow(
                                  'Teléfono Responsable',
                                  farmacia.telefonoResponsable!,
                                  LucideIcons.phone),
                          ],
                        ),

                        const SizedBox(height: MedRushTheme.spacingMd),

                        // Información adicional
                        _buildInfoCard(
                          title: 'Información Adicional',
                          children: [
                            if (farmacia.horarioAtencion != null)
                              _buildIconRow('Horario',
                                  farmacia.horarioAtencion!, LucideIcons.clock),
                            _buildIconRow(
                                'Delivery 24h',
                                farmacia.delivery24h ? 'Sí' : 'No',
                                LucideIcons.truck),
                            _buildIconRow(
                                'Fecha Registro',
                                _formatDate(farmacia.fechaRegistro),
                                LucideIcons.calendar),
                            if (farmacia.fechaUltimaActualizacion != null)
                              _buildIconRow(
                                  'Última Actualización',
                                  _formatDate(
                                      farmacia.fechaUltimaActualizacion!),
                                  LucideIcons.refreshCw),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirMapaPantallaCompleta(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapaPantallaCompleta(
          puntoInicial: LatLng(farmacia.latitud, farmacia.longitud),
          titulo: 'Ubicación de ${farmacia.nombre}',
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }

  // Deprecated helper replaced by _buildIconRow

  Widget _buildIconRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, size: 16, color: MedRushTheme.primaryGreen),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$label:',
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                      fontWeight: MedRushTheme.fontWeightMedium,
                      color: MedRushTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return StatusHelpers.formatearFechaCompletaConCeros(date);
  }

  String _toPrettyString(Farmacia f) {
    return 'Farmacia: ${f.nombre}\nRUC: ${f.ruc}\nDirección: ${f.direccion}\nCiudad: ${f.city}${f.state != null ? ', ${f.state!}' : ''}${f.zipCode != null ? ' ${f.zipCode!}' : ''}\nTeléfono: ${f.telefono}\nEmail: ${f.email ?? '-'}\nLat: ${f.latitud}, Lng: ${f.longitud}\nEstado: ${f.estado.name}\nCadena: ${f.cadena}';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Farmacia>('farmacia', farmacia));
  }
}

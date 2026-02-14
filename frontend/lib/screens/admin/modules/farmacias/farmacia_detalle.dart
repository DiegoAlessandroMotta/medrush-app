import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/mapa_widget.dart';

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
                                Text(
                                  AppLocalizations.of(context).pharmacyDetailTitle,
                                  style: const TextStyle(
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
                          title: AppLocalizations.of(context).generalInfoTitle,
                          children: [
                            _buildIconRow(
                                AppLocalizations.of(context).idShort,
                                farmacia.id,
                                LucideIcons.idCard),
                            _buildIconRow(
                                AppLocalizations.of(context).name,
                                farmacia.nombre,
                                LucideIcons.building2),
                            _buildIconRow(
                                AppLocalizations.of(context).razonSocialLabel,
                                farmacia.razonSocial,
                                LucideIcons.building),
                            if (farmacia.ruc.isNotEmpty)
                              _buildIconRow(
                                  AppLocalizations.of(context).rucLabel,
                                  farmacia.ruc,
                                  LucideIcons.shield),
                            if (farmacia.cadena != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).cadenaLabel,
                                  farmacia.cadena!,
                                  LucideIcons.store),
                            _buildIconRow(
                                AppLocalizations.of(context).statusShort,
                                farmacia.estado.name,
                                LucideIcons.flag),
                          ],
                        ),

                        const SizedBox(height: MedRushTheme.spacingMd),

                        // Información de ubicación
                        _buildInfoCard(
                          title: AppLocalizations.of(context).locationTitle,
                          children: [
                            _buildIconRow(
                                AppLocalizations.of(context).address,
                                farmacia.direccion,
                                LucideIcons.mapPin),
                            if (farmacia.city != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).city,
                                  farmacia.city!,
                                  LucideIcons.mapPin),
                            if (farmacia.state != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).stateRegionLabel,
                                  farmacia.state!,
                                  LucideIcons.map),
                            if (farmacia.zipCode != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).zipCodeLabel,
                                  farmacia.zipCode!,
                                  LucideIcons.mapPin),
                            _buildIconRow(
                                AppLocalizations.of(context).latitudeLabel,
                                farmacia.latitud.toString(),
                                LucideIcons.navigation),
                            _buildIconRow(
                                AppLocalizations.of(context).longitudeLabel,
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
                          title: AppLocalizations.of(context).contactTitle,
                          children: [
                            if (farmacia.telefono != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).phone,
                                  farmacia.telefono!,
                                  LucideIcons.phone),
                            if (farmacia.email != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).email,
                                  farmacia.email!,
                                  LucideIcons.mail),
                            if (farmacia.contactoResponsable != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).responsibleLabel,
                                  farmacia.contactoResponsable!,
                                  LucideIcons.user),
                            if (farmacia.telefonoResponsable != null)
                              _buildIconRow(
                                  AppLocalizations.of(context)
                                      .responsiblePhoneLabel,
                                  farmacia.telefonoResponsable!,
                                  LucideIcons.phone),
                          ],
                        ),

                        const SizedBox(height: MedRushTheme.spacingMd),

                        // Información adicional
                        _buildInfoCard(
                          title: AppLocalizations.of(context).additionalInfoTitle,
                          children: [
                            if (farmacia.horarioAtencion != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).scheduleLabel,
                                  farmacia.horarioAtencion!,
                                  LucideIcons.clock),
                            _buildIconRow(
                                AppLocalizations.of(context).delivery24hLabel,
                                farmacia.delivery24h
                                    ? AppLocalizations.of(context).yes
                                    : AppLocalizations.of(context).no,
                                LucideIcons.truck),
                            _buildIconRow(
                                AppLocalizations.of(context).registrationDateShort,
                                _formatDate(farmacia.fechaRegistro),
                                LucideIcons.calendar),
                            if (farmacia.fechaUltimaActualizacion != null)
                              _buildIconRow(
                                  AppLocalizations.of(context).lastUpdateLabel,
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
          titulo: AppLocalizations.of(context).pharmacyLocationTitle(farmacia.nombre),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Farmacia>('farmacia', farmacia));
  }
}

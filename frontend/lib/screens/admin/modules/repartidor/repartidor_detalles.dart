import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/farmacia.repository.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:photo_view/photo_view.dart';

// Ancho máximo del bottom sheet en desktop para mejorar legibilidad
const double _kMaxDesktopSheetWidth = 980;

// Extension para formatear fechas
extension DateFormatter on DateTime {
  String toFormattedDate() {
    return StatusHelpers.formatearFechaAPI(DateTime(year, month, day));
  }

  String toFormattedDateTime() {
    return StatusHelpers.formatearFechaCompleta(this);
  }
}

class RepartidorDetalles extends StatefulWidget {
  final Usuario repartidor;
  final void Function()? onEdit;
  final void Function()? onDelete;

  const RepartidorDetalles({
    super.key,
    required this.repartidor,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<RepartidorDetalles> createState() => _RepartidorDetallesState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Usuario>('repartidor', repartidor))
      ..add(ObjectFlagProperty<void Function()?>.has('onEdit', onEdit))
      ..add(ObjectFlagProperty<void Function()?>.has('onDelete', onDelete));
  }
}

class _RepartidorDetallesState extends State<RepartidorDetalles> {
  Farmacia? _farmacia;
  bool _isLoadingFarmacia = false;

  @override
  void initState() {
    super.initState();
    _loadFarmacia();
  }

  Future<void> _loadFarmacia() async {
    if (widget.repartidor.farmaciaId == null) {
      return;
    }

    setState(() {
      _isLoadingFarmacia = true;
    });

    try {
      logInfo(
          '🔄 Cargando farmacia del repartidor: ${widget.repartidor.farmaciaId}');
      final repo = FarmaciaRepository();
      final res = await repo.obtenerPorId(widget.repartidor.farmaciaId!);
      final farmacia = res.data;

      setState(() {
        _farmacia = farmacia;
        _isLoadingFarmacia = false;
      });

      logInfo('✅ Farmacia cargada: ${farmacia?.nombre ?? "Sin nombre"}');
    } catch (e) {
      logError('❌ Error al cargar farmacia', e);
      setState(() {
        _isLoadingFarmacia = false;
      });
    }
  }

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
                                  'Repartidor',
                                  style: TextStyle(
                                    fontSize: MedRushTheme.fontSizeTitleLarge,
                                    fontWeight: MedRushTheme.fontWeightBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: StatusHelpers.estadoRepartidorColor(
                                        widget.repartidor.estadoRepartidor ??
                                            EstadoRepartidor.desconectado),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        StatusHelpers.estadoRepartidorIcon(
                                            widget.repartidor
                                                    .estadoRepartidor ??
                                                EstadoRepartidor.desconectado),
                                        size: 12,
                                        color: MedRushTheme.textInverse,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        StatusHelpers.estadoRepartidorTexto(
                                            widget.repartidor
                                                    .estadoRepartidor ??
                                                EstadoRepartidor.desconectado),
                                        style: const TextStyle(
                                          color: MedRushTheme.textInverse,
                                          fontSize:
                                              MedRushTheme.fontSizeLabelSmall,
                                          fontWeight:
                                              MedRushTheme.fontWeightMedium,
                                        ),
                                      ),
                                    ],
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

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con foto y nombre
                        _buildHeader(),
                        const SizedBox(height: MedRushTheme.spacingLg),

                        // Información Personal
                        _buildInfoSection('Información Personal', [
                          _buildInfoRow('Nombre', widget.repartidor.nombre,
                              icon: LucideIcons.user),
                          _buildInfoRow(
                              'Tipo de Usuario', _getTipoUsuarioDisplayName(),
                              icon: LucideIcons.user),
                          if (widget.repartidor.telefono != null)
                            _buildInfoRow(
                                'Teléfono', widget.repartidor.telefono!,
                                icon: LucideIcons.phone),
                          if (widget.repartidor.codigoIsoPais != null)
                            _buildInfoRow(
                                'País', widget.repartidor.codigoIsoPais!,
                                icon: LucideIcons.flag),
                          if (widget.repartidor.verificado != null)
                            _buildInfoRow('Verificado',
                                widget.repartidor.verificado! ? 'Sí' : 'No',
                                icon: widget.repartidor.verificado!
                                    ? LucideIcons.badgeCheck
                                    : LucideIcons.shieldAlert,
                                iconColor: widget.repartidor.verificado!
                                    ? MedRushTheme.primaryGreen
                                    : MedRushTheme.textSecondary),
                          _buildInfoRow('Usuario Activo',
                              widget.repartidor.activo ? 'Sí' : 'No',
                              icon: widget.repartidor.activo
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.circleX,
                              iconColor: widget.repartidor.activo
                                  ? MedRushTheme.primaryGreen
                                  : MedRushTheme.textSecondary),
                        ]),

                        const SizedBox(height: MedRushTheme.spacingLg),

                        // Información de Documentos
                        if (_hasDocumentInfo())
                          Column(
                            children: [
                              _buildInfoSection('Documentos', [
                                if (widget.repartidor.dniIdNumero != null)
                                  _buildInfoRow(
                                      'ID', widget.repartidor.dniIdNumero!,
                                      icon: LucideIcons.idCard),
                                if (widget.repartidor.fotoDniId != null)
                                  _buildDocumentRow(
                                      'Foto ID',
                                      widget.repartidor.fotoDniId!,
                                      LucideIcons.idCard),
                                if (widget.repartidor.firmaDigital != null)
                                  _buildDocumentRow(
                                      'Firma Digital',
                                      widget.repartidor.firmaDigital!,
                                      Icons.draw),
                              ]),
                              const SizedBox(height: MedRushTheme.spacingLg),
                            ],
                          ),

                        // Información de Licencia
                        if (_hasLicenseInfo())
                          Column(
                            children: [
                              _buildInfoSection('Información de Licencia', [
                                if (widget.repartidor.licenciaNumero != null)
                                  _buildInfoRow('Número de Licencia',
                                      widget.repartidor.licenciaNumero!,
                                      icon: LucideIcons.idCard),
                                if (widget.repartidor.licenciaVencimiento !=
                                    null)
                                  _buildInfoRow(
                                    'Vencimiento',
                                    _formatDate(
                                        widget.repartidor.licenciaVencimiento!),
                                    isExpiring: _isLicenseExpiring(),
                                    icon: LucideIcons.calendar,
                                  ),
                                if (widget.repartidor.fotoLicencia != null)
                                  _buildDocumentRow(
                                      'Foto Licencia',
                                      widget.repartidor.fotoLicencia!,
                                      LucideIcons.idCard),
                                if ((widget.repartidor.fotoSeguroVehiculo ??
                                        widget.repartidor.seguroVehiculoUrl) !=
                                    null)
                                  _buildDocumentRow(
                                    'Foto Seguro del Vehículo',
                                    (widget.repartidor.fotoSeguroVehiculo ??
                                        widget.repartidor.seguroVehiculoUrl)!,
                                    LucideIcons.shield,
                                  ),
                              ]),
                              const SizedBox(height: MedRushTheme.spacingLg),
                            ],
                          ),

                        // Información del Vehículo
                        if (_hasVehicleInfo())
                          Column(
                            children: [
                              _buildInfoSection('Información del Vehículo', [
                                if (widget.repartidor.vehiculoPlaca != null)
                                  _buildInfoRow(
                                      'Placa', widget.repartidor.vehiculoPlaca!,
                                      icon: LucideIcons.mapPin),
                                if (widget.repartidor.vehiculoMarca != null)
                                  _buildInfoRow(
                                      'Marca', widget.repartidor.vehiculoMarca!,
                                      icon: LucideIcons.car),
                                if (widget.repartidor.vehiculoModelo != null)
                                  _buildInfoRow('Modelo',
                                      widget.repartidor.vehiculoModelo!,
                                      icon: LucideIcons.car),
                                if (widget.repartidor.vehiculoCodigoRegistro !=
                                    null)
                                  _buildInfoRow(
                                    'Código de Registro',
                                    widget.repartidor.vehiculoCodigoRegistro!,
                                    icon: LucideIcons.badge,
                                  ),
                              ]),
                              const SizedBox(height: MedRushTheme.spacingLg),
                            ],
                          ),

                        // Asignación de Farmacia
                        _buildInfoSection('Asignación de Farmacia', [
                          _buildFarmaciaInfo(),
                        ]),

                        const SizedBox(height: MedRushTheme.spacingLg),

                        // Información del Sistema
                        _buildInfoSection('Información del Sistema', [
                          _buildInfoRow(
                              'Fecha de Registro',
                              widget.repartidor.createdAt != null
                                  ? _formatDate(widget.repartidor.createdAt!)
                                  : 'No disponible',
                              icon: Icons.event),
                          if (widget.repartidor.updatedAt != null)
                            _buildInfoRow(
                              'Última Actividad',
                              _formatDateTime(widget.repartidor.updatedAt!),
                              icon: Icons.access_time,
                            ),
                        ]),

                        const SizedBox(height: MedRushTheme.spacingLg),

                        // Botones de Acción
                        _buildActionButtons(),

                        // Espacio extra al final para evitar que el contenido se corte
                        const SizedBox(height: MedRushTheme.spacingXl),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Row(
        children: [
          // Avatar mejorado
          _buildAvatar(),
          const SizedBox(width: MedRushTheme.spacingLg),

          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.repartidor.nombre.split(' ').first,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeHeadlineMedium,
                    fontWeight: MedRushTheme.fontWeightBold,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingSm),
                Row(
                  children: [
                    Icon(
                      StatusHelpers.estadoRepartidorIcon(
                          widget.repartidor.estadoRepartidor ??
                              EstadoRepartidor.desconectado),
                      size: 14,
                      color: StatusHelpers.estadoRepartidorColor(
                          widget.repartidor.estadoRepartidor ??
                              EstadoRepartidor.desconectado),
                    ),
                    const SizedBox(width: MedRushTheme.spacingSm),
                    Text(
                      StatusHelpers.estadoRepartidorTexto(
                          widget.repartidor.estadoRepartidor ??
                              EstadoRepartidor.desconectado),
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        color: StatusHelpers.estadoRepartidorColor(
                            widget.repartidor.estadoRepartidor ??
                                EstadoRepartidor.desconectado),
                        fontWeight: MedRushTheme.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MedRushTheme.spacingSm),
                Text(
                  widget.repartidor.email,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    color: MedRushTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final String imageUrl = BaseApi.getImageUrl(widget.repartidor.foto);

    return GestureDetector(
      onTap: imageUrl.isNotEmpty
          ? () => _showImageZoom(imageUrl, 'Foto de perfil')
          : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: MedRushTheme.primaryGreen,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: Image.network(
                  imageUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAvatarFallback();
                  },
                ),
              )
            : _buildAvatarFallback(),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person,
            size: 32,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            _getInitials(widget.repartidor.nombre),
            style: const TextStyle(
              color: Colors.white,
              fontSize: MedRushTheme.fontSizeBodySmall,
              fontWeight: MedRushTheme.fontWeightBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodyLarge,
            fontWeight: MedRushTheme.fontWeightBold,
            color: MedRushTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MedRushTheme.spacingMd),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares para formatear fechas
  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }
    return date.toFormattedDate();
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }
    return date.toFormattedDateTime();
  }

  // Método para construir una fila de información con icono
  Widget _buildInfoRow(String label, String value,
      {bool isExpiring = false, IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (iconColor ?? MedRushTheme.textSecondary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: iconColor ?? MedRushTheme.textSecondary,
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
          ],
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.textSecondary,
                    fontSize: MedRushTheme.fontSizeBodySmall,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isExpiring ? Colors.red : MedRushTheme.textPrimary,
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    fontWeight: isExpiring
                        ? MedRushTheme.fontWeightBold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmaciaInfo() {
    if (_isLoadingFarmacia) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingSm),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: MedRushTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
            const Text(
              'Cargando información de la farmacia...',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_farmacia == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingSm),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: MedRushTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_pharmacy,
                size: 16,
                color: MedRushTheme.textSecondary,
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
            const Text(
              'No asignado a ninguna farmacia',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Nombre', _farmacia!.nombre, icon: LucideIcons.pill),
        if (_farmacia!.direccion.isNotEmpty)
          _buildInfoRow('Dirección', _farmacia!.direccion,
              icon: LucideIcons.mapPin),
        if (_farmacia!.telefono != null && _farmacia!.telefono!.isNotEmpty)
          _buildInfoRow('Teléfono', _farmacia!.telefono!,
              icon: LucideIcons.phone),
      ],
    );
  }

  // Métodos para manejar estados del repartidor
  bool _hasDocumentInfo() {
    return widget.repartidor.dniIdNumero != null ||
        widget.repartidor.fotoDniId != null ||
        widget.repartidor.firmaDigital != null;
  }

  bool _hasLicenseInfo() {
    return widget.repartidor.licenciaNumero != null ||
        widget.repartidor.licenciaVencimiento != null ||
        widget.repartidor.fotoLicencia != null ||
        (widget.repartidor.fotoSeguroVehiculo ??
                widget.repartidor.seguroVehiculoUrl) !=
            null;
  }

  bool _hasVehicleInfo() {
    return widget.repartidor.vehiculoPlaca != null ||
        widget.repartidor.vehiculoMarca != null ||
        widget.repartidor.vehiculoModelo != null ||
        widget.repartidor.vehiculoCodigoRegistro != null;
  }

  bool _isLicenseExpiring() {
    final vencimiento = widget.repartidor.licenciaVencimiento;
    if (vencimiento == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = vencimiento.difference(now);
    return !difference.isNegative && difference.inDays <= 30;
  }

  // Botones de Acción
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onEdit != null) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Editar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedRushTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (widget.onDelete != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showDeleteConfirmation,
              icon:
                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              label: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este repartidor? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  // Métodos para manejar la visualización del estado
  String _getTipoUsuarioDisplayName() {
    switch (widget.repartidor.tipoUsuario) {
      case TipoUsuario.administrador:
        return 'Administrador';
      case TipoUsuario.repartidor:
        return 'Repartidor';
    }
  }

  // Método para construir una fila de documento con imagen
  Widget _buildDocumentRow(String label, String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y label
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: MedRushTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: MedRushTheme.fontWeightMedium,
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          // Mostrar imagen siempre
          _buildImagePreview(url),
        ],
      ),
    );
  }

  // Widget para mostrar preview de imagen (base64 o URL)
  Widget _buildImagePreview(String imageData) {
    return GestureDetector(
      onTap: () => _showImageZoom(imageData, 'Documento'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: MedRushTheme.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageData.startsWith('data:image/')
              ? Image.memory(
                  base64Decode(imageData.split(',')[1]),
                  width: 200,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImageError();
                  },
                )
              : Image.network(
                  imageData,
                  width: 200,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImageError();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: 200,
      height: 100,
      color: MedRushTheme.backgroundSecondary,
      child: const Center(
        child: Text(
          'Error al cargar imagen',
          style: TextStyle(color: MedRushTheme.textSecondary),
        ),
      ),
    );
  }

  // Método para mostrar zoom de imagen con photo_view
  void _showImageZoom(String imageData, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Fondo semi-transparente
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Contenido del diálogo
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: MedRushTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Imagen con zoom usando photo_view
                      PhotoView(
                        imageProvider: imageData.startsWith('data:image/')
                            ? MemoryImage(base64Decode(imageData.split(',')[1]))
                            : NetworkImage(imageData) as ImageProvider,
                        backgroundDecoration: const BoxDecoration(
                          color: MedRushTheme.surface,
                        ),
                        minScale: PhotoViewComputedScale.contained * 0.3,
                        maxScale: PhotoViewComputedScale.contained * 3.0,
                        initialScale: PhotoViewComputedScale.contained,
                        heroAttributes: PhotoViewHeroAttributes(tag: title),
                        errorBuilder: (context, error, stackTrace) {
                          return _buildZoomImageError();
                        },
                        loadingBuilder: (context, event) {
                          if (event == null) {
                            return const SizedBox.shrink();
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: event.expectedTotalBytes != null
                                  ? event.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                      // Botón de cerrar flotante
                      Positioned(
                        top: 8,
                        right: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              LucideIcons.x,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomImageError() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: MedRushTheme.backgroundSecondary,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: MedRushTheme.textSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'Error al cargar imagen',
              style: TextStyle(
                color: MedRushTheme.textSecondary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para obtener iniciales del nombre
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
}

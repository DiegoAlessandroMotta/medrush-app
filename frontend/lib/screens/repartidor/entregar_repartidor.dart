import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/screens/repartidor/firma_screen.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';

class EntregarRepartidorScreen extends StatefulWidget {
  final Pedido pedido;

  const EntregarRepartidorScreen({
    super.key,
    required this.pedido,
  });

  @override
  State<EntregarRepartidorScreen> createState() =>
      _EntregarRepartidorScreenState();
}

class _EntregarRepartidorScreenState extends State<EntregarRepartidorScreen> {
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  File? _fotoEntrega;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      body: _isProcessing
          ? _buildProcessingState()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  MedRushTheme.spacingLg,
                  MedRushTheme.spacingXl,
                  MedRushTheme.spacingLg,
                  MedRushTheme.spacingLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPedidoInfo(),
                    const SizedBox(height: MedRushTheme.spacingXl),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MedRushTheme.spacingLg,
            MedRushTheme.spacingMd,
            MedRushTheme.spacingLg,
            MedRushTheme.spacingMd,
          ),
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(MedRushTheme.primaryGreen),
          ),
          SizedBox(height: MedRushTheme.spacingLg),
          Text(
            'Procesando entrega...',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              color: MedRushTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoInfo() {
    final productosCount = widget.pedido.medicamentos.length;
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles de la Entrega',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          Row(
            children: [
              const Icon(LucideIcons.mapPin,
                  size: 18, color: MedRushTheme.textSecondary),
              const SizedBox(width: MedRushTheme.spacingSm),
              Expanded(
                child: Text(
                  widget.pedido.direccionEntrega,
                  style: const TextStyle(
                    color: MedRushTheme.textSecondary,
                    fontSize: MedRushTheme.fontSizeBodySmall,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          const Divider(height: 1, color: MedRushTheme.borderLight),
          const SizedBox(height: MedRushTheme.spacingSm),
          Row(
            children: [
              const Icon(LucideIcons.package,
                  size: 18, color: MedRushTheme.statusInProgress),
              const SizedBox(width: MedRushTheme.spacingSm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'ID de Pedido: ',
                        style: TextStyle(
                          fontWeight: MedRushTheme.fontWeightBold,
                          color: MedRushTheme.textPrimary,
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                        ),
                      ),
                      TextSpan(
                        text: '#${widget.pedido.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: MedRushTheme.textPrimary,
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingXs),
          Row(
            children: [
              const Icon(LucideIcons.user,
                  size: 18, color: MedRushTheme.textSecondary),
              const SizedBox(width: MedRushTheme.spacingSm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Cliente: ',
                        style: TextStyle(
                          fontWeight: MedRushTheme.fontWeightBold,
                          color: MedRushTheme.textPrimary,
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                        ),
                      ),
                      TextSpan(
                        text: widget.pedido.pacienteNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: MedRushTheme.textPrimary,
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingXs),
          if (productosCount > 0) ...[
            Text(
              'Productos: $productosCount artículos',
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontWeight: MedRushTheme.fontWeightMedium,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            const Row(
              children: [
                Icon(LucideIcons.pill,
                    size: 18, color: MedRushTheme.textSecondary),
                SizedBox(width: MedRushTheme.spacingSm),
                Text(
                  'Productos',
                  style: TextStyle(
                    fontWeight: MedRushTheme.fontWeightBold,
                    color: MedRushTheme.textPrimary,
                    fontSize: MedRushTheme.fontSizeBodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MedRushTheme.spacingXs),
            ...widget.pedido.medicamentos.map((m) {
              final nombre = m['nombre']?.toString() ?? '-';
              final cantidad = m['cantidad']?.toString() ?? '1';
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: MedRushTheme.spacingXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.pill,
                        size: 16, color: MedRushTheme.textSecondary),
                    const SizedBox(width: MedRushTheme.spacingSm),
                    Expanded(
                      child: Text(
                        '$nombre (x$cantidad)',
                        style: const TextStyle(
                          color: MedRushTheme.textPrimary,
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: MedRushTheme.spacingXl),
          const Text(
            'Prueba de Entrega',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          _buildFotoEntregaSection(),
        ],
      ),
    );
  }

  // _buildInfoRow eliminado (diseño actualizado)

  Widget _buildFotoEntregaSection() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fotoEntrega != null) ...[
            // Mostrar foto seleccionada
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusSm),
                border: Border.all(color: MedRushTheme.borderLight),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusSm),
                child: Image.file(
                  _fotoEntrega!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingSm),

            // Información de la foto
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _tomarFoto,
                    icon: const Icon(LucideIcons.camera, size: 16),
                    label: const Text('Cambiar Foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MedRushTheme.primaryGreen,
                      side: const BorderSide(color: MedRushTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: MedRushTheme.spacingSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _eliminarFoto,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Estado vacío simple (sin contenedor anidado)
            const SizedBox(height: MedRushTheme.spacingSm),
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Aún no se ha tomado una foto',
                      style: TextStyle(
                        fontWeight: MedRushTheme.fontWeightBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: MedRushTheme.spacingXs),
                    const Text(
                      'Por favor, tome una foto del paquete entregado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MedRushTheme.textSecondary,
                        fontSize: MedRushTheme.fontSizeBodySmall,
                      ),
                    ),
                    const SizedBox(height: MedRushTheme.spacingMd),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _tomarFoto,
                      icon: const Icon(LucideIcons.camera, size: 18),
                      label: const Text('Tomar Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MedRushTheme.primaryGreen,
                        foregroundColor: MedRushTheme.textInverse,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _cancelarEntrega,
            icon: const Icon(LucideIcons.x, size: 18),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MedRushTheme.textSecondary,
              side: const BorderSide(color: MedRushTheme.borderLight),
              padding:
                  const EdgeInsets.symmetric(vertical: MedRushTheme.spacingMd),
            ),
          ),
        ),
        const SizedBox(width: MedRushTheme.spacingMd),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _iniciarFirma,
            icon: const Icon(LucideIcons.penTool, size: 18),
            label: const Text('Firmar y Entregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: MedRushTheme.textInverse,
              padding:
                  const EdgeInsets.symmetric(vertical: MedRushTheme.spacingMd),
            ),
          ),
        ),
      ],
    );
  }

  void _cancelarEntrega() {
    Navigator.of(context).pop();
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null) {
        final fotoFile = File(image.path);
        setState(() {
          _fotoEntrega = fotoFile;
        });

        logInfo('Foto de entrega tomada: ${image.path}');
      }
    } catch (e) {
      logError('Error al tomar foto', e);
      if (mounted) {
        NotificationService.showError(
          'Error al tomar foto: $e',
          context: context,
        );
      }
    }
  }

  void _eliminarFoto() {
    setState(() {
      _fotoEntrega = null;
    });
    logInfo('Foto de entrega eliminada');
  }

  Future<void> _iniciarFirma() async {
    // Navegar a la pantalla de firma
    final firmaSvg = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => FirmaScreen(
          pedidoId: widget.pedido.id,
        ),
      ),
    );

    if (firmaSvg != null && firmaSvg.isNotEmpty) {
      // Si se obtuvo una firma SVG, proceder con la entrega
      await _confirmarEntrega(firmaSvg);
    }
  }

  Future<void> _confirmarEntrega(String firmaSvg) async {
    // Mostrar confirmación final
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.packageOpen,
              color: MedRushTheme.primaryGreen,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Confirmar Entrega'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas confirmar la entrega de este pedido?',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: MedRushTheme.backgroundSecondary,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: MedRushTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${widget.pedido.id}',
                    style: const TextStyle(
                      fontWeight: MedRushTheme.fontWeightBold,
                      color: MedRushTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: MedRushTheme.spacingXs),
                  Text(
                    widget.pedido.pacienteNombre,
                    style: const TextStyle(
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: MedRushTheme.textInverse,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    // Procesar entrega
    setState(() {
      _isProcessing = true;
    });

    try {
      // Log información de la foto antes de enviar
      if (_fotoEntrega != null) {
        final fileSize = await _fotoEntrega!.length();
        final sizeInMB = StatusHelpers.formatearTamanoArchivo(fileSize);
        logInfo('Enviando foto de entrega: ${_fotoEntrega!.path}');
        logInfo('Tamaño de foto: $sizeInMB MB');
      }

      // Marcar pedido como entregado con la firma SVG y foto
      final resultado = await _pedidoRepository.marcarPedidoEntregado(
        widget.pedido.id,
        latitud: widget.pedido.latitudEntrega ?? 0.0,
        longitud: widget.pedido.longitudEntrega ?? 0.0,
        firmaDigitalPath: firmaSvg, // Enviar el SVG como texto
        fotoEntregaPath: _fotoEntrega?.path, // Enviar la foto si existe
      );

      if (mounted) {
        if (resultado.success) {
          NotificationService.showSuccess(
            'Pedido entregado exitosamente',
            context: context,
          );

          logInfo(
              'Pedido #${widget.pedido.id} entregado exitosamente con firma');

          // Cerrar pantalla y regresar
          Navigator.of(context).pop(true);
        } else {
          NotificationService.showError(
            'Error al entregar pedido: ${resultado.error ?? "Error desconocido"}',
            context: context,
          );
          logError('Error al entregar pedido', resultado.error);
        }
      }
    } catch (e) {
      logError('Error al procesar entrega', e);
      if (mounted) {
        NotificationService.showError(
          'Error al procesar entrega: $e',
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

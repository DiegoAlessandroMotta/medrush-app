import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:signature/signature.dart';

class FirmaScreen extends StatefulWidget {
  final String pedidoId;
  final String? firmaGuardada;
  final bool esModoEdicion;

  const FirmaScreen({
    super.key,
    required this.pedidoId,
    this.firmaGuardada,
    this.esModoEdicion = false,
  });

  @override
  State<FirmaScreen> createState() => _FirmaScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('pedidoId', pedidoId))
      ..add(StringProperty('firmaGuardada', firmaGuardada))
      ..add(DiagnosticsProperty<bool>('esModoEdicion', esModoEdicion));
  }
}

class _FirmaScreenState extends State<FirmaScreen> {
  final SignatureController _signatureController = SignatureController(
    exportBackgroundColor: MedRushTheme.backgroundSecondary,
  );
  bool _hasSignature = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hasSignature = widget.firmaGuardada != null;

    // Agregar listener al controlador
    _signatureController.addListener(_onSignatureChanged);

    // Si hay una firma guardada, cargarla en el canvas
    if (widget.firmaGuardada != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarFirmaGuardada();
      });
    }
  }

  void _onSignatureChanged() {
    final bool hasSignature = _signatureController.isNotEmpty;

    setState(() {
      _hasSignature = hasSignature;
    });
  }

  Future<void> _cargarFirmaGuardada() async {
    if (widget.firmaGuardada == null || widget.firmaGuardada!.isEmpty) {
      logInfo('📝 [FIRMA] No hay firma guardada para cargar');
      return;
    }

    try {
      logInfo('📝 [FIRMA] Cargando firma guardada...');
      logInfo(
          '📝 [FIRMA] Tamaño de firma guardada: ${widget.firmaGuardada!.length} caracteres');
      logInfo(
          '📝 [FIRMA] Inicio de firma guardada: ${widget.firmaGuardada!.substring(0, widget.firmaGuardada!.length > 100 ? 100 : widget.firmaGuardada!.length)}...');

      // Verificar si es base64 o URL
      final bool esBase64 = widget.firmaGuardada!.startsWith('data:image/');
      logInfo(
          '📝 [FIRMA] Tipo de contenido: ${esBase64 ? "Base64" : "URL/otro"}');

      // Por ahora solo marcamos que hay firma
      // TODO: Implementar carga visual de firma guardada
      setState(() {
        _hasSignature = true;
      });

      logInfo('✅ [FIRMA] Firma guardada detectada, modo edición activado');
    } catch (e) {
      logError('❌ [FIRMA] Error al cargar firma guardada', e);
      logError('❌ [FIRMA] Stack trace: ${StackTrace.current}');
      setState(() {
        _hasSignature = true;
      });
    }
  }

  @override
  void dispose() {
    _signatureController
      ..removeListener(_onSignatureChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: MedRushTheme.surface,
        elevation: 0,
        title: Text(
          widget.pedidoId.isNotEmpty
              ? (widget.esModoEdicion
                  ? 'Editar Firma de Entrega'
                  : 'Firma de Entrega')
              : 'Firma de Muestra',
          style: const TextStyle(
            color: MedRushTheme.textPrimary,
            fontSize: MedRushTheme.fontSizeHeadlineSmall,
            fontWeight: MedRushTheme.fontWeightBold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MedRushTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // Canvas de firma
          Expanded(
            child: _buildSignatureCanvas(),
          ),

          // Botones de acción
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSignatureCanvas() {
    return Container(
      margin: const EdgeInsets.all(MedRushTheme.spacingMd),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        child: Signature(
          controller: _signatureController,
          backgroundColor: MedRushTheme.backgroundSecondary,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingLg),
      child: Column(
        children: [
          // Botones de acción en una fila
          Row(
            children: [
              // Botón Deshacer (solo icono)
              Expanded(
                child: OutlinedButton(
                  onPressed: _signatureController.canUndo ? _undo : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MedRushTheme.textSecondary,
                    side: const BorderSide(color: MedRushTheme.borderLight),
                    padding: const EdgeInsets.symmetric(
                        vertical: MedRushTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusLg),
                    ),
                  ),
                  child: const Icon(Icons.undo),
                ),
              ),
              const SizedBox(width: MedRushTheme.spacingMd),
              // Botón Rehacer (solo icono)
              Expanded(
                child: OutlinedButton(
                  onPressed: _signatureController.canRedo ? _redo : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MedRushTheme.textSecondary,
                    side: const BorderSide(color: MedRushTheme.borderLight),
                    padding: const EdgeInsets.symmetric(
                        vertical: MedRushTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusLg),
                    ),
                  ),
                  child: const Icon(Icons.redo),
                ),
              ),
              const SizedBox(width: MedRushTheme.spacingMd),
              // Botón Guardar (solo icono)
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasSignature ? _guardarFirma : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedRushTheme.primaryGreen,
                    foregroundColor: MedRushTheme.textInverse,
                    padding: const EdgeInsets.symmetric(
                        vertical: MedRushTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusLg),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                ),
              ),
              const SizedBox(width: MedRushTheme.spacingMd),
              // Botón Limpiar (solo icono)
              Expanded(
                child: OutlinedButton(
                  onPressed: _limpiarFirma,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                        vertical: MedRushTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusLg),
                    ),
                  ),
                  child: const Icon(Icons.clear),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _undo() {
    logInfo('↩️ [FIRMA] Deshaciendo último trazo');
    _signatureController.undo();
    _onSignatureChanged();
  }

  void _redo() {
    logInfo('↪️ [FIRMA] Rehaciendo trazo');
    _signatureController.redo();
    _onSignatureChanged();
  }

  void _limpiarFirma() {
    logInfo('🗑️ [FIRMA] Limpiando firma completa');
    _signatureController.clear();
    _onSignatureChanged();
  }

  Future<void> _guardarFirma() async {
    if (!_hasSignature) {
      NotificationService.showWarning('Debes firmar antes de guardar',
          context: context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      logInfo(
          '💾 [FIRMA] Iniciando guardado de firma para pedido #${widget.pedidoId}');
      logInfo(
          '💾 [FIRMA] Puntos de firma: ${_signatureController.points.length}');

      // Generar firma en base64 usando la funcionalidad nativa de signature
      logInfo('💾 [FIRMA] Generando firma en base64...');
      final signatureBytes = await _signatureController.toPngBytes();
      final signatureBase64 = signatureBytes != null
          ? 'data:image/png;base64,${base64Encode(signatureBytes)}'
          : '';

      // Calcular tamaños
      final base64Size = signatureBase64.length;
      final base64SizeKB = (base64Size / 1024).toStringAsFixed(2);
      final originalBytesSize = signatureBytes?.length ?? 0;
      final originalSizeKB = (originalBytesSize / 1024).toStringAsFixed(2);

      logInfo('💾 [FIRMA] Firma base64 generada:');
      logInfo(
          '💾 [FIRMA] - Tamaño original: $originalSizeKB KB ($originalBytesSize bytes)');
      logInfo(
          '💾 [FIRMA] - Tamaño base64: $base64SizeKB KB ($base64Size caracteres)');
      logInfo(
          '💾 [FIRMA] - Factor de expansión: ${(base64Size / originalBytesSize).toStringAsFixed(2)}x');

      if (signatureBase64.isEmpty) {
        throw Exception('No se pudo generar la firma en base64');
      }

      // Devolver la firma como base64
      if (widget.pedidoId.isNotEmpty) {
        logInfo(
            '📝 [FIRMA] Firma base64 generada para pedido #${widget.pedidoId}');
      } else {
        logInfo('📝 [FIRMA] Modo de prueba - firma base64 generada');
      }

      logInfo('✅ [FIRMA] Firma base64 generada exitosamente');

      if (mounted) {
        NotificationService.showSuccess(
            widget.pedidoId.isNotEmpty
                ? 'Firma de entrega generada exitosamente'
                : 'Firma de muestra generada exitosamente',
            context: context);

        logInfo('📤 [FIRMA] Retornando base64 al caller');

        // Retornar el base64 al caller
        Navigator.of(context).pop(signatureBase64);
      }
    } catch (e) {
      logError('❌ [FIRMA] Error al guardar firma', e);
      logError('❌ [FIRMA] Stack trace: ${StackTrace.current}');

      if (mounted) {
        NotificationService.showError('Error al guardar la firma',
            context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        logInfo('🏁 [FIRMA] Proceso de guardado finalizado');
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('pedidoId', widget.pedidoId))
      ..add(StringProperty('firmaGuardada', widget.firmaGuardada))
      ..add(DiagnosticsProperty<bool>('esModoEdicion', widget.esModoEdicion));
  }
}

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/repositories/farmacia.repository.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/services/csv.service.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/validators.dart';
import 'package:url_launcher/url_launcher.dart';

/// Transición personalizada para la pantalla de CSV
class CsvScreenRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  CsvScreenRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          fullscreenDialog: true,
        );
}

class PedidosCsvScreen extends StatefulWidget {
  const PedidosCsvScreen({super.key});

  @override
  State<PedidosCsvScreen> createState() => _PedidosCsvScreenState();

  /// Navega a la pantalla con animación de slide desde la derecha
  static Future<T?> show<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      CsvScreenRoute<T>(
        child: const PedidosCsvScreen(),
      ),
    );
  }
}

class _PedidosCsvScreenState extends State<PedidosCsvScreen> {
  final PedidoRepository _pedidoRepository = PedidoRepository();

  List<Map<String, dynamic>> _csvData = [];
  List<Farmacia> _farmacias = [];
  Farmacia? _selectedFarmacia;
  bool _isLoading = false;
  bool _isUploading = false;

  bool _isDownloadingTemplate = false;
  String? _error;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _loadFarmacias();
  }

  Future<void> _loadFarmacias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FarmaciaRepository.loadFarmaciasWithState(
        errorMessage: AppLocalizations.of(context).errorLoadingPharmaciesForExport,
      );

      setState(() {
        _farmacias = result['farmacias'] as List<Farmacia>;
        _isLoading = result['isLoading'] as bool;
        _error = result['success'] as bool ? null : result['error'] as String?;
      });
    } catch (e) {
      logError('Error inesperado al cargar farmacias', e);
      setState(() {
        _error = 'Error al cargar farmacias: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final fileBytes = file.bytes;

        if (fileBytes != null) {
          // Intentar diferentes codificaciones
          String content;
          try {
            content = utf8.decode(fileBytes, allowMalformed: true);
          } catch (e) {
            logError('Error UTF-8, intentando Latin-1', e);
            try {
              content = latin1.decode(fileBytes, allowInvalid: true);
            } catch (e2) {
              logError('Error Latin-1, usando String.fromCharCodes', e2);
              // Si todo falla, usar String.fromCharCodes como último recurso
              content =
                  String.fromCharCodes(fileBytes.where((byte) => byte < 256));
            }
          }

          var csvData = CsvService.parseCsvContent(content);
          // Normalizar headers a claves esperadas por backend para vista previa/validación/subida
          csvData = CsvService.mapCsvDataToBackendKeys(csvData);

          // Parsear CSV para vista previa usando el método existente
          final List<List<dynamic>> csvRows = [];

          if (csvData.isNotEmpty) {
            // Agregar headers
            csvRows
              ..add(csvData.first.keys.toList())
              // Agregar primeras 10 filas
              ..addAll(csvData.take(10).map((row) => csvData.first.keys
                  .map((key) => row[key]?.toString() ?? '')
                  .toList()));
          }

          setState(() {
            _csvData = csvData;
            _fileName = fileName;
            _error = null;
          });

          logInfo('CSV cargado: $fileName con ${csvData.length} registros');
        }
      }
    } catch (e) {
      logError('Error al cargar archivo CSV', e);
      setState(() {
        _error = 'Error al cargar archivo CSV: $e';
      });
    }
  }

  Future<void> _uploadCsv() async {
    if (_selectedFarmacia == null) {
      NotificationService.showError(
          AppLocalizations.of(context).selectPharmacyRequired, context: context);
      return;
    }

    if (_csvData.isEmpty) {
      NotificationService.showError(
          AppLocalizations.of(context).noCsvDataToUpload, context: context);
      return;
    }

    // Validar datos antes de subir
    final validationResult = CsvService.validateCsvData(_csvData);
    if (!validationResult.isValid) {
      NotificationService.showError(
        '${AppLocalizations.of(context).csvValidationErrorsPrefix}\n${validationResult.errors.join('\n')}',
        context: context,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Convertir datos a CSV
      final csvContent = CsvService.convertDataToCsv(_csvData);

      // Si estamos en Web o preferimos evitar File IO, subir como bytes
      final bytes = utf8.encode(csvContent);
      final filename = _fileName ?? 'pedidos.csv';

      final result = await _pedidoRepository.uploadCsvBytes(
        bytes: bytes,
        filename: filename,
        farmaciaId: _selectedFarmacia!.id,
      );

      if (result.success) {
        if (mounted) {
          NotificationService.showSuccess(
            AppLocalizations.of(context).csvUploadSuccess,
            context: context,
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          NotificationService.showError(
            '${AppLocalizations.of(context).errorUploadingCsv}: ${result.error}',
            context: context,
          );
        }
      }
    } catch (e) {
      logError('Error al subir CSV', e);
      if (mounted) {
        NotificationService.showError(
          '${AppLocalizations.of(context).errorUploadingCsv}: $e',
          context: context,
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() {
      _isDownloadingTemplate = true;
    });

    try {
      // Usar el servicio CSV para generar y descargar la plantilla
      await CsvService.downloadPedidosTemplate();

      if (mounted) {
        NotificationService.showSuccess(
          AppLocalizations.of(context).csvTemplateReady,
          context: context,
        );
      }
    } catch (e) {
      logError('Error al descargar plantilla', e);
      if (mounted) {
        NotificationService.showError(
          '${AppLocalizations.of(context).errorDownloadingTemplate}: $e',
          context: context,
        );
      }
    } finally {
      setState(() {
        _isDownloadingTemplate = false;
      });
    }
  }

  void _showHelpDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.info, color: MedRushTheme.primaryBlue),
            const SizedBox(width: MedRushTheme.spacingSm),
            Text(l10n.csvHelpTitle),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.csvHelpHowToUse,
                style: const TextStyle(
                  fontWeight: MedRushTheme.fontWeightBold,
                  fontSize: MedRushTheme.fontSizeBodyLarge,
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingMd),
              _buildHelpStep(
                l10n.csvHelpStep1Title,
                l10n.csvHelpStep1Description,
                LucideIcons.download,
              ),
              _buildHelpStep(
                l10n.csvHelpStep2Title,
                l10n.csvHelpStep2Description,
                LucideIcons.fileText,
              ),
              _buildHelpStep(
                l10n.csvHelpStep3Title,
                l10n.csvHelpStep3Description,
                LucideIcons.upload,
              ),
              _buildHelpStep(
                l10n.csvHelpStep4Title,
                l10n.csvHelpStep4Description,
                LucideIcons.building,
              ),
              _buildHelpStep(
                l10n.csvHelpStep5Title,
                l10n.csvHelpStep5Description,
                LucideIcons.check,
              ),
              const SizedBox(height: MedRushTheme.spacingLg),
              Container(
                padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                decoration: BoxDecoration(
                  color: MedRushTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusMd),
                  border: Border.all(
                      color: MedRushTheme.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.csvHelpTipTitle,
                      style: const TextStyle(
                        fontWeight: MedRushTheme.fontWeightBold,
                        color: MedRushTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: MedRushTheme.spacingSm),
                    Text(
                      l10n.csvHelpTipCoordinates,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(MedRushTheme.spacingSm),
            decoration: BoxDecoration(
              color: MedRushTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            ),
            child: Icon(
              icon,
              size: 16,
              color: MedRushTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: MedRushTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: MedRushTheme.fontWeightBold,
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingXs),
                Text(
                  description,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: MedRushTheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).uploadOrdersFromCsvTitle,
          style: const TextStyle(
            color: MedRushTheme.textPrimary,
            fontSize: MedRushTheme.fontSizeHeadlineSmall,
            fontWeight: MedRushTheme.fontWeightBold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: MedRushTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: AppLocalizations.of(context).backTooltip,
        ),
        actions: [
          // Botón de descargar plantilla
          IconButton(
            icon: _isDownloadingTemplate
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          MedRushTheme.primaryBlue),
                    ),
                  )
                : const Icon(LucideIcons.download,
                    color: MedRushTheme.primaryBlue),
            onPressed: _isDownloadingTemplate ? null : _downloadTemplate,
            tooltip: AppLocalizations.of(context).downloadCsvTemplateTooltip,
          ),
          // Botón de ayuda/información
          IconButton(
            icon:
                const Icon(LucideIcons.info, color: MedRushTheme.textSecondary),
            onPressed: _showHelpDialog,
            tooltip: AppLocalizations.of(context).helpTooltip,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: _csvData.isNotEmpty ? _buildStatsFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Barra de progreso que muestra el estado del proceso
  Widget _buildProgressBar() {
    if (_csvData.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalRows = _csvData.length;
    final validRows = _csvData.where((row) {
      final ubicacion = row['ubicacion']?.toString() ?? '';
      return _parseCoordinates(ubicacion) != null;
    }).length;

    return Container(
      margin: const EdgeInsets.all(MedRushTheme.spacingLg),
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).validationProgressTitle,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyLarge,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingMd,
                  vertical: MedRushTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: MedRushTheme.primaryGreen,
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusMd),
                ),
                child: Text(
                  AppLocalizations.of(context).recordsValidCount(totalRows, validRows),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    fontWeight: MedRushTheme.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          LinearProgressIndicator(
            value: totalRows > 0 ? validRows / totalRows : 0,
            backgroundColor: MedRushTheme.backgroundSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(
              validRows == totalRows
                  ? MedRushTheme.primaryGreen
                  : MedRushTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          Text(
            validRows == totalRows
                ? AppLocalizations.of(context).allRecordsHaveValidCoordinates
                : AppLocalizations.of(context).recordsNeedValidCoordinates(totalRows - validRows),
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodySmall,
              color: validRows == totalRows
                  ? MedRushTheme.primaryGreen
                  : MedRushTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsFAB() {
    final totalRows = _csvData.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingMd,
        vertical: MedRushTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: MedRushTheme.primaryGreen,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        boxShadow: [
          BoxShadow(
            color: MedRushTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.database,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: MedRushTheme.spacingXs),
          Text(
            '$totalRows registros',
            style: const TextStyle(
              color: Colors.white,
              fontSize: MedRushTheme.fontSizeBodyMedium,
              fontWeight: MedRushTheme.fontWeightBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(MedRushTheme.primaryGreen),
          ),
          SizedBox(height: MedRushTheme.spacingMd),
          Text(
            'Cargando farmacias...',
            style: TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.x,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            _error ?? AppLocalizations.of(context).unknownError,
            style: const TextStyle(
              color: MedRushTheme.textPrimary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: _loadFarmacias,
            icon: const Icon(LucideIcons.refreshCw),
            label: Text(AppLocalizations.of(context).retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: MedRushTheme.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Barra de progreso/estado
        _buildProgressBar(),

        // Contenido principal con scroll
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MedRushTheme.spacingLg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Layout de 2 columnas para archivo CSV y farmacia
                  _buildTopControls(),
                  const SizedBox(height: MedRushTheme.spacingXl),

                  // Preview de datos
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildDataPreview(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopControls() {
    return Column(
      children: [
        // Sección principal de subida
        _buildMainUploadSection(),

        const SizedBox(height: MedRushTheme.spacingXl),

        // Sección de farmacia y procesamiento
        _buildPharmacyAndProcessSection(),
      ],
    );
  }

  /// Sección principal de subida centrada
  Widget _buildMainUploadSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          // Área de drag & drop principal - solo se muestra si no hay archivo
          if (_fileName == null)
            AnimatedSlide(
              offset: Offset.zero,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _buildMainDragDropArea(),
              ),
            ),

          // Estado del archivo si está cargado con animación
          if (_fileName != null)
            AnimatedSlide(
              offset: Offset.zero,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _buildFileStatusBar(),
              ),
            ),
        ],
      ),
    );
  }

  /// Área de drag & drop principal centrada
  Widget _buildMainDragDropArea() {
    return GestureDetector(
      onTap: _pickCsvFile,
      child: Container(
        width: double.infinity,
        height: 400, // Aumentado para pantalla completa
        decoration: BoxDecoration(
          color: MedRushTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
          border: Border.all(
            color: MedRushTheme.borderLight,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: MedRushTheme.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de nube verde
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingXl),
              decoration: BoxDecoration(
                color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.upload,
                size: 100,
                color: MedRushTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingXl),

            // Texto principal
            Text(
              AppLocalizations.of(context).dragDropCsvHere,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeTitleLarge,
                fontWeight: MedRushTheme.fontWeightBold,
                color: MedRushTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MedRushTheme.spacingMd),

            // Texto secundario en verde
            Text(
              AppLocalizations.of(context).orClickToSelectFile,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyLarge,
                color: MedRushTheme.primaryGreen,
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MedRushTheme.spacingLg),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: MedRushTheme.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 16,
                        color: MedRushTheme.textSecondary,
                      ),
                      const SizedBox(width: MedRushTheme.spacingXs),
                      Text(
                        AppLocalizations.of(context).fileInfoTitle,
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                          fontWeight: MedRushTheme.fontWeightMedium,
                          color: MedRushTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                  Text(
                    AppLocalizations.of(context).fileSizeFormatHint,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de estado del archivo cargado
  Widget _buildFileStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingMd,
        vertical: MedRushTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: MedRushTheme.primaryGreen,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.fileText,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: MedRushTheme.spacingSm),
          Expanded(
            child: Text(
              AppLocalizations.of(context).recordsLoadComplete(_csvData.length, _fileName ?? AppLocalizations.of(context).csvFileLabel),
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                fontWeight: MedRushTheme.fontWeightBold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _csvData.clear();
                _fileName = null;
              });
            },
            icon: const Icon(
              LucideIcons.x,
              color: Colors.white,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de farmacia y procesamiento
  Widget _buildPharmacyAndProcessSection() {
    return AnimatedSlide(
      offset: _fileName != null ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: _fileName != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              AppLocalizations.of(context).selectPharmacyToAssignOrders,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyLarge,
                fontWeight: MedRushTheme.fontWeightBold,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),

            // Fila con dropdown y botones
            Row(
              children: [
                // Selector de farmacia
                Expanded(
                  child: _buildPharmacyDropdown(),
                ),

                const SizedBox(width: MedRushTheme.spacingMd),

                // Botón de limpiar CSV
                _buildClearCsvButton(),

                const SizedBox(width: MedRushTheme.spacingSm),

                // Botón de procesar
                _buildProcessButton(),
              ],
            ),

            // Estado de validación
            if (_fileName != null && _selectedFarmacia != null) ...[
              const SizedBox(height: MedRushTheme.spacingMd),
              const Row(
                children: [
                  Icon(
                    LucideIcons.check,
                    color: MedRushTheme.primaryGreen,
                    size: 16,
                  ),
                  SizedBox(width: MedRushTheme.spacingSm),
                  Text(
                    'Archivo válido y farmacia seleccionada. Listo para procesar.',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                      color: MedRushTheme.primaryGreen,
                      fontWeight: MedRushTheme.fontWeightMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataPreview() {
    if (_csvData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingLg),
        decoration: BoxDecoration(
          color: MedRushTheme.surface,
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
          border: Border.all(color: MedRushTheme.borderLight),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.fileText,
                size: 64,
                color: MedRushTheme.textSecondary,
              ),
              const SizedBox(height: MedRushTheme.spacingLg),
              Text(
                AppLocalizations.of(context).noDataToShow,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeTitleMedium,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingSm),
              Text(
                AppLocalizations.of(context).selectCsvFileToPreview,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  color: MedRushTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        child: _buildDataTable(),
      ),
    );
  }

  /// Convierte un valor string a boolean para el checkbox
  /// Usa el método del CsvService para mantener consistencia con el backend
  bool _parseBooleanValue(String value) {
    return CsvService.parseBooleanValue(value);
  }

  /// Formatea el texto del header removiendo guiones bajos y capitalizando
  String _formatHeaderText(String header) {
    // Reemplazar guiones bajos con espacios
    String formatted = header.replaceAll('_', ' ');

    // Capitalizar cada palabra
    List<String> words = formatted.split(' ');
    words = words.map((word) {
      if (word.isEmpty) {
        return word;
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return words.join(' ');
  }

  /// Verifica si una columna es de tipo ubicación
  bool _isLocationColumn(String header) {
    final lowerHeader = header.toLowerCase();
    return lowerHeader.contains('ubicacion') ||
        lowerHeader.contains('ubicación') ||
        lowerHeader.contains('location') ||
        lowerHeader.contains('coordenadas') ||
        lowerHeader.contains('coordinates');
  }

  /// Verifica si una columna es de tipo de pedido
  bool _isTipoPedidoColumn(String header) {
    final lowerHeader = header.toLowerCase();
    return lowerHeader.contains('tipo') &&
        (lowerHeader.contains('pedido') || lowerHeader.contains('order'));
  }

  /// Extrae coordenadas de un texto de ubicación
  /// Formato esperado: "latitud, longitud" o "latitud,longitud"
  Map<String, double>? _parseCoordinates(String locationText) {
    if (locationText.isEmpty) {
      return null;
    }

    try {
      // Limpiar el texto y dividir por comas
      final cleanText = Validators.normalizeSpaces(locationText.trim());
      final parts = Validators.splitByCommasAndSpaces(cleanText);

      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);

        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }
    } catch (e) {
      logError('Error al parsear coordenadas: $locationText', e);
    }

    return null;
  }

  /// Abre Google Maps con las coordenadas proporcionadas
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
      logError('Error al abrir Google Maps', e);
      if (mounted) {
        NotificationService.showError(
          'No se pudo abrir Google Maps: $e',
          context: context,
        );
      }
    }
  }

  /// Construye una celda con dropdown para tipo de pedido
  Widget _buildTipoPedidoCell(String value, int row, String header) {
    final l10n = AppLocalizations.of(context);
    final tiposPedido = [
      {'value': 'medicamentos', 'label': l10n.medications},
      {'value': 'insumos_medicos', 'label': l10n.orderTypeMedicalSupplies},
      {'value': 'equipos_medicos', 'label': l10n.orderTypeMedicalEquipment},
      {
        'value': 'medicamentos_controlados',
        'label': l10n.orderTypeControlledMedications,
      },
    ];

    // Encontrar el tipo actual
    final tipoActual = tiposPedido.firstWhere(
      (tipo) => tipo['value'] == value.toLowerCase(),
      orElse: () => {'value': value, 'label': value},
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: ClipRect(
        child: DropdownButtonFormField<String>(
          initialValue: tipoActual['value'] as String,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            isDense: true,
          ),
          items: tiposPedido.map((tipo) {
            return DropdownMenuItem<String>(
              value: tipo['value'] as String,
              child: Text(
                tipo['label'] as String,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _csvData[row][header] = newValue;
              });
            }
          },
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            color: MedRushTheme.textPrimary,
          ),
          isExpanded: true,
        ),
      ),
    );
  }

  /// Construye una celda clickeable para ubicaciones
  Widget _buildLocationCell(String value, bool isEmpty) {
    if (isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.minus,
              color: MedRushTheme.textSecondary,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).noLocation,
              style: const TextStyle(
                color: MedRushTheme.textSecondary,
                fontSize: MedRushTheme.fontSizeBodySmall,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Intentar parsear coordenadas
    final coordinates = _parseCoordinates(value);

    if (coordinates != null) {
      // Si tiene coordenadas válidas, hacer clickeable
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: InkWell(
          onTap: () =>
              _openGoogleMaps(coordinates['lat']!, coordinates['lng']!),
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.mapPin,
                color: MedRushTheme.primaryGreen,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: MedRushTheme.primaryGreen,
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Si no tiene coordenadas válidas, mostrar como texto normal
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Tooltip(
          message: AppLocalizations.of(context).invalidCoordinatesFormat,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.mapPin,
                color: MedRushTheme.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: MedRushTheme.textSecondary,
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDataTable() {
    if (_csvData.isEmpty) {
      return const SizedBox.shrink();
    }

    final headers = _csvData.first.keys.toList();
    final maxRowsToShow = 50;
    final columnWidth = 200.0;
    final rowHeight = 56.0;

    // Crear columnas para TableView
    final columns = headers
        .map((header) => TableColumn(
              width: columnWidth,
            ))
        .toList();

    return TableView.builder(
      columns: columns,
      rowCount:
          _csvData.length > maxRowsToShow ? maxRowsToShow : _csvData.length,
      rowHeight: rowHeight,
      style: const TableViewStyle(
        dividers: TableViewDividersStyle(
          vertical: TableViewVerticalDividersStyle.symmetric(
            TableViewVerticalDividerStyle(
              color: MedRushTheme.borderLight,
            ),
          ),
          horizontal: TableViewHorizontalDividersStyle.symmetric(
            TableViewHorizontalDividerStyle(
              color: MedRushTheme.borderLight,
            ),
          ),
        ),
        scrollbars: TableViewScrollbarsStyle.symmetric(
          TableViewScrollbarStyle(
            interactive: true,
            enabled: TableViewScrollbarEnabled.always,
            thumbVisibility: WidgetStatePropertyAll(true),
            trackVisibility: WidgetStatePropertyAll(true),
          ),
        ),
      ),
      headerBuilder: (context, contentBuilder) => contentBuilder(
        context,
        (context, column) => Container(
          height: rowHeight,
          decoration: const BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            border: Border(
              bottom: BorderSide(
                color: MedRushTheme.borderLight,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatHeaderText(headers[column]),
                style: const TextStyle(
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
      headerHeight: rowHeight,
      rowBuilder: (context, row, contentBuilder) {
        final rowData = _csvData[row];
        final isEven = row % 2 == 0;

        return Container(
          height: rowHeight,
          color: isEven ? MedRushTheme.surface : MedRushTheme.backgroundPrimary,
          child: contentBuilder(
            context,
            (context, column) {
              final header = headers[column];
              final value = rowData[header]?.toString() ?? '';
              final isEmpty = value.isEmpty;

              // Si es la columna de "requiere_firma_especial", mostrar checkbox
              if (header.toLowerCase().contains('requiere_firma') ||
                  header.toLowerCase().contains('firma_especial')) {
                final boolValue = _parseBooleanValue(value);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Center(
                    child: Checkbox(
                      value: boolValue,
                      onChanged: (newValue) {
                        setState(() {
                          _csvData[row][header] = newValue.toString();
                        });
                      },
                      activeColor: MedRushTheme.primaryGreen,
                      checkColor: MedRushTheme.surface,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                );
              }

              // Si es una columna de ubicación, hacer clickeable para Google Maps
              if (_isLocationColumn(header)) {
                return _buildLocationCell(value, isEmpty);
              }

              // Si es la columna de tipo de pedido, mostrar dropdown
              if (_isTipoPedidoColumn(header)) {
                return _buildTipoPedidoCell(value, row, header);
              }

              // Para otras columnas, mostrar texto normal
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Tooltip(
                  message: isEmpty ? AppLocalizations.of(context).emptyField : value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEmpty)
                        const Icon(
                          LucideIcons.minus,
                          color: MedRushTheme.textSecondary,
                          size: 12,
                        )
                      else
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isEmpty
                                  ? MedRushTheme.textSecondary
                                  : MedRushTheme.textPrimary,
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              fontStyle:
                                  isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Botón de procesar
  Widget _buildProcessButton() {
    final isReady =
        _fileName != null && _selectedFarmacia != null && !_isUploading;

    return ElevatedButton.icon(
      onPressed: isReady ? _uploadCsv : null,
      icon: _isUploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(LucideIcons.upload, size: 20),
      label: Text(
        _isUploading ? AppLocalizations.of(context).processing : AppLocalizations.of(context).processButton,
        style: const TextStyle(
          fontSize: MedRushTheme.fontSizeBodyMedium,
          fontWeight: MedRushTheme.fontWeightBold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isReady ? MedRushTheme.primaryGreen : MedRushTheme.textSecondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: MedRushTheme.spacingLg,
          vertical: MedRushTheme.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        ),
        minimumSize: const Size(140, 50),
        fixedSize: const Size(140, 50),
      ),
    );
  }

  /// Dropdown de farmacia simplificado
  Widget _buildPharmacyDropdown() {
    final isFarmaciaRequired = _csvData.isNotEmpty && _selectedFarmacia == null;

    return DropdownButtonFormField<Farmacia>(
      initialValue: _selectedFarmacia,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
          borderSide: BorderSide(
            color:
                isFarmaciaRequired ? Colors.orange : MedRushTheme.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
          borderSide: BorderSide(
            color:
                isFarmaciaRequired ? Colors.orange : MedRushTheme.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
          borderSide: BorderSide(
            color:
                isFarmaciaRequired ? Colors.orange : MedRushTheme.primaryGreen,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MedRushTheme.spacingMd,
          vertical: MedRushTheme.spacingMd,
        ),
        suffixIcon: const Icon(
          LucideIcons.chevronDown,
          color: MedRushTheme.textSecondary,
        ),
      ),
      hint: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFarmaciaRequired) ...[
            const Icon(
              LucideIcons.triangleAlert,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isFarmaciaRequired
                ? AppLocalizations.of(context).selectAPharmacy
                : AppLocalizations.of(context).centralPharmacy,
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: isFarmaciaRequired
                  ? Colors.orange.shade700
                  : MedRushTheme.textSecondary,
            ),
          ),
        ],
      ),
      items: _farmacias.map((farmacia) {
        return DropdownMenuItem<Farmacia>(
          value: farmacia,
          child: Text(
            farmacia.nombre,
            style: const TextStyle(fontSize: MedRushTheme.fontSizeBodyMedium),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (Farmacia? value) {
        setState(() {
          _selectedFarmacia = value;
        });
      },
    );
  }

  /// Botón de limpiar CSV
  Widget _buildClearCsvButton() {
    return Tooltip(
      message: AppLocalizations.of(context).clearCsv,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _csvData.clear();
            _fileName = null;
            _selectedFarmacia = null;
          });
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
          ),
          child: const Icon(
            LucideIcons.trash2,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

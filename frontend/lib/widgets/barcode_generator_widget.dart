import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/utils/validators.dart';

class BarcodeGeneratorWidget extends StatefulWidget {
  final String? initialBarcode;
  final int? pedidoId;
  final String? farmaciaId;
  final bool showControls;
  final Function(String)? onBarcodeGenerated;

  const BarcodeGeneratorWidget({
    super.key,
    this.initialBarcode,
    this.pedidoId,
    this.farmaciaId,
    this.showControls = true,
    this.onBarcodeGenerated,
  });

  @override
  State<BarcodeGeneratorWidget> createState() => _BarcodeGeneratorWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('initialBarcode', initialBarcode))
      ..add(IntProperty('pedidoId', pedidoId))
      ..add(StringProperty('farmaciaId', farmaciaId))
      ..add(DiagnosticsProperty<bool>('showControls', showControls))
      ..add(ObjectFlagProperty<Function(String p1)?>.has(
          'onBarcodeGenerated', onBarcodeGenerated));
  }
}

class _BarcodeGeneratorWidgetState extends State<BarcodeGeneratorWidget> {
  late String _currentBarcode;

  @override
  void initState() {
    super.initState();
    _currentBarcode = widget.initialBarcode ?? _generateExampleBarcode();
  }

  String _generateExampleBarcode() {
    // Generar código de ejemplo para demostración
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'MR${StatusHelpers.formatearIdConCeros(int.tryParse(widget.pedidoId?.toString() ?? '1') ?? 1)}${StatusHelpers.formatearIdConCeros(int.tryParse(widget.farmaciaId?.toString() ?? '1') ?? 1, digitos: 3)}${timestamp.substring(8)}${timestamp.substring(0, 6)}';
  }

  void _regenerateBarcode() {
    setState(() {
      _currentBarcode = _generateExampleBarcode();
    });
    widget.onBarcodeGenerated?.call(_currentBarcode);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentBarcode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).barcodeCodeCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFormat() {
    // Nota: El formato ahora se determina automáticamente por el tipo de código
    // que viene del backend. Este método se mantiene para compatibilidad.
    setState(() {
      _currentBarcode = _generateExampleBarcode();
    });
    widget.onBarcodeGenerated?.call(_currentBarcode);
  }

  bool _isNumericBarcode(String barcode) {
    return Validators.isNumericOnly(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              AppLocalizations.of(context).barcodeTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Información del código
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Código:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Row(
                        children: [
                          SelectableText(
                            _currentBarcode,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: _copyToClipboard,
                            tooltip: AppLocalizations.of(context).copyCodeTooltip,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.pedidoId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).orderIdShortLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${widget.pedidoId}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.farmaciaId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).pharmacyIdLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          widget.farmaciaId!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Código de barras visual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: BarcodeWidget(
                barcode: _isNumericBarcode(_currentBarcode)
                    ? Barcode.code128()
                    : Barcode.code39(),
                data: _currentBarcode,
                width: 250,
                height: 80,
                errorBuilder: (context, error) => Container(
                  width: 250,
                  height: 80,
                  color: Colors.red[100],
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).errorGeneratingBarcode,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                ),
              ),
            ),

            if (widget.showControls) ...[
              const SizedBox(height: 16),

              // Controles
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _regenerateBarcode,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(AppLocalizations.of(context).regenerateButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: _toggleFormat,
                    icon: Icon(
                      _isNumericBarcode(_currentBarcode)
                          ? Icons.text_fields
                          : Icons.numbers,
                      size: 18,
                    ),
                    label: Text(
                      _isNumericBarcode(_currentBarcode)
                          ? AppLocalizations.of(context).alphanumericLabel
                          : AppLocalizations.of(context).numericLabel,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(AppLocalizations.of(context).copyButton),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Información del formato
              Text(
                _isNumericBarcode(_currentBarcode)
                    ? AppLocalizations.of(context).formatNumericDigits(_currentBarcode.length)
                    : AppLocalizations.of(context).formatAlphanumericChars(_currentBarcode.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget simplificado para mostrar solo el código
class SimpleBarcodeWidget extends StatelessWidget {
  final String barcode;
  final double? width;
  final double? height;
  final bool showText;

  const SimpleBarcodeWidget({
    super.key,
    required this.barcode,
    this.width = 150,
    this.height = 50,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = _isValidBarcode(barcode);

    if (!isValid) {
      return Container(
        width: width,
        height: height,
        color: Colors.red[100],
        child: Center(
          child: Text(
            AppLocalizations.of(context).invalidCode,
            style: TextStyle(color: Colors.red[800]),
          ),
        ),
      );
    }

    final isNumeric = _isNumericBarcode(barcode);

    return BarcodeWidget(
      barcode: isNumeric ? Barcode.code128() : Barcode.code39(),
      data: barcode,
      width: width!,
      height: height!,
      drawText: showText,
      errorBuilder: (context, error) => Container(
        width: width,
        height: height,
        color: Colors.red[100],
        child: Center(
          child: Text(
            AppLocalizations.of(context).errorLabel,
            style: TextStyle(color: Colors.red[800]),
          ),
        ),
      ),
    );
  }

  bool _isNumericBarcode(String barcode) {
    return Validators.isNumericOnly(barcode);
  }

  bool _isValidBarcode(String barcode) {
    if (barcode.isEmpty) {
      return false;
    }
    // Validación básica: debe tener al menos 5 caracteres
    return barcode.length >= 5;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('barcode', barcode))
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('height', height))
      ..add(DiagnosticsProperty<bool>('showText', showText));
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medrush/theme/theme.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScanScreen extends StatefulWidget {
  final String modo;
  final String? pedidoId;

  const BarcodeScanScreen({super.key, required this.modo, this.pedidoId});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('modo', modo))
      ..add(StringProperty('pedidoId', pedidoId));
  }
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _scannerStarted = false;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    // Solicitar permisos de cámara
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _scannerStarted = true;
      });
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de Cámara'),
        content: const Text(
            'La aplicación necesita acceso a la cámara para escanear códigos de barras.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && _scannedCode == null) {
      final code = barcodes.first.displayValue ?? barcodes.first.rawValue ?? '';

      if (code.isNotEmpty) {
        setState(() {
          _scannedCode = code;
        });

        // Pausar el escáner
        cameraController.stop();

        // Procesar el código escaneado
        _processScannedCode(code);
      }
    }
  }

  void _processScannedCode(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
            ),
            const SizedBox(width: 8),
            const Text('Código Escaneado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modo: ${widget.modo}'),
            if (widget.pedidoId != null) Text('Pedido: #${widget.pedidoId}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: MedRushTheme.fontWeightBold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getSuccessMessage(widget.modo),
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _resetScanner,
            child: const Text('Escanear Otro'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, code);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _getSuccessMessage(String modo) {
    switch (modo.toLowerCase()) {
      case 'entrega':
        return '✓ Código de entrega verificado correctamente';
      case 'recogida':
        return '✓ Código de recogida verificado correctamente';
      case 'verificacion':
        return '✓ Código verificado correctamente';
      default:
        return '✓ Código escaneado correctamente';
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedCode = null;
    });
    Navigator.pop(context);
    cameraController.start();
  }

  void _toggleFlash() {
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    cameraController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear - ${widget.modo}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_scannerStarted) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: _toggleFlash,
              tooltip: 'Flash',
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
              tooltip: 'Cambiar Cámara',
            ),
          ],
        ],
      ),
      body: _scannerStarted ? _buildScanner() : _buildPermissionRequest(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Escáner de cámara
        MobileScanner(
          controller: cameraController,
          onDetect: _onDetect,
        ),

        // Overlay con marco de escaneo
        _buildScannerOverlay(),

        // Información en la parte superior
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Card(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escaneo para: ${widget.modo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: MedRushTheme.fontSizeBodyLarge,
                      fontWeight: MedRushTheme.fontWeightBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.pedidoId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pedido #${widget.pedidoId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Instrucciones en la parte inferior
        const Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Card(
            color: Colors.black54,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Apunta la cámara hacia el código de barras o QR.\nEl escaneo será automático.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Esquinas del marco
            ...List.generate(4, (index) {
              return Positioned(
                top: index < 2 ? 0 : null,
                bottom: index >= 2 ? 0 : null,
                left: index % 2 == 0 ? 0 : null,
                right: index % 2 == 1 ? 0 : null,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      top: index < 2
                          ? const BorderSide(color: Colors.red, width: 4)
                          : BorderSide.none,
                      bottom: index >= 2
                          ? const BorderSide(color: Colors.red, width: 4)
                          : BorderSide.none,
                      left: index % 2 == 0
                          ? const BorderSide(color: Colors.red, width: 4)
                          : BorderSide.none,
                      right: index % 2 == 1
                          ? const BorderSide(color: Colors.red, width: 4)
                          : BorderSide.none,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Permiso de Cámara Requerido',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: MedRushTheme.fontWeightBold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para escanear códigos de barras, necesitamos acceso a tu cámara.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: MedRushTheme.fontSizeBodyLarge,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final status = await Permission.camera.request();
                  if (status.isGranted) {
                    setState(() {
                      _scannerStarted = true;
                    });
                  } else {
                    _showPermissionDeniedDialog();
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Permitir Acceso a Cámara'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MobileScannerController>(
        'cameraController', cameraController));
  }
}

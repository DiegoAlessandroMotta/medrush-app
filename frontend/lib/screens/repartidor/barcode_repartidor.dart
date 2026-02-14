import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/screens/repartidor/entregar_repartidor.dart';
import 'package:medrush/screens/repartidor/modules/pedidos/pedidos_detalle_repartidor.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class BarcodeRepartidorScreen extends StatefulWidget {
  const BarcodeRepartidorScreen({super.key});

  @override
  State<BarcodeRepartidorScreen> createState() =>
      _BarcodeRepartidorScreenState();
}

class _BarcodeRepartidorScreenState extends State<BarcodeRepartidorScreen>
    with WidgetsBindingObserver {
  final PedidoRepository _pedidoRepository = PedidoRepository();
  MobileScannerController? _scannerController;
  bool _isScanning = true;
  bool _isProcessing = false;
  Pedido? _pedidoEncontrado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      formats: [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Detener el escáner antes de liberar recursos
    _scannerController?.stop();
    // Esperar un momento para que se liberen los buffers
    Future.delayed(const Duration(milliseconds: 100), () {
      _scannerController?.dispose();
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Manejar el ciclo de vida de la app para liberar recursos de la cámara
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _scannerController?.stop();
      case AppLifecycleState.resumed:
        if (_isScanning && !_isProcessing) {
          _scannerController?.start();
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      body: _buildScannerArea(),
    );
  }

  Widget _buildScannerArea() {
    if (_isProcessing) {
      return Stack(
        children: [
          // Fondo oscuro
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        MedRushTheme.primaryGreen),
                  ),
                  const SizedBox(height: MedRushTheme.spacingLg),
                  Text(
                    AppLocalizations.of(context).processingBarcode,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyLarge,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón de retroceso
          Positioned(
            top: MediaQuery.of(context).padding.top + MedRushTheme.spacingMd,
            left: MedRushTheme.spacingMd,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusLg),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      );
    }

    // Si hay un pedido encontrado, mostrar dialog y mantener cámara
    if (_pedidoEncontrado != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarDialogPedidoEncontrado();
      });
    }

    return Stack(
      children: [
        // Cámara del escáner ocupando toda la pantalla
        MobileScanner(
          controller: _scannerController!,
          onDetect: _onBarcodeDetected,
          errorBuilder: _buildScannerError,
        ),

        // Overlay profesional de escaneo (minimalista B/N)
        if (_isScanning) const _ScannerOverlay(),

        // Botón de retroceso flotante
        Positioned(
          top: MediaQuery.of(context).padding.top + MedRushTheme.spacingMd,
          left: MedRushTheme.spacingMd,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        // Texto de ayuda inferior removido
      ],
    );
  }

  Widget _buildScannerError(BuildContext context, MobileScannerException error) {
    final isUnsupported = error.errorCode == MobileScannerErrorCode.unsupported;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: MedRushTheme.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).scannerErrorTitle,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeTitleMedium,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).scannerErrorMessage,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              if (kIsWeb || isUnsupported) ...[
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).scannerWebHint,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogPedidoEncontrado() {
    if (_pedidoEncontrado == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          title: const SizedBox.shrink(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila con título del pedido y botón de cerrar
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.package,
                          color: MedRushTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: MedRushTheme.spacingXs),
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context).orderIdShort}${_pedidoEncontrado!.id}',
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeBodyMedium,
                              color: MedRushTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón de cerrar (X)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetScanner();
                    },
                    icon: const Icon(
                      LucideIcons.x,
                      color: MedRushTheme.textSecondary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MedRushTheme.spacingMd),
              // Información del pedido
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
                    // Nombre del cliente (resaltado)
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.user,
                          color: MedRushTheme.primaryGreen,
                          size: 18,
                        ),
                        const SizedBox(width: MedRushTheme.spacingXs),
                        Expanded(
                          child: Text(
                            _pedidoEncontrado!.pacienteNombre,
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeTitleMedium,
                              fontWeight: MedRushTheme.fontWeightBold,
                              color: MedRushTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MedRushTheme.spacingSm),

                    // Estado del pedido
                    Row(
                      children: [
                        Icon(
                          StatusHelpers.estadoPedidoIcon(
                              _pedidoEncontrado!.estado),
                          color: StatusHelpers.estadoPedidoColor(
                              _pedidoEncontrado!.estado),
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingXs),
                        Text(
                          AppLocalizations.of(context).statusLabel,
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: MedRushTheme.textSecondary,
                            fontWeight: MedRushTheme.fontWeightMedium,
                          ),
                        ),
                        Text(
                          StatusHelpers.estadoPedidoTexto(
                              _pedidoEncontrado!.estado, AppLocalizations.of(context)),
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: StatusHelpers.estadoPedidoColor(
                                _pedidoEncontrado!.estado),
                            fontWeight: MedRushTheme.fontWeightBold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MedRushTheme.spacingSm),

                    // Repartidor asignado (si aplica)
                    if (_pedidoEncontrado!.repartidor != null ||
                        _pedidoEncontrado!.repartidorId != null) ...[
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.user,
                            color: MedRushTheme.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: MedRushTheme.spacingXs),
                            Text(
                              AppLocalizations.of(context).assignedTo,
                              style: const TextStyle(
                                fontSize: MedRushTheme.fontSizeBodySmall,
                                color: MedRushTheme.textSecondary,
                                fontWeight: MedRushTheme.fontWeightMedium,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              _pedidoEncontrado!.repartidor?.nombre ??
                                  _pedidoEncontrado!.repartidorId ??
                                  '-',
                              style: const TextStyle(
                                fontSize: MedRushTheme.fontSizeBodySmall,
                                color: MedRushTheme.textPrimary,
                                fontWeight: MedRushTheme.fontWeightBold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MedRushTheme.spacingSm),
                    ],

                    // Dirección de entrega
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          color: MedRushTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingXs),
                        Expanded(
                          child: Text(
                            _pedidoEncontrado!.direccionEntrega,
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              color: MedRushTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Firma especial (si aplica)
                    if (_pedidoEncontrado!.requiereFirmaEspecial == true) ...[
                      const SizedBox(height: MedRushTheme.spacingSm),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.penTool,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: MedRushTheme.spacingXs),
                          Text(
                            AppLocalizations.of(context).requiresSpecialSignature,
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              color: Colors.orange,
                              fontWeight: MedRushTheme.fontWeightBold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingLg),
              const Text(
                '¿Qué deseas hacer con este pedido?',
                style: TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  color: MedRushTheme.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            // Botones en la misma fila
            Row(
              children: [
                // Botón Ver Detalle
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _verDetallePedido,
                    icon: const Icon(LucideIcons.eye, size: 15),
                    label: Text(AppLocalizations.of(context).viewDetails),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MedRushTheme.textSecondary,
                      side: const BorderSide(color: MedRushTheme.borderLight),
                    ),
                  ),
                ),
                const SizedBox(width: MedRushTheme.spacingSm),
                // Botón Asignar (solo si está pendiente)
                if (_pedidoEncontrado!.estado == EstadoPedido.pendiente)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _asignarPedido();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MedRushTheme.primaryGreen,
                        foregroundColor: MedRushTheme.textInverse,
                      ),
                      child: Text(AppLocalizations.of(context).assign),
                    ),
                  ),
                // Botón Entregar (solo si está en ruta)
                if (_pedidoEncontrado!.estado == EstadoPedido.enRuta)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _entregarPedido();
                      },
                      icon: const Icon(LucideIcons.packageOpen, size: 15),
                      label: Text(AppLocalizations.of(context).deliver),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MedRushTheme.primaryBlue,
                        foregroundColor: MedRushTheme.textInverse,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String scannedCode = barcodes.first.rawValue ?? '';
      logInfo('Código de barras escaneado: $scannedCode');

      // Detener la cámara inmediatamente
      _scannerController?.stop();

      setState(() {
        _isScanning = false;
        _isProcessing = true;
      });

      _procesarCodigoBarras(scannedCode);
    }
  }

  Future<void> _procesarCodigoBarras(String codigoBarras) async {
    try {
      logInfo('Buscando pedido con código: $codigoBarras');

      // Buscar el pedido por código de barras
      final resultado =
          await _pedidoRepository.obtenerPedidoPorCodigoBarra(codigoBarras);

      if (!mounted) {
        return;
      }

      if (resultado.success && resultado.data != null) {
        setState(() {
          _pedidoEncontrado = resultado.data;
          _isProcessing = false;
        });

        logInfo('Pedido encontrado: #${_pedidoEncontrado!.id}');
      } else {
        setState(() {
          _isProcessing = false;
        });

        logWarning('Pedido no encontrado con código: $codigoBarras');
        NotificationService.showError(
          AppLocalizations.of(context).noOrderWithBarcode,
          context: context,
        );

        // Volver a escanear después de un momento
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
            });
          }
        });
      }
    } catch (e) {
      logError('Error al procesar código de barras', e);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        NotificationService.showError(
          AppLocalizations.of(context).errorProcessingBarcode,
          context: context,
        );

        // Volver a escanear después de un momento
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
            });
          }
        });
      }
    }
  }

  void _verDetallePedido() {
    if (_pedidoEncontrado != null) {
      showMaterialModalBottomSheet(
        context: context,
        expand: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PedidoDetalleScreen(
          pedidoId: _pedidoEncontrado!.id,
        ),
      );
    }
  }

  void _entregarPedido() {
    if (_pedidoEncontrado != null) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => EntregarRepartidorScreen(
            pedido: _pedidoEncontrado!,
          ),
        ),
      )
          .then((entregado) {
        if (entregado == true) {
          // Si se entregó exitosamente, resetear el escáner
          _resetScanner();
        }
      });
    }
  }

  Future<void> _asignarPedido() async {
    if (_pedidoEncontrado == null) {
      return;
    }

    try {
      // Mostrar confirmación antes de asignar
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                LucideIcons.userPlus,
                color: MedRushTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              Text(AppLocalizations.of(context).assignOrder),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).assignOrderConfirm,
                style: const TextStyle(
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
                      '${AppLocalizations.of(context).orderIdShort}${_pedidoEncontrado!.id}',
                      style: const TextStyle(
                        fontWeight: MedRushTheme.fontWeightBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: MedRushTheme.spacingXs),
                    Text(
                      _pedidoEncontrado!.pacienteNombre,
                      style: const TextStyle(
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: MedRushTheme.spacingXs),
                    Text(
                      _pedidoEncontrado!.direccionEntrega,
                      style: const TextStyle(
                        color: MedRushTheme.textSecondary,
                        fontSize: MedRushTheme.fontSizeBodySmall,
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedRushTheme.primaryGreen,
                foregroundColor: MedRushTheme.textInverse,
              ),
              child: Text(AppLocalizations.of(context).assign),
            ),
          ],
        ),
      );

      if (confirmar != true || !mounted) {
        return;
      }

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(MedRushTheme.primaryGreen),
          ),
        ),
      );

      // Obtener el ID del repartidor actual desde el provider de autenticación
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final repartidorId = authProvider.usuario?.id;

      if (repartidorId == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar loading
          NotificationService.showError(
            AppLocalizations.of(context).couldNotGetDriverInfo,
            context: context,
          );
        }
        return;
      }

      // Asignar el pedido
      final resultado = await _pedidoRepository.asignarPedido(
        _pedidoEncontrado!.id,
        repartidorId,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        if (resultado.success && resultado.data != null) {
          NotificationService.showSuccess(
            AppLocalizations.of(context).orderAssignedSuccess,
            context: context,
          );

          logInfo(
              'Pedido #${_pedidoEncontrado!.id} asignado al repartidor $repartidorId');

          // Después de asignar exitosamente, resetear el escáner para continuar escaneando
          _resetScanner();
        } else {
          NotificationService.showError(
            AppLocalizations.of(context).errorAssigningOrderDetail(
                resultado.error ?? AppLocalizations.of(context).unknownError),
            context: context,
          );
          logError('Error al asignar pedido', resultado.error);
        }
      }
    } catch (e) {
      logError('Error al asignar pedido', e);
      if (mounted) {
        Navigator.of(context).pop();
        NotificationService.showError(
          AppLocalizations.of(context).errorAssigningOrderDetail(e.toString()),
          context: context,
        );
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _pedidoEncontrado = null;
      _isScanning = true;
      _isProcessing = false;
    });

    // Reiniciar el controlador del escáner de forma segura
    _scannerController?.stop().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _isScanning) {
          _scannerController?.start();
        }
      });
    });
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingTop = MediaQuery.of(context).padding.top;

    // Dimensiones de la ventana de escaneo
    final windowWidth = size.width * 0.75;
    final windowHeight = windowWidth * 0.75; // relación aproximada 4:3
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, (size.height + paddingTop) / 2),
      width: windowWidth,
      height: windowHeight,
    );

    return IgnorePointer(
      child: CustomPaint(
        size: Size(size.width, size.height),
        painter: _ScannerOverlayPainter(scanWindow: rect),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  _ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    // Máscara oscura
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Crear path con recorte (ventana)
    final background = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
      ..addRRect(
          RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)));
    final mask = Path.combine(PathOperation.difference, background, cutout);
    canvas.drawPath(mask, overlayPaint);

    // Esquinas blancas (L)
    const cornerLen = 22.0;
    const cornerWidth = 3.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final r = RRect.fromRectAndRadius(scanWindow, const Radius.circular(12))
        .outerRect;

    // top-left
    canvas
      ..drawLine(
          Offset(r.left, r.top), Offset(r.left + cornerLen, r.top), cornerPaint)
      ..drawLine(
          Offset(r.left, r.top), Offset(r.left, r.top + cornerLen), cornerPaint)

      // top-right
      ..drawLine(Offset(r.right, r.top), Offset(r.right - cornerLen, r.top),
          cornerPaint)
      ..drawLine(Offset(r.right, r.top), Offset(r.right, r.top + cornerLen),
          cornerPaint)

      // bottom-left
      ..drawLine(Offset(r.left, r.bottom), Offset(r.left + cornerLen, r.bottom),
          cornerPaint)
      ..drawLine(Offset(r.left, r.bottom), Offset(r.left, r.bottom - cornerLen),
          cornerPaint)

      // bottom-right
      ..drawLine(Offset(r.right, r.bottom),
          Offset(r.right - cornerLen, r.bottom), cornerPaint)
      ..drawLine(Offset(r.right, r.bottom),
          Offset(r.right, r.bottom - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';

/// Widget mejorado para mostrar imágenes de red con manejo de URLs temporales
class NetworkImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool showRefreshButton;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onImageError;

  const NetworkImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.showRefreshButton = false,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  State<NetworkImageWidget> createState() => _NetworkImageWidgetState();
}

class _NetworkImageWidgetState extends State<NetworkImageWidget> {
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(NetworkImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Comparar URLs de forma más robusta (trim y case insensitive)
    final oldUrl = oldWidget.imageUrl?.trim().toLowerCase();
    final newUrl = widget.imageUrl?.trim().toLowerCase();
    if (oldUrl != newUrl) {
      logInfo('🔄 URL de imagen cambió: $oldUrl -> $newUrl');
      _retryCount = 0; // Reset retry count on URL change
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _currentImageUrl = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageUrl = widget.imageUrl!;

      // Validar URL firmada antes de intentar cargarla
      if (!BaseApi.isValidSignedUrl(imageUrl)) {
        logError('❌ URL firmada inválida: $imageUrl');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
          widget.onImageError?.call();
        }
        return;
      }

      // Verificar si la URL está próxima a expirar
      final isNearExpiry = BaseApi.isUrlNearExpiry(imageUrl);
      if (isNearExpiry) {
        logWarning('⚠️ URL firmada próxima a expirar: $imageUrl');
      }

      // Para Web, agregar timestamp para forzar recarga si es necesario
      String finalUrl = imageUrl;
      if (kIsWeb && _retryCount > 0) {
        final separator = imageUrl.contains('?') ? '&' : '?';
        finalUrl =
            '$imageUrl${separator}t=${DateTime.now().millisecondsSinceEpoch}';
        logInfo('🔄 Forzando recarga con timestamp: $finalUrl');
      }

      if (mounted) {
        setState(() {
          _currentImageUrl = finalUrl;
          _isLoading = false;
          _hasError = false;
        });
        logInfo('✅ Imagen cargada exitosamente: $finalUrl');
      }
    } catch (e) {
      logError('❌ Error al cargar imagen: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        widget.onImageError?.call();
      }
    }
  }

  void _refreshImage() {
    _retryCount++;
    if (_retryCount <= _maxRetries) {
      logInfo(
          '🔄 Reintentando carga de imagen (intento $_retryCount/$_maxRetries)');
      _loadImage();
    } else {
      logError('❌ Máximo de reintentos alcanzado para la imagen');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError || _currentImageUrl == null) {
      return _buildErrorWidget();
    }

    return _buildImageWidget();
  }

  Widget _buildImageWidget() {
    Widget image = Image.network(
      _currentImageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // Usar key para forzar recarga en Web cuando cambie la URL
      key: ValueKey(_currentImageUrl),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          widget.onImageLoaded?.call();
          return child;
        }
        return _buildLoadingIndicator(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        logError('❌ Error al cargar imagen en Image.network: $error');
        widget.onImageError?.call();
        return _buildErrorWidget();
      },
    );

    if (widget.borderRadius != null) {
      image = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    if (widget.showRefreshButton) {
      return Stack(
        children: [
          image,
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _refreshImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return image;
  }

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cargando imagen...',
              style: TextStyle(
                fontSize: 12,
                color: MedRushTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: (widget.width != null && widget.height != null)
                  ? (widget.width! < widget.height!
                      ? widget.width! * 0.3
                      : widget.height! * 0.3)
                  : 24,
              color: MedRushTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            const Text(
              'Sin imagen',
              style: TextStyle(
                fontSize: 12,
                color: MedRushTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: (widget.width != null && widget.height != null)
                  ? (widget.width! < widget.height!
                      ? widget.width! * 0.3
                      : widget.height! * 0.3)
                  : 24,
              color: Colors.red,
            ),
            const SizedBox(height: 4),
            const Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
            if (widget.showRefreshButton) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _refreshImage,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(AppLocalizations.of(context).retry),
                style: TextButton.styleFrom(
                  foregroundColor: MedRushTheme.primaryGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

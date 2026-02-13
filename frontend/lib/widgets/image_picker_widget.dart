import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final String? userId;
  final Function(String? imageUrl)? onImageChanged;
  final double size;
  final bool showRemoveButton;
  final String? placeholderText;
  final String? customPath;
  final String? uploadEndpoint;
  final bool isCircular;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    this.userId,
    this.onImageChanged,
    this.size = 120,
    this.showRemoveButton = true,
    this.placeholderText,
    this.customPath,
    this.uploadEndpoint, // Se construirá dinámicamente con userId
    this.isCircular = true, // Por defecto circular para compatibilidad
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('initialImageUrl', initialImageUrl))
      ..add(StringProperty('userId', userId))
      ..add(ObjectFlagProperty<Function(String? imageUrl)?>.has(
          'onImageChanged', onImageChanged))
      ..add(DoubleProperty('size', size))
      ..add(DiagnosticsProperty<bool>('showRemoveButton', showRemoveButton))
      ..add(StringProperty('placeholderText', placeholderText))
      ..add(StringProperty('customPath', customPath))
      ..add(StringProperty('uploadEndpoint', uploadEndpoint));
  }
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
    debugPrint(
        'ImagePickerWidget initState: _currentImageUrl = $_currentImageUrl');
    debugPrint(
        'ImagePickerWidget initState: widget.initialImageUrl = ${widget.initialImageUrl}');
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImageUrl != widget.initialImageUrl) {
      debugPrint(
          'ImagePickerWidget: URL actualizada de "${oldWidget.initialImageUrl}" a "${widget.initialImageUrl}"');
      setState(() {
        _currentImageUrl = widget.initialImageUrl;
      });
      debugPrint('ImagePickerWidget: _currentImageUrl = $_currentImageUrl');
    }
  }

  void _showError(String message) {
    if (mounted) {
      NotificationService.showError(
        message,
        context: context,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Usar BaseApi en lugar de StorageService
      final XFile? imageFile = await BaseApi.pickImage();

      if (imageFile != null && widget.userId != null) {
        // Subir imagen usando BaseApi
        try {
          // Construir endpoint dinámicamente si no se proporciona
          final String endpoint =
              widget.uploadEndpoint ?? EndpointManager.userFoto(widget.userId!);

          final String? uploadedUrl = await BaseApi.uploadImage(
            imageFile: imageFile,
            userId: widget.userId!,
            customPath: widget.customPath,
            endpoint: endpoint,
          );

          if (uploadedUrl != null) {
            // Verificar si la URL es accesible (solo en Web para diagnóstico)
            if (kIsWeb) {
              final isAccessible = await BaseApi.isUrlAccessible(uploadedUrl);
              if (!isAccessible) {
                _showError(
                    'Imagen subida pero no accesible. Verifique CORS/HTTPS.');
              }
            }

            setState(() {
              _currentImageUrl = uploadedUrl;
              _isUploading = false;
            });
            widget.onImageChanged?.call(uploadedUrl);
          } else {
            setState(() {
              _isUploading = false;
            });
            _showError('Error al subir la imagen: No se recibió URL');
          }
        } catch (e) {
          setState(() {
            _isUploading = false;
          });
          _showError('Error al subir la imagen: $e');
        }
      } else {
        setState(() {
          _isUploading = false;
        });
        if (widget.userId == null) {
          _showError('ID de usuario requerido');
        }
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _removeImage() async {
    if (_currentImageUrl != null) {
      try {
        setState(() {
          _isUploading = true;
        });

        // Usar BaseApi para eliminar imagen
        final success = await BaseApi.deleteImage(
          _currentImageUrl!,
          endpoint:
              widget.uploadEndpoint ?? EndpointManager.userFoto(widget.userId!),
        );

        if (success) {
          setState(() {
            _currentImageUrl = null;
            _isUploading = false;
          });
          widget.onImageChanged?.call(null);
        } else {
          setState(() {
            _isUploading = false;
          });
          _showError('Error al eliminar la imagen');
        }
      } catch (e) {
        _showError('Error al eliminar imagen: $e');
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context).gallery),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context).camera),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'ImagePickerWidget build: _isUploading=$_isUploading, _currentImageUrl=$_currentImageUrl');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contenedor de la imagen
        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: MedRushTheme.backgroundSecondary,
              borderRadius: widget.isCircular
                  ? BorderRadius.circular(widget.size / 2)
                  : BorderRadius.circular(12),
              border: Border.all(
                color: MedRushTheme.borderLight,
                width: 2,
              ),
            ),
            child: _isUploading
                ? _buildLoadingIndicator()
                : _currentImageUrl != null
                    ? _buildImageWidget()
                    : _buildPlaceholder(),
          ),
        ),

        const SizedBox(height: 8),

        // Botón de eliminar (si está habilitado y hay imagen)
        if (widget.showRemoveButton &&
            _currentImageUrl != null &&
            !_isUploading)
          TextButton.icon(
            onPressed: _removeImage,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(AppLocalizations.of(context).delete),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(height: 8),
          Text(
            'Subiendo...',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    debugPrint(
        'ImagePickerWidget: Construyendo imagen con URL: $_currentImageUrl');
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: _buildNetworkImage(),
    );
  }

  Widget _buildNetworkImage() {
    // Para Flutter Web, usar un enfoque diferente
    if (kIsWeb) {
      return _buildWebImage();
    } else {
      return _buildMobileImage();
    }
  }

  Widget _buildWebImage() {
    // Para Flutter Web, usar un enfoque más simple y directo
    return Image.network(
      _currentImageUrl!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      // Configuración específica para web
      cacheWidth: widget.size.toInt(),
      cacheHeight: widget.size.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('ImagePickerWidget (Web): Imagen cargada exitosamente');
          return child;
        }
        debugPrint(
            'ImagePickerWidget (Web): Cargando imagen... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
        return _buildLoadingIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('ImagePickerWidget (Web): Error al cargar imagen: $error');
        debugPrint('URL problemática: $_currentImageUrl');

        // Para web, mostrar un mensaje de error más específico
        return _buildWebErrorWidget();
      },
    );
  }

  Widget _buildWebErrorWidget() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(widget.size / 2),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: widget.size * 0.3,
            color: Colors.red,
          ),
          const SizedBox(height: 4),
          const Text(
            'Error CORS',
            style: TextStyle(
              fontSize: 10,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Web restriction',
            style: TextStyle(
              fontSize: 8,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileImage() {
    return Image.network(
      _currentImageUrl!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      cacheWidth: widget.size.toInt(),
      cacheHeight: widget.size.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('ImagePickerWidget (Mobile): Imagen cargada exitosamente');
          return child;
        }
        return _buildLoadingIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
            'ImagePickerWidget (Mobile): Error al cargar imagen: $error');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: widget.size * 0.3,
          color: MedRushTheme.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          widget.placeholderText ?? 'Agregar foto',
          style: const TextStyle(
            fontSize: 12,
            color: MedRushTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

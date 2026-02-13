import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/screens/repartidor/modules/perfil/perfl_token.dart';
// UsuarioRepository eliminado - no existe en el backend
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/network_image_widget.dart';
import 'package:medrush/widgets/web_smooth_scroll_wrapper.dart';
import 'package:provider/provider.dart';

class PerfilRepartidorScreen extends StatefulWidget {
  const PerfilRepartidorScreen({super.key});

  @override
  State<PerfilRepartidorScreen> createState() => _PerfilRepartidorScreenState();
}

class _PerfilRepartidorScreenState extends State<PerfilRepartidorScreen> {
  // UsuarioRepository eliminado - no existe en el backend
  Usuario? _usuarioActual;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  // Repository para operaciones de repartidor
  final RepartidorRepository _repartidorRepository = RepartidorRepository();

  // Controladores para edición
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _licenciaController = TextEditingController();
  final TextEditingController _vehiculoController = TextEditingController();

  // Controladores para cambio de contraseña
  final TextEditingController _passwordActualController =
      TextEditingController();
  final TextEditingController _passwordNuevaController =
      TextEditingController();
  final TextEditingController _passwordConfirmacionController =
      TextEditingController();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarPerfilUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _licenciaController.dispose();
    _vehiculoController.dispose();
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfilUsuario() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      logInfo('🔄 Cargando perfil del repartidor...');

      // Obtener usuario actual desde AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usuarioActual = authProvider.usuario;

      if (usuarioActual == null) {
        logError('❌ No hay usuario autenticado');
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          NotificationService.showError(
              AppLocalizations.of(context).noUserAuthenticated,
              context: context);
        }
        return;
      }

      logInfo(
          '👤 Usuario autenticado: ${usuarioActual.nombre} (${usuarioActual.id})');

      // Usar el usuario del AuthProvider directamente
      setState(() {
        _usuarioActual = usuarioActual;
        _isLoading = false;
      });

      // Inicializar controladores con datos actuales
      _inicializarControladores();

      logInfo('✅ Perfil cargado exitosamente desde AuthProvider');
    } catch (e) {
      logError('❌ Error al cargar perfil', e);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).errorLoadingProfile,
            context: context);
      }
    }
  }

  void _inicializarControladores() {
    if (_usuarioActual != null && mounted) {
      final l10n = AppLocalizations.of(context);
      _nombreController.text = _usuarioActual!.nombre;
      _emailController.text = _usuarioActual!.email;
      _telefonoController.text = _usuarioActual!.telefono ?? '';
      _licenciaController.text = _usuarioActual!.licenciaNumero ?? '';
      _vehiculoController.text = _usuarioActual!.vehiculoCompleto(l10n);
    }
  }

  Future<void> _mostrarOpcionesFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: MedRushTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MedRushTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingLg),

                Text(
                  AppLocalizations.of(context).changeProfilePhoto,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeTitleMedium,
                    fontWeight: MedRushTheme.fontWeightBold,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingLg),

                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoOption(
                        icon: LucideIcons.camera,
                        label: AppLocalizations.of(context).camera,
                        onTap: () {
                          Navigator.pop(context);
                          _seleccionarFoto(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: MedRushTheme.spacingMd),
                    Expanded(
                      child: _buildPhotoOption(
                        icon: LucideIcons.image,
                        label: AppLocalizations.of(context).gallery,
                        onTap: () {
                          Navigator.pop(context);
                          _seleccionarFoto(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),

                if (_usuarioActual?.foto != null &&
                    _usuarioActual!.foto!.isNotEmpty) ...[
                  const SizedBox(height: MedRushTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: _buildPhotoOption(
                      icon: LucideIcons.trash2,
                      label: AppLocalizations.of(context).deletePhoto,
                      onTap: () {
                        Navigator.pop(context);
                        _eliminarFoto();
                      },
                      isDestructive: true,
                    ),
                  ),
                ],

                const SizedBox(height: MedRushTheme.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
      child: Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingLg),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : MedRushTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.3)
                : MedRushTheme.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isDestructive ? Colors.red : MedRushTheme.primaryGreen,
            ),
            const SizedBox(height: MedRushTheme.spacingSm),
            Text(
              label,
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                fontWeight: MedRushTheme.fontWeightMedium,
                color: isDestructive ? Colors.red : MedRushTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _subirFoto(File(image.path));
      }
    } catch (e) {
      logError('❌ Error al seleccionar foto', e);
      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).photoSelectError,
            context: context);
      }
    }
  }

  Future<void> _subirFoto(File imageFile) async {
    if (_usuarioActual == null) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      logInfo('📸 Subiendo foto de perfil...');

      final result = await BaseApi.uploadProfilePicture(
        _usuarioActual!.id,
        imageFile,
      );

      if (result.success && result.data != null) {
        logInfo('✅ Foto de perfil actualizada exitosamente');

        // Actualizar la URL de la foto en el usuario actual inmediatamente
        if (_usuarioActual != null && result.data != null) {
          setState(() {
            _usuarioActual = _usuarioActual!.copyWith(foto: result.data);
          });
          logInfo('🔄 UI actualizada con nueva URL de foto: ${result.data}');
        }

        // Actualizar el usuario en el AuthProvider
        if (!mounted) {
          {}
          return;
        }
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshProfile();

        // Actualizar el usuario local con la nueva foto del AuthProvider
        final usuarioActualizado = authProvider.usuario;
        if (usuarioActualizado != null) {
          setState(() {
            _usuarioActual = usuarioActualizado;
          });
        }

        if (mounted) {
          NotificationService.showSuccess(
              AppLocalizations.of(context).profilePhotoUpdated, context: context);
        }
      } else {
        logError('❌ Error al subir foto: ${result.error}');
        if (mounted) {
          NotificationService.showError(
              result.error ?? AppLocalizations.of(context).photoUpdateError,
              context: context);
        }
      }
    } catch (e) {
      logError('❌ Error al subir foto', e);
      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).photoUpdateError,
            context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _eliminarFoto() async {
    if (_usuarioActual == null) {
      return;
    }

    // Mostrar confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.trash2, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).deletePhoto),
          ],
        ),
        content: Text(
            AppLocalizations.of(context).confirmDeleteProfilePhotoQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      logInfo('🗑️ Eliminando foto de perfil...');

      final result = await BaseApi.uploadProfilePicture(
        _usuarioActual!.id,
        null, // Sin archivo = eliminar
      );

      if (result.success) {
        logInfo('✅ Foto de perfil eliminada exitosamente');

        // Actualizar la URL de la foto en el usuario actual inmediatamente
        if (_usuarioActual != null) {
          setState(() {
            _usuarioActual = _usuarioActual!.copyWith();
          });
          logInfo('🔄 UI actualizada - foto eliminada');
        }
        {}
        // Actualizar el usuario en el AuthProvider
        if (!mounted) {
          return;
        }
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshProfile();

        // Actualizar el usuario local con los datos actualizados del AuthProvider
        final usuarioActualizado = authProvider.usuario;
        if (usuarioActualizado != null) {
          setState(() {
            _usuarioActual = usuarioActualizado;
          });
        }

        if (mounted) {
          NotificationService.showSuccess(
              AppLocalizations.of(context).profilePhotoDeleted, context: context);
        }
      } else {
        logError('❌ Error al eliminar foto: ${result.error}');
        if (mounted) {
          NotificationService.showError(
              result.error ??
                  AppLocalizations.of(context).errorDeletingPhoto,
              context: context);
        }
      }
    } catch (e) {
      logError('❌ Error al eliminar foto', e);
      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).errorDeletingPhoto,
            context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Widget _buildPasswordSection() {
    return _buildInfoCard(
      title: AppLocalizations.of(context).securitySectionTitle,
      icon: LucideIcons.lock,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoCambioPassword,
            icon: const Icon(LucideIcons.key, size: 16),
            label: Text(AppLocalizations.of(context).changePassword),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusLg),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _mostrarDialogoCambioPassword() async {
    // Limpiar controladores
    _passwordActualController.clear();
    _passwordNuevaController.clear();
    _passwordConfirmacionController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.key, color: MedRushTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).changePassword),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).changePasswordInstruction,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  color: MedRushTheme.textSecondary,
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingLg),
              TextField(
                controller: _passwordActualController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).currentPassword,
                  prefixIcon: const Icon(LucideIcons.lock),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingMd),
              TextField(
                controller: _passwordNuevaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).newPassword,
                  prefixIcon: const Icon(LucideIcons.key),
                  border: const OutlineInputBorder(),
                  helperText: AppLocalizations.of(context).min8Characters,
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingMd),
              TextField(
                controller: _passwordConfirmacionController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).confirmNewPassword,
                  prefixIcon: const Icon(LucideIcons.key),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validarFormularioPassword()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).changeButton),
          ),
        ],
      ),
    );

    if (result == true) {
      await _cambiarPassword();
    }
  }

  bool _validarFormularioPassword() {
    final passwordActual = _passwordActualController.text.trim();
    final passwordNueva = _passwordNuevaController.text.trim();
    final passwordConfirmacion = _passwordConfirmacionController.text.trim();

    if (passwordActual.isEmpty) {
      NotificationService.showError(
          AppLocalizations.of(context).enterCurrentPassword, context: context);
      return false;
    }

    if (passwordNueva.isEmpty) {
      NotificationService.showError(
          AppLocalizations.of(context).enterNewPassword, context: context);
      return false;
    }

    if (passwordNueva.length < 8) {
      NotificationService.showError(
          AppLocalizations.of(context).newPasswordMin8Chars, context: context);
      return false;
    }

    if (passwordNueva != passwordConfirmacion) {
      NotificationService.showError(
          AppLocalizations.of(context).passwordsDoNotMatch, context: context);
      return false;
    }

    if (passwordActual == passwordNueva) {
      NotificationService.showError(
          AppLocalizations.of(context).passwordMustBeDifferent, context: context);
      return false;
    }

    return true;
  }

  Future<void> _cambiarPassword() async {
    if (_usuarioActual == null) {
      return;
    }

    try {
      logInfo('🔐 Cambiando contraseña del repartidor...');

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: MedRushTheme.primaryGreen,
          ),
        ),
      );

      // Usar el repositorio para cambiar la contraseña
      final result = await _repartidorRepository.cambiarPassword(
        repartidorId: _usuarioActual!.id,
        nuevaPassword: _passwordNuevaController.text.trim(),
        confirmacionPassword: _passwordConfirmacionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (result.success) {
          logInfo('✅ Contraseña actualizada exitosamente');

          // Limpiar formulario
          _passwordActualController.clear();
          _passwordNuevaController.clear();
          _passwordConfirmacionController.clear();

          NotificationService.showSuccess(
            AppLocalizations.of(context).passwordChangedSuccess,
            context: context,
          );
        } else {
          logError('❌ Error al cambiar contraseña: ${result.error}');
          NotificationService.showError(
            result.error ??
                AppLocalizations.of(context).errorChangingPasswordShort,
            context: context,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        logError('❌ Error al cambiar contraseña', e);
        NotificationService.showError(
          AppLocalizations.of(context).errorChangingPassword(e.toString()),
          context: context,
        );
      }
    }
  }

  // Edición de perfil deshabilitada para repartidor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'fab_sesiones_repartidor',
        tooltip: AppLocalizations.of(context).activeSessions,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PerfilTokensScreen(),
            ),
          );
        },
        backgroundColor: MedRushTheme.primaryGreen,
        foregroundColor: MedRushTheme.textInverse,
        child: const Icon(LucideIcons.userRoundSearch, size: 18),
      ),
      body: WebSmoothScrollWrapper(
        child: _isLoading
            ? _buildLoadingState()
            : _usuarioActual != null
                ? _buildPerfilContent()
                : _buildErrorState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: MedRushTheme.primaryGreen,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            AppLocalizations.of(context).loadingProfile,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
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
            Icons.error_outline,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            AppLocalizations.of(context).errorLoadingProfile,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          ElevatedButton(
            onPressed: _cargarPerfilUsuario,
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: MedRushTheme.textInverse,
            ),
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilContent() {
    return SingleChildScrollView(
      controller: PrimaryScrollController.of(context),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        MedRushTheme.spacingLg,
        MedRushTheme.spacingLg,
        MedRushTheme.spacingLg,
        MedRushTheme.spacingXl +
            80, // FIX: Padding extra para el bottom navigation
      ),
      child: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: MedRushTheme.spacingXl),
          _buildPersonalInfoSection(),
          const SizedBox(height: MedRushTheme.spacingLg),
          _buildProfessionalInfoSection(),
          const SizedBox(height: MedRushTheme.spacingLg),
          _buildStatusSection(),
          const SizedBox(height: MedRushTheme.spacingLg),
          _buildPasswordSection(),
          const SizedBox(height: MedRushTheme.spacingLg),
          _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: MedRushTheme.spacingMd),
          Text(
            _usuarioActual!.nombre,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MedRushTheme.spacingXs),
          Text(
            _usuarioActual!.email,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _mostrarOpcionesFoto,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: MedRushTheme.primaryGreen,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: _usuarioActual!.foto != null &&
                      _usuarioActual!.foto!.isNotEmpty
                  ? NetworkImageWidget(
                      imageUrl: _usuarioActual!.foto!,
                      width: 100,
                      height: 100,
                      placeholder: _buildAvatarFallback(),
                      errorWidget: _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
          ),

          // Indicador de carga
          if (_isUploadingPhoto)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: MedRushTheme.primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),

          // Botón de cambio de foto
          if (!_isUploadingPhoto)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MedRushTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MedRushTheme.surface,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 16,
                  color: MedRushTheme.textInverse,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return ColoredBox(
      color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
      child: const Icon(
        LucideIcons.user,
        size: 50,
        color: MedRushTheme.primaryGreen,
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildInfoCard(
      title: AppLocalizations.of(context).personalInfo,
      icon: LucideIcons.user,
      children: [
        _buildInfoRow(
          label: AppLocalizations.of(context).name,
          value: _nombreController.text,
          icon: LucideIcons.user,
          controller: _nombreController,
        ),
        _buildInfoRow(
          label: AppLocalizations.of(context).email,
          value: _emailController.text,
          icon: LucideIcons.mail,
          controller: _emailController,
        ),
        _buildInfoRow(
          label: AppLocalizations.of(context).phone,
          value: _telefonoController.text,
          icon: LucideIcons.phone,
          controller: _telefonoController,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    return _buildInfoCard(
      title: AppLocalizations.of(context).professionalInfo,
      icon: LucideIcons.briefcase,
      children: [
        _buildInfoRow(
          label: AppLocalizations.of(context).drivingLicense,
          value: _licenciaController.text,
          icon: LucideIcons.car,
          controller: _licenciaController,
        ),
        _buildInfoRow(
          label: AppLocalizations.of(context).vehicle,
          value: _vehiculoController.text,
          icon: LucideIcons.truck,
          controller: _vehiculoController,
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return _buildInfoCard(
      title: AppLocalizations.of(context).systemStatus,
      icon: LucideIcons.settings,
      children: [
        _buildStatusRow(
          label: AppLocalizations.of(context).driverStatus,
          value: _usuarioActual!.estadoRepartidor != null
              ? StatusHelpers.estadoRepartidorTexto(
                  _usuarioActual!.estadoRepartidor!, AppLocalizations.of(context))
              : AppLocalizations.of(context).notAssigned,
          icon: StatusHelpers.estadoRepartidorIcon(
              _usuarioActual!.estadoRepartidor),
          color: _usuarioActual!.estadoRepartidor != null
              ? StatusHelpers.estadoRepartidorColor(
                  _usuarioActual!.estadoRepartidor!)
              : MedRushTheme.textSecondary,
        ),
        _buildStatusRow(
          label: AppLocalizations.of(context).activeUser,
          value: _usuarioActual!.activo
              ? AppLocalizations.of(context).yes
              : AppLocalizations.of(context).no,
          icon: _usuarioActual!.activo ? LucideIcons.check : LucideIcons.x,
          color:
              _usuarioActual!.activo ? MedRushTheme.primaryGreen : Colors.red,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
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
          Row(
            children: [
              Icon(
                icon,
                color: MedRushTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeTitleMedium,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    bool isEditing = false,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MedRushTheme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            ),
            child: Icon(
              icon,
              size: 18,
              color: MedRushTheme.textSecondary,
            ),
          ),
          const SizedBox(width: MedRushTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textSecondary,
                    fontWeight: MedRushTheme.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingXs),
                if (isEditing && controller != null)
                  TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                      color: MedRushTheme.textPrimary,
                      fontWeight: MedRushTheme.fontWeightMedium,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MedRushTheme.spacingSm,
                        vertical: MedRushTheme.spacingXs,
                      ),
                    ),
                  )
                else
                  Text(
                    value.isEmpty
                        ? AppLocalizations.of(context).notSpecified
                        : value,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                      color: MedRushTheme.textPrimary,
                      fontWeight: MedRushTheme.fontWeightMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: MedRushTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textSecondary,
                    fontWeight: MedRushTheme.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingXs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    color: color,
                    fontWeight: MedRushTheme.fontWeightMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
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
          const Text(
            'Sesión',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              fontWeight: MedRushTheme.fontWeightMedium,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(AppLocalizations.of(context).logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusLg),
                ),
              ),
              onPressed: () => _mostrarDialogoLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).logout),
          ],
        ),
        content: Text(AppLocalizations.of(context).logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).logout),
          ),
        ],
      ),
    );
  }

  // Métodos de firma eliminados

  Future<void> _logout() async {
    try {
      logInfo('🚪 Cerrando sesión del repartidor...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        logInfo('✅ Sesión cerrada exitosamente');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      logError('❌ Error al cerrar sesión', e);
      if (mounted) {
        NotificationService.showError(
            AppLocalizations.of(context).errorLoggingOut, context: context);
      }
    }
  }
}

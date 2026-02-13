import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/screens/admin/modules/configuracion/google_api_metrics_widget.dart';
import 'package:medrush/screens/admin/modules/configuracion/limpieza_pedidos_widget.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/validators.dart';
import 'package:provider/provider.dart';

class ConfiguracionAdminScreen extends StatelessWidget {
  const ConfiguracionAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsTitle),
        backgroundColor: MedRushTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const ConfiguracionAdminContent(),
    );
  }
}

// Widget de contenido sin Scaffold para usar en AdminMainScreen
class ConfiguracionAdminContent extends StatefulWidget {
  const ConfiguracionAdminContent({super.key});

  @override
  State<ConfiguracionAdminContent> createState() =>
      _ConfiguracionAdminContentState();
}

class _ConfiguracionAdminContentState extends State<ConfiguracionAdminContent> {
  bool _isProfileExpanded = false;
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _hasPendingProfileChanges = false;
  bool _hasPendingPasswordChanges = false;
  bool _isSyncingProfileControllers = false;
  bool _hasInitializedProfile = false;
  bool _isPasswordExpanded = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _nombreController.addListener(_onProfileFieldChanged);
    _emailController.addListener(_onProfileFieldChanged);
    _telefonoController.addListener(_onProfileFieldChanged);
    _currentPasswordController.addListener(_onPasswordFieldChanged);
    _newPasswordController.addListener(_onPasswordFieldChanged);
    _confirmPasswordController.addListener(_onPasswordFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedProfile) {
      final authProvider = context.read<AuthProvider>();
      _syncProfileControllers(authProvider.usuario);
      _hasInitializedProfile = true;
    }
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onProfileFieldChanged);
    _emailController.removeListener(_onProfileFieldChanged);
    _telefonoController.removeListener(_onProfileFieldChanged);
    _currentPasswordController.removeListener(_onPasswordFieldChanged);
    _newPasswordController.removeListener(_onPasswordFieldChanged);
    _confirmPasswordController.removeListener(_onPasswordFieldChanged);

    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _syncProfileControllers(Usuario? usuario) {
    _isSyncingProfileControllers = true;

    final nombre = usuario?.nombre ?? '';
    final email = usuario?.email ?? '';
    final telefono = usuario?.telefono ?? '';

    if (_nombreController.text != nombre) {
      _nombreController.value = TextEditingValue(
        text: nombre,
        selection: TextSelection.collapsed(offset: nombre.length),
      );
    }

    if (_emailController.text != email) {
      _emailController.value = TextEditingValue(
        text: email,
        selection: TextSelection.collapsed(offset: email.length),
      );
    }

    if (_telefonoController.text != telefono) {
      _telefonoController.value = TextEditingValue(
        text: telefono,
        selection: TextSelection.collapsed(offset: telefono.length),
      );
    }

    _isSyncingProfileControllers = false;

    if (_hasPendingProfileChanges) {
      if (mounted) {
        setState(() {
          _hasPendingProfileChanges = false;
        });
      } else {
        _hasPendingProfileChanges = false;
      }
    }
  }

  void _maybeSyncProfileControllers(Usuario? usuario) {
    if (_hasPendingProfileChanges) {
      return;
    }

    final nombre = usuario?.nombre ?? '';
    final email = usuario?.email ?? '';
    final telefono = usuario?.telefono ?? '';

    final needsSync = _nombreController.text != nombre ||
        _emailController.text != email ||
        _telefonoController.text != telefono;

    if (needsSync) {
      _syncProfileControllers(usuario);
    }
  }

  void _onProfileFieldChanged() {
    if (_isSyncingProfileControllers) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final usuario = authProvider.usuario;

    if (usuario == null) {
      if (_hasPendingProfileChanges) {
        setState(() {
          _hasPendingProfileChanges = false;
        });
      }
      return;
    }

    final currentNombre = _nombreController.text.trim();
    final currentEmail = _emailController.text.trim();
    final currentTelefono = _telefonoController.text.trim();

    final hasChanges = currentNombre != usuario.nombre ||
        currentEmail != usuario.email ||
        currentTelefono != (usuario.telefono ?? '');

    if (hasChanges != _hasPendingProfileChanges) {
      setState(() {
        _hasPendingProfileChanges = hasChanges;
      });
    }
  }

  void _onPasswordFieldChanged() {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final hasChanges = currentPassword.isNotEmpty ||
        newPassword.isNotEmpty ||
        confirmPassword.isNotEmpty;

    if (hasChanges != _hasPendingPasswordChanges) {
      setState(() {
        _hasPendingPasswordChanges = hasChanges;
      });
    }
  }

  void _resetPasswordForm() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _hasPendingPasswordChanges = false;
    });
  }

  Future<void> _handlePasswordSubmit(AuthProvider authProvider) async {
    if (_isSavingPassword) {
      return;
    }

    final formState = _passwordFormKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSavingPassword = true;
    });

    // TODO: Integrar con endpoint protegido cuando el backend esté listo.

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingPassword = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).passwordUpdateAvailable,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    _resetPasswordForm();
  }

  Future<void> _handleProfileSubmit(AuthProvider authProvider) async {
    if (_isSavingProfile) {
      return;
    }

    final formState = _profileFormKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSavingProfile = true;
    });

    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final telefono = _telefonoController.text.trim();

    final success = await authProvider.updateProfile(
      nombre: nombre,
      email: email,
      telefono: telefono.isEmpty ? null : telefono,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingProfile = false;
      if (success) {
        _hasPendingProfileChanges = false;
      }
    });

    if (success) {
      _syncProfileControllers(authProvider.usuario);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _maybeSyncProfileControllers(authProvider.usuario);
        });

        return ColoredBox(
          color: MedRushTheme.backgroundSecondary,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              isDesktop ? 24 : 104, // Extra space for bottom nav in mobile
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Layout de una columna (tanto desktop como móvil)
                _buildCollapsibleProfileCard(authProvider),
                const SizedBox(height: 24),
                const GoogleApiMetricsWidget(),
                const SizedBox(height: 24),
                const LimpiezaPedidosWidget(),
                const SizedBox(height: 24),
                _buildLogoutCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleProfileCard(AuthProvider authProvider) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header clickeable
          InkWell(
            onTap: () {
              setState(() {
                _isProfileExpanded = !_isProfileExpanded;
              });
            },
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MedRushTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      color: MedRushTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).adminProfile,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyLarge,
                        fontWeight: MedRushTheme.fontWeightSemiBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isProfileExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: MedRushTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Contenido desplegable
          if (_isProfileExpanded) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildProfileContent(authProvider),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileContent(AuthProvider authProvider) {
    final usuario = authProvider.usuario;

    if (usuario == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).couldNotLoadUserInfo,
          style: const TextStyle(
            color: MedRushTheme.textSecondary,
          ),
        ),
      );
    }

    return Form(
      key: _profileFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableField(
            label: AppLocalizations.of(context).name,
            controller: _nombreController,
            placeholder: AppLocalizations.of(context).name,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context).enterValidName;
              }
              if (value.trim().length < 3) {
                return AppLocalizations.of(context).nameMinLength3;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            label: AppLocalizations.of(context).email,
            controller: _emailController,
            placeholder: AppLocalizations.of(context).emailHint,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final l10n = AppLocalizations.of(context);
              if (value == null || value.trim().isEmpty) {
                return l10n.enterEmailAddress;
              }
              final emailError = Validators.email(value);
              if (emailError != null) {
                return emailError;
              }
              if (!Validators.isValidEmailStrict(value.trim())) {
                return l10n.invalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildEditableField(
            label: AppLocalizations.of(context).phone,
            controller: _telefonoController,
            placeholder: AppLocalizations.of(context).phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(Validators.getPhoneInputPattern()),
            ],
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return null; // Campo opcional
              }
              if (trimmed.length < 6) {
                return AppLocalizations.of(context).enterValidPhone;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordChangeForm(authProvider),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasPendingProfileChanges && !_isSavingProfile
                  ? () => _handleProfileSubmit(authProvider)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedRushTheme.textPrimary,
                foregroundColor: MedRushTheme.textInverse,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusSm),
                ),
                elevation: 0,
              ),
              child: _isSavingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MedRushTheme.textInverse,
                        ),
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context).updateProfileButton,
                      style: const TextStyle(
                        fontWeight: MedRushTheme.fontWeightSemiBold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChangeForm(AuthProvider authProvider) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isPasswordExpanded = !_isPasswordExpanded;
              });
            },
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MedRushTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      color: MedRushTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).changePassword,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyLarge,
                        fontWeight: MedRushTheme.fontWeightSemiBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isPasswordExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: MedRushTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isPasswordExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _passwordFormKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordField(
                      label: AppLocalizations.of(context).currentPassword,
                      controller: _currentPasswordController,
                      hintText: AppLocalizations.of(context).enterCurrentPassword,
                      validator: (value) {
                        final l10n = AppLocalizations.of(context);
                        if (value == null || value.isEmpty) {
                          return l10n.enterCurrentPassword;
                        }
                        if (value.length < 8) {
                          return l10n.passwordMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      label: AppLocalizations.of(context).newPassword,
                      controller: _newPasswordController,
                      hintText: AppLocalizations.of(context).enterNewPassword,
                      validator: (value) {
                        final l10n = AppLocalizations.of(context);
                        if (value == null || value.isEmpty) {
                          return l10n.enterNewPassword;
                        }
                        if (value.length < 12) {
                          return l10n.newPasswordMin12;
                        }
                        if (!Validators.isComplexPassword(value)) {
                          return l10n.passwordMustIncludeComplexity;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      label: AppLocalizations.of(context).confirmNewPassword,
                      controller: _confirmPasswordController,
                      hintText: AppLocalizations.of(context).repeatNewPassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        final l10n = AppLocalizations.of(context);
                        if (value == null || value.isEmpty) {
                          return l10n.confirmPasswordRequired;
                        }
                        if (value != _newPasswordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _hasPendingPasswordChanges && !_isSavingPassword
                                ? () => _handlePasswordSubmit(authProvider)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedRushTheme.primaryGreen,
                          foregroundColor: MedRushTheme.textInverse,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MedRushTheme.borderRadiusSm,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: _isSavingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    MedRushTheme.textInverse,
                                  ),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context).updatePassword,
                                style: const TextStyle(
                                  fontWeight: MedRushTheme.fontWeightSemiBold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: MedRushTheme.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.primaryBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.error),
            ),
          ),
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            color: MedRushTheme.textPrimary,
          ),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: textInputAction,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: MedRushTheme.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.primaryBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              borderSide: const BorderSide(color: MedRushTheme.error),
            ),
          ),
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            color: MedRushTheme.textPrimary,
          ),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    // Solo mostrar en móviles
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (!isMobile) {
          return const SizedBox.shrink(); // No mostrar en desktop
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MedRushTheme.surface,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
            boxShadow: const [
              BoxShadow(
                color: MedRushTheme.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MedRushTheme.error.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: const Icon(
                      LucideIcons.logOut,
                      color: MedRushTheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).session,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyLarge,
                      fontWeight: MedRushTheme.fontWeightSemiBold,
                      color: MedRushTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.logOut,
                      color: MedRushTheme.textInverse, size: 16),
                  label: Text(AppLocalizations.of(context).logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedRushTheme.error,
                    foregroundColor: MedRushTheme.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _mostrarDialogoLogout(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.logOut, color: MedRushTheme.error),
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
              await _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.error,
              foregroundColor: MedRushTheme.textInverse,
            ),
            child: Text(AppLocalizations.of(context).logout),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Navegar ANTES del logout para evitar que el contexto se desmonte
      Navigator.pushReplacementNamed(context, '/login');

      // Ejecutar logout después de la navegación
      await authProvider.logout();
    } catch (e) {
      // En caso de error, navegar de todas formas
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

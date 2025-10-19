import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/repositories/apk.repository.dart';
import 'package:medrush/routes/routes.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/validators.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Estado de conexión al servidor
  bool _isCheckingConnection = false;
  bool _isServerConnected = false;
  String? _connectionError;

  // Repositorio para manejo de APK
  final _apkRepository = ApkRepository();

  @override
  void initState() {
    super.initState();
    // Verificar conexión al servidor al inicializar
    _checkServerConnection();

    // Mostrar mensaje si se redirigió por token expirado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.state == AuthState.unauthenticated &&
          authProvider.error == null) {
        // Mostrar mensaje informativo sobre sesión expirada
        NotificationService.showWarning(
          'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
          context: context,
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Verifica la conexión al servidor backend
  Future<void> _checkServerConnection() async {
    if (mounted) {
      setState(() {
        _isCheckingConnection = true;
        _connectionError = null;
      });
    }

    try {
      final isConnected = await BaseApi.testConnection();

      if (mounted) {
        setState(() {
          _isServerConnected = isConnected;
          _isCheckingConnection = false;
          _connectionError =
              isConnected ? null : 'No se pudo conectar al servidor';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isServerConnected = false;
          _isCheckingConnection = false;
          _connectionError = 'Error de conexión: $e';
        });
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Navegar según el rol del usuario
      final userRole = authProvider.userRole;
      AppRoutes.navigateByRole(context, userRole);
    }
  }

  Future<void> _downloadApk() async {
    try {
      // Mostrar indicador de carga
      if (mounted) {
        NotificationService.showInfo(
          'Obteniendo enlace de descarga...',
          context: context,
        );
      }

      // Obtener URL de descarga usando el repositorio
      final result = await _apkRepository.getDownloadUrl();

      if (!result.success) {
        if (mounted) {
          NotificationService.showError(
            result.error ?? 'No se pudo obtener el enlace de descarga',
            context: context,
          );
        }
        return;
      }

      final url = Uri.parse(result.data!);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (mounted) {
          NotificationService.showSuccess(
            'Descarga iniciada correctamente',
            context: context,
          );
        }
      } else {
        if (mounted) {
          NotificationService.showError(
            'No se pudo abrir el enlace de descarga',
            context: context,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          'Error al descargar APK: $e',
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón de descarga APK solo visible en web
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(right: MedRushTheme.spacingMd),
              child: IconButton(
                onPressed: _downloadApk,
                icon: const Icon(
                  LucideIcons.download,
                  color: MedRushTheme.primaryGreen,
                  size: 24,
                ),
                tooltip: 'Descargar APK para Android',
                style: IconButton.styleFrom(
                  backgroundColor:
                      MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MedRushTheme.backgroundPrimary,
              MedRushTheme.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 1200 ? 500 : 400,
                minWidth: 320,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingLg,
                  vertical: MedRushTheme.spacingLg,
                ),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      children: [
                        const SizedBox(height: MedRushTheme.spacingXl),

                        // Logo simplificado
                        _buildHeader(),

                        const SizedBox(height: MedRushTheme.spacingXl),

                        // Indicador de conexión al servidor (solo si hay problemas)
                        if (!_isServerConnected && !_isCheckingConnection) ...[
                          _buildServerConnectionStatus(),
                          const SizedBox(height: MedRushTheme.spacingMd),
                        ],

                        // Formulario de login
                        _buildLoginForm(authProvider),

                        if (authProvider.error != null) ...[
                          const SizedBox(height: MedRushTheme.spacingMd),
                          _buildErrorMessage(authProvider),
                        ],

                        const SizedBox(height: MedRushTheme.spacingXl),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Image.asset(
      'assets/images/logo.png',
      width: 160,
      height: 160,
      fit: BoxFit.contain,
    );
  }

  Widget _buildLoginForm(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MedRushTheme.spacingXl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: MedRushTheme.spacingXl),

              // Título del formulario
              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: MedRushTheme.fontSizeHeadlineSmall,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: MedRushTheme.spacingMd),

              const Text(
                'Ingresa tus credenciales para continuar',
                style: TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  color: MedRushTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: MedRushTheme.spacingXl),

              // Campo Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  // Enfocar el campo de contraseña al presionar Enter
                  FocusScope.of(context).nextFocus();
                },
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'ejemplo@medrush.pe',
                  prefixIcon: const Icon(LucideIcons.mail,
                      color: MedRushTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    borderSide:
                        const BorderSide(color: MedRushTheme.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    borderSide:
                        const BorderSide(color: MedRushTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    borderSide: const BorderSide(
                        color: MedRushTheme.primaryGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: MedRushTheme.backgroundSecondary,
                ),
                validator: Validators.email,
              ),

              const SizedBox(height: MedRushTheme.spacingMd),

              // Campo Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Ingresa tu contraseña',
                  prefixIcon: const Icon(LucideIcons.lock,
                      color: MedRushTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      color: MedRushTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    borderSide:
                        const BorderSide(color: MedRushTheme.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    borderSide:
                        const BorderSide(color: MedRushTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    borderSide: const BorderSide(
                        color: MedRushTheme.primaryGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: MedRushTheme.backgroundSecondary,
                ),
                validator: Validators.password,
              ),

              const SizedBox(height: MedRushTheme.spacingXl),

              // Botón de login mejorado
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      authProvider.state == AuthState.loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedRushTheme.primaryGreen,
                    foregroundColor: MedRushTheme.textInverse,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    ),
                    elevation: MedRushTheme.elevationSm,
                  ),
                  child: authProvider.state == AuthState.loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: MedRushTheme.textInverse,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: MedRushTheme.spacingSm),
                            Text(
                              'Iniciando sesión...',
                              style: TextStyle(
                                color: MedRushTheme.textInverse,
                                fontSize: MedRushTheme.fontSizeLabelLarge,
                                fontWeight: MedRushTheme.fontWeightMedium,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logIn,
                                color: MedRushTheme.textInverse),
                            SizedBox(width: MedRushTheme.spacingSm),
                            Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: MedRushTheme.fontSizeLabelLarge,
                                fontWeight: MedRushTheme.fontWeightMedium,
                                color: MedRushTheme.textInverse,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerConnectionStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingMd,
        vertical: MedRushTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: _isCheckingConnection
            ? Colors.blue.shade50
            : _isServerConnected
                ? Colors.green.shade50
                : Colors.red.shade50,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(
          color: _isCheckingConnection
              ? Colors.blue.shade200
              : _isServerConnected
                  ? Colors.green.shade200
                  : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          if (_isCheckingConnection) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verificando conexión al servidor...',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightMedium,
                ),
              ),
            ),
          ] else if (_isServerConnected) ...[
            Icon(
              LucideIcons.check,
              color: Colors.green.shade600,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conectado al servidor: ${EndpointManager.currentBaseUrl}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightMedium,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.refreshCw,
                color: Colors.green.shade600,
                size: 16,
              ),
              onPressed: _checkServerConnection,
              visualDensity: VisualDensity.compact,
              tooltip: 'Verificar conexión nuevamente',
            ),
          ] else ...[
            Icon(
              LucideIcons.x,
              color: Colors.red.shade600,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin conexión al servidor',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      fontWeight: MedRushTheme.fontWeightMedium,
                    ),
                  ),
                  if (_connectionError != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _connectionError!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: MedRushTheme.fontSizeBodySmall - 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.refreshCw,
                color: Colors.red.shade600,
                size: 16,
              ),
              onPressed: _checkServerConnection,
              visualDensity: VisualDensity.compact,
              tooltip: 'Reintentar conexión',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(AuthProvider authProvider) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.triangleAlert, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: MedRushTheme.fontWeightMedium,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: Colors.red.shade600),
                  onPressed: () => authProvider.clearError(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

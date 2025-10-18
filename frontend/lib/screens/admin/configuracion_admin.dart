import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/widgets/google_api_metrics_widget.dart';
import 'package:provider/provider.dart';

class ConfiguracionAdminScreen extends StatelessWidget {
  const ConfiguracionAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
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
class ConfiguracionAdminContent extends StatelessWidget {
  const ConfiguracionAdminContent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MedRushTheme.spacingLg,
            MedRushTheme.spacingLg,
            MedRushTheme.spacingLg,
            isDesktop
                ? MedRushTheme.spacingLg
                : MedRushTheme.spacingXl +
                    80, // Extra space for bottom nav in mobile
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(MedRushTheme.spacingLg),
                decoration: BoxDecoration(
                  color: MedRushTheme.surface,
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusLg),
                  border: Border.all(color: MedRushTheme.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.settings,
                      color: MedRushTheme.primaryGreen,
                      size: 32,
                    ),
                    SizedBox(width: MedRushTheme.spacingMd),
                    Text(
                      'Configuración',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeTitleLarge,
                        fontWeight: MedRushTheme.fontWeightBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingXl),

              // Sección de perfil del administrador
              Container(
                padding: const EdgeInsets.all(MedRushTheme.spacingLg),
                decoration: BoxDecoration(
                  color: MedRushTheme.surface,
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusLg),
                  border: Border.all(color: MedRushTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          color: MedRushTheme.primaryGreen,
                          size: 24,
                        ),
                        SizedBox(width: MedRushTheme.spacingSm),
                        Text(
                          'Perfil del Administrador',
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyLarge,
                            fontWeight: MedRushTheme.fontWeightMedium,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MedRushTheme.spacingLg),

                    // Información del administrador
                    if (authProvider.usuario != null) ...[
                      Row(
                        children: [
                          // Avatar del administrador
                          _buildAdminAvatar(authProvider),
                          const SizedBox(width: MedRushTheme.spacingLg),
                          // Información del usuario
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.usuario!.nombre,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodyLarge,
                                    fontWeight: MedRushTheme.fontWeightSemiBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: MedRushTheme.spacingXs),
                                Text(
                                  authProvider.usuario!.email,
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodyMedium,
                                    color: MedRushTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: MedRushTheme.spacingXs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: MedRushTheme.spacingSm,
                                    vertical: MedRushTheme.spacingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MedRushTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        MedRushTheme.borderRadiusSm),
                                    border: Border.all(
                                      color: MedRushTheme.primaryGreen
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.shield,
                                        size: 14,
                                        color: MedRushTheme.primaryGreen,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Administrador',
                                        style: TextStyle(
                                          fontSize:
                                              MedRushTheme.fontSizeBodySmall,
                                          fontWeight:
                                              MedRushTheme.fontWeightMedium,
                                          color: MedRushTheme.primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Center(
                        child: Text(
                          'No se pudo cargar la información del usuario',
                          style: TextStyle(
                            color: MedRushTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingXl),

              // Sección de métricas de Google API
              const GoogleApiMetricsWidget(),
              const SizedBox(height: MedRushTheme.spacingXl),

              // Sección de cuenta (solo en móvil)
              if (!isDesktop) ...[
                Container(
                  padding: const EdgeInsets.all(MedRushTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: MedRushTheme.surface,
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusLg),
                    border: Border.all(color: MedRushTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            LucideIcons.logOut,
                            color: MedRushTheme.error,
                            size: 24,
                          ),
                          SizedBox(width: MedRushTheme.spacingSm),
                          Text(
                            'Sesión',
                            style: TextStyle(
                              fontSize: MedRushTheme.fontSizeBodyLarge,
                              fontWeight: MedRushTheme.fontWeightMedium,
                              color: MedRushTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MedRushTheme.spacingLg),
                      ElevatedButton.icon(
                        icon:
                            const Icon(LucideIcons.logOut, color: Colors.white),
                        label: const Text('Cerrar sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedRushTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                        onPressed: () => _mostrarDialogoLogout(context),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminAvatar(AuthProvider authProvider) {
    final foto = authProvider.usuario?.foto;
    final imageUrl = BaseApi.getImageUrl(foto);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: MedRushTheme.primaryGreen,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: MedRushTheme.borderLight, width: 3),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(37),
              child: Image.network(
                imageUrl,
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    LucideIcons.user,
                    color: Colors.white,
                    size: 32,
                  );
                },
              ),
            )
          : const Icon(
              LucideIcons.user,
              color: Colors.white,
              size: 32,
            ),
    );
  }

  void _mostrarDialogoLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cerrar el diálogo de confirmación
              Navigator.of(context).pop();

              // Ejecutar logout directamente sin loading adicional
              await _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
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

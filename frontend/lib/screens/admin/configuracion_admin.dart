import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/screens/admin/modules/configuracion/google_api_metrics_widget.dart';
import 'package:medrush/screens/admin/modules/configuracion/limpieza_pedidos_widget.dart';
import 'package:medrush/theme/theme.dart';
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
class ConfiguracionAdminContent extends StatefulWidget {
  const ConfiguracionAdminContent({super.key});

  @override
  State<ConfiguracionAdminContent> createState() =>
      _ConfiguracionAdminContentState();
}

class _ConfiguracionAdminContentState extends State<ConfiguracionAdminContent> {
  bool _isProfileExpanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
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
                  const Expanded(
                    child: Text(
                      'Perfil del Administrador',
                      style: TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campos del formulario
        if (authProvider.usuario != null) ...[
          _buildFormField(
              'Nombre', authProvider.usuario!.nombre, 'Nombre del Admin'),
          const SizedBox(height: 16),
          _buildFormField('Dirección de Email', authProvider.usuario!.email,
              'admin@healthcare.com'),
          const SizedBox(height: 16),
          _buildPasswordChangeForm(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
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
              child: const Text(
                'Actualizar Perfil',
                style: TextStyle(
                  fontWeight: MedRushTheme.fontWeightSemiBold,
                ),
              ),
            ),
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
    );
  }

  Widget _buildPasswordChangeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cambiar Contraseña',
          style: TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Contraseña actual',
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textTertiary,
                  ),
                ),
              ),
              Icon(
                LucideIcons.lock,
                size: 16,
                color: MedRushTheme.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Nueva contraseña',
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textTertiary,
                  ),
                ),
              ),
              Icon(
                LucideIcons.key,
                size: 16,
                color: MedRushTheme.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Confirmar nueva contraseña',
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textTertiary,
                  ),
                ),
              ),
              Icon(
                LucideIcons.check,
                size: 16,
                color: MedRushTheme.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(String label, String value, String placeholder) {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: Text(
            value.isNotEmpty ? value : placeholder,
            style: TextStyle(
              fontSize: 14,
              color: value.isNotEmpty
                  ? const Color(0xFF1F2937)
                  : const Color(0xFF9CA3AF),
            ),
          ),
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
                  const Text(
                    'Sesión',
                    style: TextStyle(
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
                  label: const Text('Cerrar sesión'),
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
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: MedRushTheme.error),
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
              backgroundColor: MedRushTheme.error,
              foregroundColor: MedRushTheme.textInverse,
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

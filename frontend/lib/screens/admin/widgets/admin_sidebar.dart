import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/routes/routes.dart';
import 'package:medrush/theme/theme.dart';
import 'package:provider/provider.dart';

class AdminSidebarNavigation extends StatefulWidget {
  const AdminSidebarNavigation({super.key});

  @override
  State<AdminSidebarNavigation> createState() => _AdminSidebarNavigationState();
}

class _AdminSidebarNavigationState extends State<AdminSidebarNavigation> {
  late AdminNavigationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminNavigationController.instance;
    // Inicializar con la ruta actual
    _controller.ensureInitialized(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              children: [
                const SizedBox(height: MedRushTheme.spacingMd),

                // Logo compacto + texto
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    MedRushTheme.spacingLg,
                    MedRushTheme.spacingSm,
                    MedRushTheme.spacingLg,
                    MedRushTheme.spacingMd,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logonoletter.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: MedRushTheme.spacingMd),
                      Text(
                        AppLocalizations.of(context).adminPanel,
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeTitleMedium,
                          fontWeight: MedRushTheme.fontWeightBold,
                          color: MedRushTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Información del administrador
                if (authProvider.usuario != null)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: MedRushTheme.spacingMd,
                      vertical: MedRushTheme.spacingSm,
                    ),
                    padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusMd),
                      border: Border.all(
                        color: MedRushTheme.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: _buildAdminAvatar(authProvider),
                        ),
                        const SizedBox(width: MedRushTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.usuario!.nombre,
                                style: const TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodyMedium,
                                  fontWeight: MedRushTheme.fontWeightSemiBold,
                                  color: MedRushTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                authProvider.usuario!.nombre,
                                style: const TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodySmall,
                                  color: MedRushTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Menú de navegación
                _buildSidebarMenuItem(
                  context: context,
                  icon: LucideIcons.truck,
                  label: AppLocalizations.of(context).deliveriesTab,
                  index: AdminNavigationController.entregasIndex,
                  isSelected: _controller
                      .isCurrentIndex(AdminNavigationController.entregasIndex),
                ),
                _buildSidebarMenuItem(
                  context: context,
                  icon: LucideIcons.building2,
                  label: AppLocalizations.of(context).pharmaciesTab,
                  index: AdminNavigationController.farmaciasIndex,
                  isSelected: _controller
                      .isCurrentIndex(AdminNavigationController.farmaciasIndex),
                ),
                _buildSidebarMenuItem(
                  context: context,
                  icon: LucideIcons.users,
                  label: AppLocalizations.of(context).driversTab,
                  index: AdminNavigationController.personalIndex,
                  isSelected: _controller
                      .isCurrentIndex(AdminNavigationController.personalIndex),
                ),
                _buildSidebarMenuItem(
                  context: context,
                  icon: LucideIcons.map,
                  label: AppLocalizations.of(context).routesTab,
                  index: AdminNavigationController.rutasIndex,
                  isSelected: _controller
                      .isCurrentIndex(AdminNavigationController.rutasIndex),
                ),
                _buildSidebarMenuItem(
                  context: context,
                  icon: LucideIcons.settings,
                  label: AppLocalizations.of(context).configuration,
                  index: AdminNavigationController.configuracionIndex,
                  isSelected: _controller.isCurrentIndex(
                      AdminNavigationController.configuracionIndex),
                ),

                const Spacer(),
                _buildLogoutItem(context),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAdminAvatar(AuthProvider authProvider) {
    final foto = authProvider.usuario?.foto;
    final imageUrl = BaseApi.getImageUrl(foto);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: MedRushTheme.primaryGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    LucideIcons.user,
                    color: Colors.white,
                    size: 20,
                  );
                },
              ),
            )
          : const Icon(
              LucideIcons.user,
              color: Colors.white,
              size: 20,
            ),
    );
  }

  Widget _buildSidebarMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingMd,
        vertical: MedRushTheme.spacingXs,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? MedRushTheme.primaryGreen
              : MedRushTheme.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? MedRushTheme.primaryGreen
                : MedRushTheme.textPrimary,
            fontWeight: isSelected
                ? MedRushTheme.fontWeightMedium
                : MedRushTheme.fontWeightRegular,
          ),
        ),
        selected: isSelected,
        selectedTileColor: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        ),
        onTap: () {
          _controller.navigateTo(context, index);
        },
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingMd,
        vertical: MedRushTheme.spacingXs,
      ),
      child: ListTile(
        leading: const Icon(
          LucideIcons.logOut,
          color: MedRushTheme.error,
        ),
        title: Text(
          AppLocalizations.of(context).logout,
          style: const TextStyle(
            color: MedRushTheme.error,
            fontWeight: MedRushTheme.fontWeightMedium,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        ),
        onTap: () async {
          try {
            await context.read<AuthProvider>().logout();
          } catch (_) {}
          if (!mounted || !context.mounted) {
            return;
          }
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        },
      ),
    );
  }
}

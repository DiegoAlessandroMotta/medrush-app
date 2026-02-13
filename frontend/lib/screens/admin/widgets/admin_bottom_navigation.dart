import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/routes/routes.dart';
import 'package:medrush/theme/theme.dart';

class AdminBottomNavigation extends StatefulWidget {
  const AdminBottomNavigation({super.key});

  @override
  State<AdminBottomNavigation> createState() => _AdminBottomNavigationState();
}

class _AdminBottomNavigationState extends State<AdminBottomNavigation> {
  final iconList = <IconData>[
    LucideIcons.truck,
    LucideIcons.building2,
    LucideIcons.users,
    LucideIcons.map,
    LucideIcons.settings,
  ];

  List<String> _labelList(BuildContext context) => <String>[
        AppLocalizations.of(context).deliveriesTab,
        AppLocalizations.of(context).pharmaciesTab,
        AppLocalizations.of(context).driversTab,
        AppLocalizations.of(context).routesTab,
        AppLocalizations.of(context).settingsTab,
      ];

  late AdminNavigationController _controller;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('navigation', 'AdminBottomNavigation'))
      ..add(IntProperty('currentIndex', _controller.currentIndex))
      ..add(IterableProperty<IconData>('iconList', iconList));
  }

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
        // Validar que tenemos al menos 2 elementos para evitar el error
        final itemCount = iconList.length.clamp(2, 5);

        return AnimatedBottomNavigationBar.builder(
          itemCount: itemCount,
          tabBuilder: (int index, bool isActive) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconList[index],
                  size: 22,
                  color: isActive
                      ? MedRushTheme.primaryGreen
                      : MedRushTheme.textTertiary,
                ),
                const SizedBox(height: 4),
                Text(
                  _labelList(context)[index],
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeLabelSmall,
                    fontWeight: isActive
                        ? MedRushTheme.fontWeightMedium
                        : MedRushTheme.fontWeightRegular,
                    color: isActive
                        ? MedRushTheme.primaryGreen
                        : MedRushTheme.textTertiary,
                  ),
                ),
              ],
            );
          },
          backgroundColor: MedRushTheme.surface,
          activeIndex: _controller.currentIndex.clamp(0, itemCount - 1),
          splashColor: MedRushTheme.primaryGreen,
          splashSpeedInMilliseconds: 300,
          notchSmoothness: NotchSmoothness.softEdge,
          gapLocation: GapLocation.none, // Sin notch para admin
          leftCornerRadius: 20,
          rightCornerRadius: 20,
          onTap: (index) {
            if (index >= 0 && index < itemCount) {
              _controller.navigateTo(context, index);
            }
          },
          shadow: const BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 10,
            spreadRadius: 0.5,
            color: MedRushTheme.shadowMedium,
          ),
        );
      },
    );
  }
}

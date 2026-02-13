import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/routes/routes.dart';
import 'package:medrush/theme/theme.dart';

class RepartidorBottomNavigation extends StatefulWidget {
  const RepartidorBottomNavigation({super.key});

  @override
  State<RepartidorBottomNavigation> createState() =>
      _RepartidorBottomNavigationState();
}

class _RepartidorBottomNavigationState
    extends State<RepartidorBottomNavigation> {
  late RepartidorNavigationController _controller;

  final iconList = <IconData>[
    LucideIcons.truck,
    LucideIcons.history,
    LucideIcons.mapPin,
    LucideIcons.user,
  ];

  List<String> _labelList(BuildContext context) => <String>[
        AppLocalizations.of(context).deliveriesTab,
        AppLocalizations.of(context).historyTab,
        AppLocalizations.of(context).routeTab,
        AppLocalizations.of(context).profileTab,
      ];

  @override
  void initState() {
    super.initState();
    _controller = RepartidorNavigationController.instance;
    // Inicializar con la ruta actual
    _controller.ensureInitialized(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return AnimatedBottomNavigationBar.builder(
          itemCount: iconList.length,
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
          activeIndex: _controller.currentIndex,
          splashColor: MedRushTheme.primaryGreen,
          splashSpeedInMilliseconds: 300,
          notchSmoothness: NotchSmoothness.softEdge,
          gapLocation: GapLocation.center,
          leftCornerRadius: 20,
          rightCornerRadius: 20,
          onTap: (index) => _controller.navigateTo(context, index),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('navigation', 'RepartidorBottomNavigation'))
      ..add(IntProperty('currentIndex', _controller.currentIndex))
      ..add(IterableProperty<IconData>('iconList', iconList));
  }
}

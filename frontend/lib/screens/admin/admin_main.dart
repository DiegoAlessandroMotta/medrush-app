import 'package:flutter/material.dart';
import 'package:medrush/routes/routes.dart';
import 'package:medrush/screens/admin/configuracion_admin.dart';
import 'package:medrush/screens/admin/farmacias_admin.dart';
import 'package:medrush/screens/admin/pedidos_admin.dart';
import 'package:medrush/screens/admin/repartidor_admin.dart';
import 'package:medrush/screens/admin/rutas_admin.dart';
import 'package:medrush/screens/admin/widgets/admin_bottom_navigation.dart';
import 'package:medrush/screens/admin/widgets/admin_sidebar.dart';
import 'package:medrush/theme/theme.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late AdminNavigationController _controller;
  int _currentIndex = AdminNavigationController.entregasIndex;
  late final PageController _pageController;

  // Lista de pantallas para mantener el estado
  late final List<Widget> _screens = [
    const EntregasScreen(key: ValueKey(0)),
    const FarmaciasListScreen(key: ValueKey(1)),
    const PersonalScreen(key: ValueKey(2)),
    const RutasAdminScreen(key: ValueKey(3)),
    const ConfiguracionAdminContent(key: ValueKey(4)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AdminNavigationController.instance;

    // Inicializar con la ruta actual del controlador
    _currentIndex = _controller.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _controller
      ..addListener(_onControllerChanged)

      // Inicializar el controlador con la ruta actual
      ..ensureInitialized(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        _currentIndex = _controller.currentIndex;
      });
      // Cambio directo sin animación para mejor rendimiento
      if (_pageController.hasClients &&
          _currentIndex != _pageController.page?.round()) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          decoration: const BoxDecoration(
            color: MedRushTheme.surface,
            border: Border(
              right: BorderSide(
                color: MedRushTheme.borderLight,
              ),
            ),
          ),
          child: const AdminSidebarNavigation(),
        ),
        Expanded(
          child: _screens[_currentIndex],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      // Permitir que el contenido se extienda detrás del bottom navigation
      extendBody: true,
      body: SafeArea(
        bottom: false, // No agregar padding inferior automático
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(),
    );
  }
}

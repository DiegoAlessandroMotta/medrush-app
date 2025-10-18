import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/routes/routes.dart';
import 'package:medrush/screens/repartidor/historial_repartidor.dart';
import 'package:medrush/screens/repartidor/pedidos_repartidor.dart';
import 'package:medrush/screens/repartidor/perfil_repartidor.dart';
import 'package:medrush/screens/repartidor/ruta_map_repartidor.dart';
import 'package:medrush/screens/repartidor/widgets/repartidor_bottom_navigation.dart';
import 'package:medrush/theme/theme.dart';

class RepartidorMainScreen extends StatefulWidget {
  const RepartidorMainScreen({super.key});

  @override
  State<RepartidorMainScreen> createState() => _RepartidorMainScreenState();
}

class _RepartidorMainScreenState extends State<RepartidorMainScreen> {
  late RepartidorNavigationController _controller;

  // Lazy loading: solo cargar pantallas cuando sean necesarias
  final Map<int, Widget> _screenCache = {};

  @override
  void initState() {
    super.initState();
    _controller = RepartidorNavigationController.instance;

    // Escuchar cambios en el controlador
    _controller
      ..addListener(_onControllerChanged)
      // Inicializar con la ruta actual
      ..ensureInitialized(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      debugPrint(
          '🎯 [NAVIGATION] Controlador cambiado - Índice actual: ${_controller.currentIndex}');
      debugPrint(
          '🔄 [ANIMATION] Previous: ${_controller.previousIndex} → Current: ${_controller.currentIndex}');
      setState(() {
        // Forzar rebuild para mostrar la pantalla correcta
      });
    }
  }

  // Lazy loading: crear pantalla solo cuando se necesite
  Widget _getScreen(int index) {
    if (!_screenCache.containsKey(index)) {
      debugPrint('🔄 [LAZY LOADING] Cargando pantalla índice: $index');
      Widget screen;
      switch (index) {
        case RepartidorNavigationController.entregasIndex:
          debugPrint('📦 [LAZY LOADING] Creando Pantalla Entregas');
          screen = const PedidosListScreen(key: ValueKey(0));
        case RepartidorNavigationController.historialIndex:
          debugPrint('📋 [LAZY LOADING] Creando Pantalla Historial');
          screen = const HistorialScreen(key: ValueKey(1));
        case RepartidorNavigationController.rutaIndex:
          debugPrint('🗺️ [LAZY LOADING] Creando Pantalla Ruta');
          screen = const RutaMapScreen(key: ValueKey(2));
        case RepartidorNavigationController.perfilIndex:
          debugPrint('👤 [LAZY LOADING] Creando Pantalla Perfil');
          screen = const PerfilRepartidorScreen(key: ValueKey(3));
        default:
          debugPrint(
              '❓ [LAZY LOADING] Índice desconocido: $index, usando Entregas');
          screen = const PedidosListScreen(key: ValueKey(0));
      }
      _screenCache[index] = screen;
      debugPrint('✅ [LAZY LOADING] Pantalla índice $index cargada y cacheada');
    } else {
      debugPrint(
          '⚡ [LAZY LOADING] Usando pantalla cacheada para índice: $index');
    }
    return _screenCache[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      // Permitir que el contenido se extienda detrás del bottom navigation
      extendBody: true,
      body: SafeArea(
        bottom: false, // No agregar padding inferior automático
        child: Padding(
          // Agregar padding inferior para evitar que el contenido cubra el botón central
          padding: EdgeInsets.zero, // Prueba: sin padding inferior
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Determinar dirección de la animación basada en el índice anterior
              final previousIndex = _controller.previousIndex;
              final currentIndex = _controller.currentIndex;

              debugPrint(
                  '🎬 [ANIMATION] Building transition - Previous: $previousIndex, Current: $currentIndex');

              // Calcular dirección de la transición
              Offset beginOffset;
              if (currentIndex > previousIndex) {
                // Navegando hacia la derecha (adelante)
                beginOffset = const Offset(1.0, 0.0);
                debugPrint('➡️ [ANIMATION] Sliding from right to left');
              } else if (currentIndex < previousIndex) {
                // Navegando hacia la izquierda (atrás)
                beginOffset = const Offset(-1.0, 0.0);
                debugPrint('⬅️ [ANIMATION] Sliding from left to right');
              } else {
                // Mismo índice, sin animación
                beginOffset = Offset.zero;
                debugPrint('⏸️ [ANIMATION] No animation - same index');
              }

              return SlideTransition(
                position: Tween<Offset>(
                  begin: beginOffset,
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
            key: ValueKey(
                'screen_${_controller.currentIndex}'), // Key más específica
            child: _getScreen(_controller.currentIndex),
          ),
        ),
      ),
      floatingActionButton:
          (_controller.currentIndex == RepartidorNavigationController.rutaIndex)
              ? null // Ocultar FAB (QR) en la pantalla de Ruta (mapa)
              : FloatingActionButton(
                  heroTag: 'fab_qr_repartidor_main',
                  onPressed: () {
                    Navigator.pushNamed(context, '/repartidor/barcode-scan');
                  },
                  backgroundColor: MedRushTheme.textInverse,
                  elevation: 16,
                  child: const Icon(
                    LucideIcons.barcode,
                    color: MedRushTheme.primaryGreen,
                    size: 26,
                  ),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const RepartidorBottomNavigation(),
    );
  }
}

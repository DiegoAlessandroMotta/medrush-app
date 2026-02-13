import 'package:flutter/material.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/screens/admin/admin_main.dart';
import 'package:medrush/screens/admin/configuracion_admin.dart';
import 'package:medrush/screens/admin/modules/farmacias/farmacia_detalle.dart';
import 'package:medrush/screens/admin/modules/farmacias/farmacia_form.dart';
import 'package:medrush/screens/login_screen.dart';
import 'package:medrush/screens/register_screen.dart';
import 'package:medrush/screens/repartidor/barcode_repartidor.dart';
import 'package:medrush/screens/repartidor/firma_screen.dart';
import 'package:medrush/screens/repartidor/historial_repartidor.dart';
import 'package:medrush/screens/repartidor/modules/pedidos/pedidos_detalle_repartidor.dart';
import 'package:medrush/screens/repartidor/pedidos_repartidor.dart';
import 'package:medrush/screens/repartidor/perfil_repartidor.dart';
import 'package:medrush/screens/repartidor/repartidor_main.dart';
import 'package:medrush/screens/repartidor/ruta_map_repartidor.dart';
import 'package:medrush/services/notification_service.dart';

class AppRoutes {
  // Rutas principales
  static const String login = '/login';
  static const String register = '/register';

  // Rutas de Administrador
  static const String adminDashboard = '/admin/dashboard';
  static const String adminFarmacias = '/admin/farmacias';
  static const String adminNuevaFarmacia = '/admin/nueva-farmacia';
  static const String adminEditarFarmacia = '/admin/editar-farmacia';
  static const String adminFarmaciaDetalle = '/admin/farmacia-detalle';
  static const String adminEntregas = '/admin/entregas';
  static const String adminPersonal = '/admin/personal';
  static const String adminRutas = '/admin/rutas';
  static const String adminConfiguracion = '/admin/configuracion';

  // Rutas de Repartidor
  static const String repartidorMain = '/repartidor/main';
  static const String repartidorEntregas = '/repartidor/entregas';
  static const String repartidorHistorial = '/repartidor/historial';
  static const String repartidorPerfil = '/repartidor/perfil';
  static const String repartidorRuta = '/repartidor/ruta';
  static const String repartidorBarcodeScan = '/repartidor/barcode-scan';
  static const String repartidorPedidoDetalle = '/repartidor/pedido-detalle';

  // Rutas de utilidad
  static const String firma = '/firma';

  // Mapa de rutas
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Ruta principal de login
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),

      // Rutas de Administrador
      adminDashboard: (context) => const AdminMainScreen(),
      adminFarmacias: (context) => const AdminMainScreen(),
      adminNuevaFarmacia: (context) => FarmaciaForm(
            onSave: (farmacia) {
              NotificationService.showSuccess('Farmacia guardada exitosamente',
                  context: context);
              Navigator.of(context).pop();
            },
          ),
      adminEditarFarmacia: (context) {
        final farmaciaData =
            ModalRoute.of(context)!.settings.arguments as Map<String, String>;

        // Usar factory method para crear Farmacia
        final farmacia = Farmacia.fromMap(farmaciaData);

        return FarmaciaForm(
          onSave: (farmacia) {
            NotificationService.showSuccess('Farmacia actualizada exitosamente',
                context: context);
            Navigator.of(context).pop();
          },
          initialData: farmacia,
        );
      },
      adminFarmaciaDetalle: (context) {
        final farmacia = ModalRoute.of(context)!.settings.arguments as Farmacia;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).pharmacyDetailsTitle),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          body: FarmaciaDetalleBottomSheet(farmacia: farmacia),
        );
      },
      adminEntregas: (context) => const AdminMainScreen(),
      adminPersonal: (context) => const AdminMainScreen(),
      adminRutas: (context) => const AdminMainScreen(),
      adminConfiguracion: (context) => const ConfiguracionAdminScreen(),

      // Rutas de Repartidor
      repartidorMain: (context) => const RepartidorMainScreen(),
      repartidorEntregas: (context) => const PedidosListScreen(),
      repartidorHistorial: (context) => const HistorialScreen(),
      repartidorPerfil: (context) => const PerfilRepartidorScreen(),
      repartidorRuta: (context) => const RutaMapScreen(),
      repartidorBarcodeScan: (context) => const BarcodeRepartidorScreen(),
      repartidorPedidoDetalle: (context) {
        final pedidoId = ModalRoute.of(context)!.settings.arguments as String;
        return PedidoDetalleScreen(pedidoId: pedidoId);
      },

      // Rutas de Firma
      firma: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final pedidoId = args?['pedidoId'] as String? ?? '';
        final esModoEdicion = args?['esModoEdicion'] as bool? ?? false;
        final firmaGuardada = args?['firmaGuardada'] as String?;

        return FirmaScreen(
          pedidoId: pedidoId,
          esModoEdicion: esModoEdicion,
          firmaGuardada: firmaGuardada,
        );
      },
    };
  }

  /// Obtiene la ruta principal según el rol del usuario
  static String getMainRouteByRole(String userRole) {
    return switch (userRole.toLowerCase()) {
      'admin' || 'administrador' => adminDashboard,
      'repartidor' || 'delivery' || 'driver' => repartidorMain,
      _ => login,
    };
  }

  /// Navega según el rol del usuario
  static void navigateByRole(BuildContext context, String userRole) {
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(getMainRouteByRole(userRole));
    }
  }
}

// --- Lógica de navegación admin centralizada ---

class AdminNavigationController extends ChangeNotifier {
  static AdminNavigationController? _instance;

  // Índices de navegación
  static const int entregasIndex = 0;
  static const int farmaciasIndex = 1;
  static const int personalIndex = 2;
  static const int rutasIndex = 3;
  static const int configuracionIndex = 4;

  // Estado actual
  int _currentIndex = entregasIndex;
  String _currentRoute = AppRoutes.adminEntregas;
  int _previousIndex = entregasIndex;
  bool _isInitializing = false;

  // Mapa de rutas a índices
  static const Map<String, int> routeToIndex = {
    AppRoutes.adminDashboard: entregasIndex,
    AppRoutes.adminEntregas: entregasIndex,
    AppRoutes.adminFarmacias: farmaciasIndex,
    AppRoutes.adminPersonal: personalIndex,
    AppRoutes.adminRutas: rutasIndex,
    AppRoutes.adminConfiguracion: configuracionIndex,
  };

  // Mapa de índices a rutas
  static const Map<int, String> indexToRoute = {
    entregasIndex: AppRoutes.adminEntregas,
    farmaciasIndex: AppRoutes.adminFarmacias,
    personalIndex: AppRoutes.adminPersonal,
    rutasIndex: AppRoutes.adminRutas,
    configuracionIndex: AppRoutes.adminConfiguracion,
  };

  // Singleton pattern
  static AdminNavigationController get instance {
    _instance ??= AdminNavigationController._();
    return _instance!;
  }

  AdminNavigationController._() {
    // Asegurar que siempre inicie en Entregas
    _currentIndex = entregasIndex;
    _currentRoute = AppRoutes.adminEntregas;
    _previousIndex = entregasIndex;
  }

  // Getters
  int get currentIndex => _currentIndex;
  String get currentRoute => _currentRoute;
  int get previousIndex => _previousIndex;

  /// Cambiar a un índice específico (sin navegación)
  void navigateTo(BuildContext context, int index) {
    if (_currentIndex == index) {
      return;
    }
    _previousIndex = _currentIndex;
    _currentIndex = index;
    _currentRoute = indexToRoute[index] ?? AppRoutes.adminDashboard;
    notifyListeners();
  }

  // Cambiar a una ruta específica (sin navegación)
  void navigateToRoute(BuildContext context, String route) {
    final index = routeToIndex[route];
    if (index != null) {
      navigateTo(context, index);
    }
  }

  // Inicializar con la ruta actual
  void initializeWithRoute(String route) {
    if (route == AppRoutes.adminDashboard || !routeToIndex.containsKey(route)) {
      _currentRoute = AppRoutes.adminEntregas;
      _currentIndex = entregasIndex;
    } else {
      _currentRoute = route;
      _currentIndex = routeToIndex[route] ?? entregasIndex;
    }
    _previousIndex = _currentIndex;
    _isInitializing = false; // Reset flag después de inicializar
    notifyListeners();
  }

  // Verificar si el controlador está inicializado con una ruta válida
  bool get isInitialized => _currentRoute != AppRoutes.adminDashboard;

  bool isCurrentRoute(String route) => _currentRoute == route;
  bool isCurrentIndex(int index) => _currentIndex == index;

  // Resetear flag de inicialización (útil para navegación programática)
  void resetInitializationFlag() {
    _isInitializing = false;
  }

  void resetToEntregas() {
    _currentIndex = entregasIndex;
    _currentRoute = AppRoutes.adminEntregas;
    _previousIndex = entregasIndex;
    notifyListeners();
  }

  // Método centralizado para inicialización post-frame
  void ensureInitialized(BuildContext context) {
    // Evitar múltiples inicializaciones simultáneas
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final route = ModalRoute.of(context)?.settings.name;
        if (route != null) {
          initializeWithRoute(route);
        }
      }
      _isInitializing = false;
    });
  }
}

// --- Lógica de navegación repartidor centralizada ---

class RepartidorNavigationController extends ChangeNotifier {
  static RepartidorNavigationController? _instance;

  // Índices de navegación
  static const int entregasIndex = 0;
  static const int historialIndex = 1;
  static const int rutaIndex = 2;
  static const int perfilIndex = 3;

  // Estado actual
  int _currentIndex = entregasIndex;
  String _currentRoute = AppRoutes.repartidorEntregas;
  int _previousIndex = entregasIndex;
  bool _isInitializing = false;

  // Mapa de rutas a índices
  static const Map<String, int> routeToIndex = {
    AppRoutes.repartidorMain: entregasIndex,
    AppRoutes.repartidorEntregas: entregasIndex,
    AppRoutes.repartidorHistorial: historialIndex,
    AppRoutes.repartidorRuta: rutaIndex,
    AppRoutes.repartidorPerfil: perfilIndex,
  };

  // Mapa de índices a rutas
  static const Map<int, String> indexToRoute = {
    entregasIndex: AppRoutes.repartidorMain,
    historialIndex: AppRoutes.repartidorHistorial,
    rutaIndex: AppRoutes.repartidorRuta,
    perfilIndex: AppRoutes.repartidorPerfil,
  };

  // Singleton pattern
  static RepartidorNavigationController get instance {
    _instance ??= RepartidorNavigationController._();
    return _instance!;
  }

  RepartidorNavigationController._() {
    // Asegurar que siempre inicie en Entregas
    _currentIndex = entregasIndex;
    _currentRoute = AppRoutes.repartidorMain;
    _previousIndex = entregasIndex;
  }

  // Getters
  int get currentIndex => _currentIndex;
  String get currentRoute => _currentRoute;
  int get previousIndex => _previousIndex;

  /// Cambiar a un índice específico (sin navegación)
  void navigateTo(BuildContext context, int index) {
    if (_currentIndex == index) {
      return;
    }
    _previousIndex = _currentIndex;
    _currentIndex = index;
    _currentRoute = indexToRoute[index] ?? AppRoutes.repartidorMain;
    notifyListeners();
  }

  // Cambiar a una ruta específica (sin navegación)
  void navigateToRoute(BuildContext context, String route) {
    final index = routeToIndex[route];
    if (index != null) {
      navigateTo(context, index);
    }
  }

  // Inicializar con la ruta actual
  void initializeWithRoute(String route) {
    if (route == AppRoutes.repartidorMain || !routeToIndex.containsKey(route)) {
      _currentRoute = AppRoutes.repartidorMain;
      _currentIndex = entregasIndex;
    } else {
      _currentRoute = route;
      _currentIndex = routeToIndex[route] ?? entregasIndex;
    }
    _previousIndex = _currentIndex;
    _isInitializing = false; // Reset flag después de inicializar
    notifyListeners();
  }

  bool isCurrentRoute(String route) => _currentRoute == route;
  bool isCurrentIndex(int index) => _currentIndex == index;

  // Resetear flag de inicialización (útil para navegación programática)
  void resetInitializationFlag() {
    _isInitializing = false;
  }

  void resetToEntregas() {
    _currentIndex = entregasIndex;
    _currentRoute = AppRoutes.repartidorMain;
    _previousIndex = entregasIndex;
    notifyListeners();
  }

  // Método centralizado para inicialización post-frame
  void ensureInitialized(BuildContext context) {
    // Evitar múltiples inicializaciones simultáneas
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final route = ModalRoute.of(context)?.settings.name;
        if (route != null) {
          initializeWithRoute(route);
        }
      }
      _isInitializing = false;
    });
  }
}

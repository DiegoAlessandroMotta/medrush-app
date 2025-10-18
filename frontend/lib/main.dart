import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medrush/firebase_options.dart';
import 'package:medrush/providers/auth.provider.dart';
import 'package:medrush/providers/rutas.provider.dart';
import 'package:medrush/routes/routes.dart';
import 'package:medrush/screens/barcode_scan_admin.dart';
import 'package:medrush/screens/login_screen.dart';
import 'package:medrush/screens/repartidor/firma_screen.dart';
import 'package:medrush/screens/repartidor/modules/pedidos/pedidos_detalle_repartidor.dart';
import 'package:medrush/services/fcm_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación a solo vertical (portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logInfo('Firebase inicializado correctamente');
  } catch (e) {
    logError('Error al inicializar Firebase', e);
    // Continuar sin Firebase si hay error
  }

  try {
    // Configurar manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    logInfo('Firebase Messaging configurado');
  } catch (e) {
    logError('Error al configurar Firebase Messaging', e);
    // Continuar sin Firebase Messaging si hay error
  }

  // FIX: Cache deshabilitado - initCache eliminado
  runApp(const MedRushApp());
}

class MedRushApp extends StatelessWidget {
  const MedRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RutasProvider()),
      ],
      child: MaterialApp(
        title: 'MedRush - Delivery de Medicamentos',
        debugShowCheckedModeBanner: false,
        theme: MedRushTheme.lightTheme,
        // darkTheme eliminado porque no existe tema oscuro
        themeMode: ThemeMode.light, // Fuerza siempre el tema claro
        home: const AuthWrapper(),
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: (settings) {
          // Rutas dinámicas con argumentos
          switch (settings.name) {
            case '/pedido-detalle':
              final pedidoId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => PedidoDetalleScreen(pedidoId: pedidoId),
              );
            case '/barcode-scan':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => BarcodeScanScreen(
                  modo: args['modo'],
                  pedidoId: args['pedidoId']?.toString(),
                ),
              );
            case '/firma':
              final pedidoId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => FirmaScreen(pedidoId: pedidoId),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

/// Widget que maneja la autenticación y redirige automáticamente
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Si el usuario no está autenticado, mostrar login
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }

        // Si está autenticado, navegar según el rol
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final userRole = authProvider.userRole;
          AppRoutes.navigateByRole(context, userRole);
        });

        // Mostrar loading mientras se navega
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

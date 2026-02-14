import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/firebase_options.dart';
import 'package:medrush/l10n/app_localizations.dart';
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

  // Inicializar detección del emulador solo en móvil (Platform no existe en web)
  if (!kIsWeb) {
    await EndpointManager.initializeEmulatorDetection();
  }

  // Inicializar Firebase con mejor manejo de errores
  await _initializeFirebase();

  // Configurar Firebase Messaging
  await _initializeFirebaseMessaging();

  // Ejecutar la aplicación con manejo de errores global
  FlutterError.onError = (details) {
    logError('Error de Flutter', details.exception, details.stack);
  };

  runApp(const MedRushApp());
}

/// Inicializa Firebase con manejo de errores
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logInfo('Firebase inicializado correctamente');
  } catch (e, stackTrace) {
    logError('Error al inicializar Firebase', e, stackTrace);
    // Continuar sin Firebase si hay error
  }
}

/// Inicializa Firebase Messaging con manejo de errores
Future<void> _initializeFirebaseMessaging() async {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    logInfo('Firebase Messaging configurado');
  } catch (e, stackTrace) {
    logError('Error al configurar Firebase Messaging', e, stackTrace);
    // Continuar sin Firebase Messaging si hay error
  }
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
        title: 'MedRush - Delivery',
        debugShowCheckedModeBanner: false,
        theme: MedRushTheme.lightTheme,
        // darkTheme eliminado porque no existe tema oscuro
        themeMode: ThemeMode.light, // Fuerza siempre el tema claro
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English (Default)
          Locale('es'), // Spanish
        ],
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
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              final userRole = authProvider.userRole;
              AppRoutes.navigateByRole(context, userRole);
            }
          });
        }

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

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:medrush/api/fcm.api.dart';
import 'package:medrush/firebase_options.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Servicio para manejar Firebase Cloud Messaging
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _messaging;
  String? _currentToken;
  bool _isInitialized = false;

  /// Inicializa el servicio FCM
  Future<void> initialize() async {
    if (_isInitialized) {
      logInfo('FCM ya está inicializado');
      return;
    }

    try {
      logInfo('Inicializando Firebase Cloud Messaging...');

      // En web, FCM puede no estar disponible
      if (kIsWeb) {
        logInfo('Detectado entorno web, FCM puede tener limitaciones');
      }

      // Verificar si Firebase ya está inicializado
      try {
        Firebase.app(); // Esto lanza una excepción si no está inicializado
        logInfo('Firebase ya está inicializado');
      } catch (e) {
        logInfo('Firebase no está inicializado, inicializando...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _messaging = FirebaseMessaging.instance;

      // Configurar manejadores de mensajes
      _setupMessageHandlers();

      // Solicitar permisos (puede fallar en web)
      await _requestPermissions();

      // Obtener token (puede fallar en web)
      await _getToken();

      _isInitialized = true;
      logInfo('FCM inicializado exitosamente');
    } catch (e) {
      logError('Error al inicializar FCM', e);
      if (kIsWeb) {
        logWarning('FCM no disponible en web, continuando sin notificaciones');
        // En web, no re-lanzar el error para no bloquear el login
        return;
      }
      rethrow;
    }
  }

  /// Configura los manejadores de mensajes
  void _setupMessageHandlers() {
    if (_messaging == null) {
      return;
    }

    // Mensaje cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logInfo('Mensaje recibido en primer plano: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Mensaje cuando la app está en segundo plano y se abre desde la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logInfo('App abierta desde notificación: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Mensaje cuando la app está completamente cerrada y se abre desde la notificación
    _messaging!.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        logInfo(
            '📱 App abierta desde notificación (app cerrada): ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Solicita permisos para notificaciones
  Future<void> _requestPermissions() async {
    if (_messaging == null) {
      return;
    }

    try {
      final settings = await _messaging!.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        logInfo('Permisos de notificación concedidos');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        logInfo('Permisos provisionales de notificación concedidos');
      } else {
        logWarning('Permisos de notificación denegados');
      }
    } catch (e) {
      logError('Error al solicitar permisos de notificación', e);
    }
  }

  /// Obtiene el token FCM
  Future<String?> _getToken() async {
    if (_messaging == null) {
      return null;
    }

    try {
      _currentToken = await _messaging!.getToken();
      if (_currentToken != null) {
        logInfo('🔑 Token FCM obtenido: ${_currentToken!.substring(0, 20)}...');
      }
      return _currentToken;
    } catch (e) {
      logError('❌ Error al obtener token FCM', e);
      return null;
    }
  }

  /// Registra el token en el backend
  Future<bool> registerToken() async {
    if (_currentToken == null) {
      logWarning('⚠️ No hay token FCM disponible para registrar');
      return false;
    }

    try {
      logInfo('Registrando token FCM en el backend...');

      final deviceInfo = await _getDeviceInfo();
      final platform = _getPlatform();

      final success = await FcmApi.registerDeviceToken(
        token: _currentToken!,
        deviceType: platform,
        deviceName: deviceInfo['deviceName'],
        appVersion: deviceInfo['appVersion'],
      );

      if (success) {
        logInfo('Token FCM registrado exitosamente en el backend');
      } else {
        logError('Error al registrar token FCM en el backend');
      }

      return success;
    } catch (e) {
      logError('Error al registrar token FCM', e);
      return false;
    }
  }

  /// Obtiene información del dispositivo
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceName = 'Dispositivo Desconocido';
      String platform = 'unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        platform = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} ${iosInfo.model}';
        platform = 'ios';
      } else if (kIsWeb) {
        deviceName = 'Web Browser';
        platform = 'web';
      }

      return {
        'deviceName': deviceName,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'platform': platform,
      };
    } catch (e) {
      logError('❌ Error al obtener información del dispositivo', e);
      return {
        'deviceName': 'Dispositivo Desconocido',
        'appVersion': '1.0.0',
        'buildNumber': '1',
        'platform': 'unknown',
      };
    }
  }

  /// Obtiene la plataforma actual
  String _getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (kIsWeb) {
      return 'web';
    }
    return 'unknown';
  }

  /// Maneja mensajes en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    logInfo('Procesando mensaje en primer plano:');
    logInfo('   Título: ${message.notification?.title}');
    logInfo('   Cuerpo: ${message.notification?.body}');
    logInfo('   Datos: ${message.data}');

    // Aquí puedes mostrar un diálogo, snackbar, o actualizar la UI
    // Por ejemplo, usando un provider o notificando a otros widgets
  }

  /// Maneja cuando se toca una notificación
  void _handleNotificationTap(RemoteMessage message) {
    logInfo('👆 Notificación tocada:');
    logInfo('   Título: ${message.notification?.title}');
    logInfo('   Cuerpo: ${message.notification?.body}');
    logInfo('   Datos: ${message.data}');

    // Aquí puedes navegar a una pantalla específica basada en los datos
    // Por ejemplo, navegar a un pedido específico si viene en message.data
  }

  /// Obtiene el token actual
  String? get currentToken => _currentToken;

  /// Verifica si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Refresca el token FCM
  Future<String?> refreshToken() async {
    if (_messaging == null) {
      return null;
    }

    try {
      _currentToken = await _messaging!.getToken();
      if (_currentToken != null) {
        logInfo(
            '🔄 Token FCM refrescado: ${_currentToken!.substring(0, 20)}...');
        // Re-registrar el nuevo token en el backend
        await registerToken();
      }
      return _currentToken;
    } catch (e) {
      logError('❌ Error al refrescar token FCM', e);
      return null;
    }
  }

  /// Suscribe a un tema
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) {
      return;
    }

    try {
      await _messaging!.subscribeToTopic(topic);
      logInfo('📢 Suscrito al tema: $topic');
    } catch (e) {
      logError('❌ Error al suscribirse al tema: $topic', e);
    }
  }

  /// Se desuscribe de un tema
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) {
      return;
    }

    try {
      await _messaging!.unsubscribeFromTopic(topic);
      logInfo('📢 Desuscrito del tema: $topic');
    } catch (e) {
      logError('❌ Error al desuscribirse del tema: $topic', e);
    }
  }

  /// Limpia recursos
  void dispose() {
    _messaging = null;
    _currentToken = null;
    _isInitialized = false;
    logInfo('🧹 FCM Service disposed');
  }
}

/// Manejador de mensajes en segundo plano (debe ser una función de nivel superior)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    Firebase.app(); // Verificar si ya está inicializado
  } catch (e) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ); // Solo inicializar si no está inicializado
  }
  logInfo('Mensaje en segundo plano: ${message.messageId}');
  logInfo('   Título: ${message.notification?.title}');
  logInfo('   Cuerpo: ${message.notification?.body}');
  logInfo('   Datos: ${message.data}');
}

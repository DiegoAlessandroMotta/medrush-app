import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:medrush/utils/loggers.dart';

class EndpointManager {
  // ===== CONFIGURACIÓN DE RED =====

  // Detectar entorno local (simple flag para desarrollo)
  static const bool _isLocal = true;

  // URLs del servidor de producción
  static const String _prodDomain = 'medrush.ksdemosapps.com';

  // IP local para dispositivos físicos (cambiar según tu red)
  // Usa la IP de tu adaptador Wi-Fi o Ethernet activo
  // Ejemplo: '192.168.1.3' (Wi-Fi) o '192.168.1.40' (Ethernet)
  static const String _localIp = '192.168.1.3';
  static const int _localPort = 4000;

  // Cache para la detección del emulador
  static bool? _isEmulatorCache;

  /// Detecta si está ejecutándose en un emulador de Android
  /// Usa múltiples métodos para mayor confiabilidad
  static bool get _isAndroidEmulator {
    if (!Platform.isAndroid) {
      return false;
    }
    
    // Usar cache si está disponible
    if (_isEmulatorCache != null) {
      return _isEmulatorCache!;
    }
    
    bool isEmulator = false;
    
    // Método 1: Verificar variable de entorno ANDROID_SERIAL
    final androidSerial = Platform.environment['ANDROID_SERIAL'];
    if (androidSerial != null && androidSerial.startsWith('emulator')) {
      isEmulator = true;
    }
    
    // Método 2: Verificar modelo del dispositivo (emuladores suelen tener nombres específicos)
    if (!isEmulator) {
      final model = Platform.environment['ANDROID_MODEL'];
      if (model != null) {
        final modelLower = model.toLowerCase();
        if (modelLower.contains('sdk') || 
            modelLower.contains('emulator') ||
            modelLower.contains('google_sdk') ||
            modelLower.contains('gphone')) {
          isEmulator = true;
        }
      }
    }
    
    // Método 3: Verificar marca del dispositivo
    if (!isEmulator) {
      final brand = Platform.environment['ANDROID_BRAND'];
      if (brand != null) {
        final brandLower = brand.toLowerCase();
        if (brandLower.contains('generic') || brandLower.contains('unknown')) {
          isEmulator = true;
        }
      }
    }
    
    // Método 4: Verificar hardware (emuladores suelen tener "goldfish" o "ranchu")
    if (!isEmulator) {
      final hardware = Platform.environment['ANDROID_HARDWARE'];
      if (hardware != null) {
        final hardwareLower = hardware.toLowerCase();
        if (hardwareLower.contains('goldfish') || 
            hardwareLower.contains('ranchu') ||
            hardwareLower.contains('vbox')) {
          isEmulator = true;
        }
      }
    }
    
    // Método 5: Usar device_info_plus de forma síncrona si es posible
    // Nota: Esto requiere una llamada asíncrona, pero podemos intentar detectar
    // basándonos en el nombre del dispositivo que aparece en los logs
    // "google sdk_gphone64_x86_64" contiene "sdk" y "gphone"
    
    // Cachear el resultado
    _isEmulatorCache = isEmulator;
    
    if (kDebugMode && Platform.isAndroid) {
      logDebug('[EndpointManager] Detección de emulador: $isEmulator');
      logDebug('[EndpointManager] ANDROID_SERIAL: ${Platform.environment['ANDROID_SERIAL']}');
      logDebug('[EndpointManager] ANDROID_MODEL: ${Platform.environment['ANDROID_MODEL']}');
      logDebug('[EndpointManager] ANDROID_BRAND: ${Platform.environment['ANDROID_BRAND']}');
      logDebug('[EndpointManager] ANDROID_HARDWARE: ${Platform.environment['ANDROID_HARDWARE']}');
    }
    
    return isEmulator;
  }
  
  /// Inicializa la detección del emulador de forma asíncrona
  /// Debe llamarse al inicio de la app para mejorar la detección
  static Future<void> initializeEmulatorDetection() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _isAndroidEmulatorAsync();
  }
  
  /// Detecta el emulador de forma asíncrona usando device_info_plus
  /// Este método es más confiable pero requiere async
  static Future<bool> _isAndroidEmulatorAsync() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Verificar características comunes de emuladores
      final model = androidInfo.model.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final device = androidInfo.device.toLowerCase();
      
      bool isEmulator = 
          model.contains('sdk') ||
          model.contains('emulator') ||
          model.contains('google_sdk') ||
          model.contains('gphone') ||
          brand.contains('generic') ||
          manufacturer.contains('unknown') ||
          device.contains('generic');
      
      // Actualizar cache
      _isEmulatorCache = isEmulator;
      
      if (kDebugMode) {
        logDebug('[EndpointManager] Async detección: $isEmulator');
        logDebug('[EndpointManager] Model: $model, Brand: $brand, Device: $device, Manufacturer: $manufacturer');
      }
      
      return isEmulator;
    } catch (e) {
      if (kDebugMode) {
        logError('[EndpointManager] Error detectando emulador', e);
      }
      return false;
    }
  }

  static String get serverDomain {
    if (_isLocal) {
      if (kIsWeb) {
        return 'localhost:4000';
      }
      // Si es emulador, usar 10.0.2.2 (IP especial del emulador)
      // Si es dispositivo físico, usar la IP local de la máquina
      final isEmulator = _isAndroidEmulator;
      if (isEmulator) {
        return '10.0.2.2:$_localPort';
      }
      // Dispositivo físico: usar IP local configurada
      return '$_localIp:$_localPort';
    }
    return _prodDomain;
  }

  static String get serverUrl =>
      _isLocal ? 'http://$serverDomain/api' : 'https://$serverDomain/api';
  static String get serverWebSocketUrl =>
      _isLocal ? 'ws://$serverDomain/ws' : 'wss://$serverDomain/ws';

  // Configuración de URLs
  static String get baseUrl => serverUrl;

  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 60000; // 60 segundos
  static const int sendTimeout = 60000; // 60 segundos

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Configuración de autenticación
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String sessionKey = 'laravel_session';
  static const String lastUsedEmailKey = 'last_used_email';

  // Configuración de WebSocket - siempre usar el servidor de producción
  static String get websocketUrl => serverWebSocketUrl;

  // API Key de Google Maps
  static const String googleMapsApiKey =
      'AIzaSyAMgHYDRMHOOLGXWvMUBZWieIhsW3bb6Rg';

  // Configuración de CSV
  static const List<String> csvHeaders = [
    'paciente_nombre',
    'paciente_telefono',
    'direccion',
    'direccion_detalle',
    'latitud',
    'longitud',
    'observaciones',
    'tipo_medicamento',
    'medicamentos',
    'codigo_acceso',
    'prioridad',
  ];

  // ===== ENDPOINTS BASE =====
  static const String auth = '/auth';
  static const String user = '/user';
  static const String farmacias = '/farmacias';
  static const String pedidos = '/pedidos';
  static const String repartidores = '/user/repartidores';
  static const String rutas = '/rutas';
  static const String fcm = '/fcm';
  static const String notificaciones = '/user/notificaciones';

  // Endpoints de autenticación
  static const String login = '$auth/login';
  static const String me = '$auth/me';
  static const String logout = '$auth/logout';
  static const String logoutAll = '$auth/logout-all';
  static const String tokens = '$auth/tokens';
  static String revokeToken(String tokenId) => '$auth/tokens/$tokenId';

  // Endpoints de usuario
  static String userFoto(String userId) => '$user/$userId/foto';
  static String userActivo(String userId) => '$user/$userId/activo';
  static const String userNotifications = '$user/notificaciones';

  // Endpoints de farmacias
  static String farmaciaById(String id) => '$farmacias/$id';
  static String farmaciaUsers(String id) => '$farmacias/$id/users';
  static String farmaciaByRucEin(String rucEin) => '$farmacias/ruc-ein/$rucEin';

  // Endpoints de pedidos
  static const String pedidosCargarCsv = '$pedidos/cargar-csv';
  static const String pedidosGenerarEtiquetasPdf =
      '/reportes-pdf/etiquetas-pedido';
  static String reportePdfById(String id) => '/reportes-pdf/$id';
  static String pedidoById(String id) => '$pedidos/$id';
  static String pedidoByCodigoBarra(String codigoBarra) =>
      '$pedidos/codigo-barra/$codigoBarra';
  static String pedidoEntregar(String id) => '$pedidos/$id/entregar';
  static String pedidoEventos(String id) => '$pedidos/$id/eventos';
  static String pedidoAsignar(String id) => '$pedidos/$id/asignar';
  static String pedidoAsignarByCodigoBarra(String codigoBarra) =>
      '$pedidos/$codigoBarra/asignar/codigo-barra';
  static String pedidoRetirarRepartidor(String id) =>
      '$pedidos/$id/retirar-repartidor';
  static String pedidoCancelar(String id) => '$pedidos/$id/cancelar';
  static String pedidoRecoger(String id) => '$pedidos/$id/recoger';
  static String pedidoRecogerByCodigoBarra(String codigoBarra) =>
      '$pedidos/$codigoBarra/recoger/codigo-barra';
  static String pedidoEnRuta(String id) => '$pedidos/$id/en-ruta';
  static String pedidoFalloEntrega(String id) => '$pedidos/$id/fallo-entrega';

  // Endpoints de repartidores
  static String repartidorById(String id) => '$repartidores/$id';
  static String repartidorDniId(String id) => '$repartidores/$id/dni-id';
  static String repartidorLicencia(String id) => '$repartidores/$id/licencia';
  static String repartidorSeguroVehiculo(String id) =>
      '$repartidores/$id/seguro-vehiculo';
  static String repartidorVerificado(String id) =>
      '$repartidores/$id/verificado';
  static String repartidorEstado(String id) => '$repartidores/$id/estado';

  // Endpoints de rutas
  static const String rutasOptimizar = '$rutas/optimizar';
  static const String rutasCurrent = '$rutas/current';
  static String rutaById(String id) => '$rutas/$id';
  static String rutaOptimizar(String id) => '$rutas/$id/optimizar';
  static String rutaPedidos(String id) => '$rutas/$id/pedidos';
  static String rutaPedidosReordenar(String id) =>
      '$rutas/$id/pedidos/reordenar';
  static String rutaPedidoRemove(String rutaId, String pedidoId) =>
      '$rutas/$rutaId/pedidos/$pedidoId';

  // Endpoints de FCM
  static const String fcmTokens = '$fcm/tokens';
  static String fcmTokenDelete(String token) => '$fcm/tokens/$token';
  static const String fcmTokenDeleteCurrentSession =
      '$fcm/tokens/current-session';

  // Endpoints de ubicaciones repartidor
  static const String ubicacionesRepartidor = '/ubicaciones-repartidor';

  // Endpoints de geocoding
  static const String geocoding = '/geocoding';
  static const String geocodingReverse = '$geocoding/reverse';

  // Endpoints de directions
  static const String directions = '/directions';
  static const String directionsWithWaypoints = '$directions/with-waypoints';
  static const String directionsRouteInfo = '$directions/route-info';

  // Endpoints de descargas
  static String downloadTemplateSignedUrl(String lang, String templateKey) =>
      '/downloads/templates/csv/$lang/$templateKey/signed-url';
  static String downloadTemplate(String lang, String templateKey) =>
      '/downloads/templates/csv/$lang/$templateKey';
  static const String downloadApk = '/downloads/medrush-app/apk';

  /// Construye endpoint con parámetros de ruta
  static String buildEndpoint(String template, Map<String, String> params) {
    String endpoint = template;
    params.forEach((key, value) {
      endpoint = endpoint.replaceAll('{$key}', value);
    });
    return endpoint;
  }

  /// Construye endpoint con query parameters
  static String buildEndpointWithQuery(
    String endpoint,
    Map<String, dynamic> queryParams,
  ) {
    if (queryParams.isEmpty) {
      return endpoint;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$endpoint?$queryString';
  }

  // ===== MÉTODOS DE UTILIDAD =====

  /// Obtiene la URL base actual
  static String get currentBaseUrl {
    // Para localhost, usar siempre la URL completa del servidor
    return baseUrl;
  }

  /// Construye una URL completa para un endpoint
  static String buildUrl(String endpoint) {
    return '$currentBaseUrl$endpoint';
  }

  /// Construye una URL con parámetros de ruta
  static String buildUrlWithParams(
      String endpoint, Map<String, dynamic> params) {
    String url = endpoint;
    params.forEach((key, value) {
      url = url.replaceAll('{$key}', value.toString());
    });
    return buildUrl(url);
  }

  /// Construye headers con token de autenticación
  static Map<String, String> buildAuthHeaders(String? token) {
    final headers = Map<String, String>.from(defaultHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Obtiene configuración de timeouts centralizada
  static Map<String, int> getTimeoutConfig() {
    return {
      'connectTimeout': connectTimeout,
      'receiveTimeout': receiveTimeout,
      'sendTimeout': sendTimeout,
    };
  }

  /// Construye parámetros de paginación
  static Map<String, dynamic> buildPaginationParams({
    int page = 1,
    int perPage = defaultPageSize,
    String? orderBy,
    String orderDirection = 'desc',
  }) {
    final params = <String, dynamic>{
      'current_page': page,
      'per_page': perPage.clamp(1, maxPageSize),
      'order_direction': orderDirection,
    };

    if (orderBy != null) {
      params['order_by'] = orderBy;
    }

    return params;
  }

  /// URL base fija para la aplicación
  static String get currentHost => serverDomain;

  /// Información de debug para la configuración de red
  static Map<String, dynamic> get debugInfo {
    return {
      'isWeb': kIsWeb,
      'platform': kIsWeb ? 'web' : 'mobile',
      'baseUrl': baseUrl,
      'websocketUrl': websocketUrl,
      'currentHost': currentHost,
      'serverDomain': serverDomain,
    };
  }
}

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:medrush/utils/loggers.dart';

class EndpointManager {
  static const String _apiBaseUrlFromEnv =
      String.fromEnvironment('API_BASE_URL');

  /// Dominio del backend en producción (api.medrush.cc con HTTPS en Dokploy).
  static const String _prodDomain = 'api.medrush.cc';

  /// Inicializa la detección del emulador (Android). No-op en web.
  static Future<void> initializeEmulatorDetection() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _isAndroidEmulatorAsync();
  }

  static Future<bool> _isAndroidEmulatorAsync() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final model = androidInfo.model.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final device = androidInfo.device.toLowerCase();
      final isEmulator = model.contains('sdk') ||
          model.contains('emulator') ||
          model.contains('google_sdk') ||
          model.contains('gphone') ||
          brand.contains('generic') ||
          manufacturer.contains('unknown') ||
          device.contains('generic');
      if (kDebugMode) {
        logDebug('[EndpointManager] Async detección emulador: $isEmulator');
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
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      final uri = Uri.parse(_apiBaseUrlFromEnv);
      return uri.port != 80 && uri.port != 443
          ? '${uri.host}:${uri.port}'
          : uri.host;
    }
    return _prodDomain;
  }

  /// URL base del API. Sin API_BASE_URL se usa https://api.medrush.cc (producción con SSL).
  static String get serverUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv.endsWith('/api')
          ? _apiBaseUrlFromEnv
          : '$_apiBaseUrlFromEnv/api';
    }
    return 'https://$serverDomain/api';
  }

  static String get serverWebSocketUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      final base = _apiBaseUrlFromEnv.endsWith('/api')
          ? _apiBaseUrlFromEnv.substring(0, _apiBaseUrlFromEnv.length - 4)
          : _apiBaseUrlFromEnv;
      final scheme = base.startsWith('https') ? 'wss' : 'ws';
      final rest =
          base.contains('://') ? base.substring(base.indexOf('://') + 3) : base;
      return '$scheme://$rest/ws';
    }
    return 'wss://$serverDomain/ws';
  }

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
      'AIzaSyBquo-0Ex1O2hHcSkcgOUdGo2FQ44LtcOA';

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

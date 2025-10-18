import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/utils/loggers.dart';

class AuthApi {
  /// Inicia sesión de un usuario
  ///
  /// [email] - Email del usuario
  /// [password] - Contraseña del usuario
  /// [deviceName] - Nombre del dispositivo (requerido por Laravel Sanctum)
  ///
  /// Retorna un Map con:
  /// - user: datos del usuario autenticado
  /// - access_token: token de acceso para futuras peticiones
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.post<Map<String, dynamic>>(
          EndpointManager.login,
          data: {
            'email': email,
            'password': password,
            'device_name': deviceName,
          },
        );
        return response.data as Map<String, dynamic>;
      },
      operationName: 'Iniciando sesión para: $email',
      successMessage: 'Login exitoso para: $email',
    );
  }

  /// Obtiene la información del usuario autenticado
  ///
  /// [token] - Token de acceso Bearer
  ///
  /// Retorna los datos del usuario autenticado
  static Future<Map<String, dynamic>> getMe(String token) {
    return ApiHelper.executeWithLogging(
      () async {
        ApiHelper.setAuthHeaders(token);
        final response = await BaseApi.get<Map<String, dynamic>>(
          EndpointManager.me,
        );
        return response.data as Map<String, dynamic>;
      },
      operationName: 'Obteniendo información del usuario autenticado',
      successMessage: 'Información del usuario obtenida exitosamente',
    );
  }

  /// Cierra la sesión del usuario (revoca el token actual)
  ///
  /// [token] - Token de acceso Bearer
  static Future<bool> logout(String token) {
    return ApiHelper.executeWithLogging(
      () async {
        ApiHelper.setAuthHeaders(token);
        await BaseApi.post(EndpointManager.logout);
        return true;
      },
      operationName: 'Cerrando sesión del usuario',
      successMessage: 'Sesión cerrada exitosamente',
    );
  }

  /// Cierra todas las sesiones del usuario (revoca todos los tokens)
  ///
  /// [token] - Token de acceso Bearer
  static Future<bool> logoutAll(String token) {
    return ApiHelper.executeWithLogging(
      () async {
        ApiHelper.setAuthHeaders(token);
        await BaseApi.post(EndpointManager.logoutAll);
        return true;
      },
      operationName: 'Cerrando todas las sesiones del usuario',
      successMessage: 'Todas las sesiones cerradas exitosamente',
    );
  }

  /// Lista todas las sesiones activas del usuario
  ///
  /// [token] - Token de acceso Bearer
  static Future<List<Map<String, dynamic>>> listTokens(String token) async {
    try {
      logInfo('📱 Obteniendo lista de sesiones activas');

      // Configurar headers de autorización
      BaseApi.setCustomHeaders({'Authorization': 'Bearer $token'});

      // El backend responde envuelto en { status, message, data: [] }
      final response = await BaseApi.get<Map<String, dynamic>>(
        EndpointManager.tokens,
      );

      final map = response.data as Map<String, dynamic>;
      final dynamic data = map['data'];
      final List tokensRaw = (data is List) ? data : <dynamic>[];

      final tokens = tokensRaw
          .map((t) => (t as Map).map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();

      logInfo('✅ Lista de sesiones obtenida: ${tokens.length} sesiones');
      return tokens;
    } catch (e) {
      logError('❌ Error al obtener lista de sesiones', e);
      rethrow;
    }
  }

  /// Revoca un token específico
  ///
  /// [token] - Token de acceso Bearer
  /// [tokenId] - ID del token a revocar
  static Future<bool> revokeToken(String token, String tokenId) async {
    try {
      logInfo('🗑️ Revocando token: $tokenId');

      // Configurar headers de autorización
      BaseApi.setCustomHeaders({'Authorization': 'Bearer $token'});

      await BaseApi.delete(
        EndpointManager.revokeToken(tokenId),
      );

      logInfo('✅ Token revocado exitosamente: $tokenId');
      return true;
    } catch (e) {
      logError('❌ Error al revocar token: $tokenId', e);
      rethrow;
    }
  }

  /// Registra un nuevo usuario repartidor
  ///
  /// [userData] - Datos del usuario repartidor
  /// [deviceName] - Nombre del dispositivo
  ///
  /// Retorna un Map con:
  /// - user: datos del usuario registrado
  /// - access_token: token de acceso para futuras peticiones
  static Future<Map<String, dynamic>> registerRepartidor({
    required Map<String, dynamic> userData,
    required String deviceName,
  }) async {
    try {
      logInfo('👤 Registrando nuevo usuario repartidor');

      final response = await BaseApi.post<Map<String, dynamic>>(
        EndpointManager.repartidores,
        data: {
          ...userData,
          'device_name': deviceName,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      logInfo('✅ Usuario repartidor registrado exitosamente');
      logDebug('📦 Response data: $responseData');

      return responseData;
    } catch (e) {
      logError('❌ Error al registrar usuario repartidor', e);
      rethrow;
    }
  }

  /// Registra un nuevo usuario farmacia
  ///
  /// [userData] - Datos del usuario farmacia
  /// [deviceName] - Nombre del dispositivo
  ///
  /// Retorna un Map con:
  /// - user: datos del usuario registrado
  /// - access_token: token de acceso para futuras peticiones
  static Future<Map<String, dynamic>> registerFarmacia({
    required Map<String, dynamic> userData,
    required String deviceName,
  }) async {
    try {
      logInfo('🏥 Registrando nuevo usuario farmacia');

      final response = await BaseApi.post<Map<String, dynamic>>(
        '/user/farmacias',
        data: {
          ...userData,
          'device_name': deviceName,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      logInfo('✅ Usuario farmacia registrado exitosamente');
      logDebug('📦 Response data: $responseData');

      return responseData;
    } catch (e) {
      logError('❌ Error al registrar usuario farmacia', e);
      rethrow;
    }
  }

  /// Registra un nuevo usuario administrador
  ///
  /// [userData] - Datos del usuario administrador
  /// [deviceName] - Nombre del dispositivo
  ///
  /// Retorna un Map con:
  /// - user: datos del usuario registrado
  /// - access_token: token de acceso para futuras peticiones
  static Future<Map<String, dynamic>> registerAdmin({
    required Map<String, dynamic> userData,
    required String deviceName,
  }) async {
    try {
      logInfo('👨‍💼 Registrando nuevo usuario administrador');

      final response = await BaseApi.post<Map<String, dynamic>>(
        '/user/administradores',
        data: {
          ...userData,
          'device_name': deviceName,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      logInfo('✅ Usuario administrador registrado exitosamente');
      logDebug('📦 Response data: $responseData');

      return responseData;
    } catch (e) {
      logError('❌ Error al registrar usuario administrador', e);
      rethrow;
    }
  }
}

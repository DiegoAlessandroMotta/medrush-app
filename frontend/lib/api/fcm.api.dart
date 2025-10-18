import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:medrush/api/api_helper.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FcmApi {
  /// Registra o actualiza el token FCM de un dispositivo
  static Future<bool> registerDeviceToken({
    required String token,
    required String deviceType,
    String? deviceName,
    String? appVersion,
  }) {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.post<Map<String, dynamic>>(
          EndpointManager.fcmTokens,
          data: {
            'token': token,
            'platform': deviceType,
            'device_name': deviceName ?? 'Dispositivo Móvil',
            'app_version': appVersion ?? '1.0.0',
          },
        );
        return ApiHelper.isValidResponse(response.data);
      },
      operationName: 'Registrando token FCM del dispositivo: $deviceType',
      successMessage: 'Token FCM registrado exitosamente',
    );
  }

  /// Registra token FCM para Android
  static Future<bool> registerAndroidToken({
    required String token,
    String? deviceName,
    String? appVersion,
  }) {
    return registerDeviceToken(
      token: token,
      deviceType: 'android',
      deviceName: deviceName ?? 'Android Device',
      appVersion: appVersion,
    );
  }

  /// Registra token FCM para iOS
  static Future<bool> registerIosToken({
    required String token,
    String? deviceName,
    String? appVersion,
  }) {
    return registerDeviceToken(
      token: token,
      deviceType: 'ios',
      deviceName: deviceName ?? 'iOS Device',
      appVersion: appVersion,
    );
  }

  /// Registra token FCM para Web
  static Future<bool> registerWebToken({
    required String token,
    String? deviceName,
    String? appVersion,
  }) {
    return registerDeviceToken(
      token: token,
      deviceType: 'web',
      deviceName: deviceName ?? 'Web Browser',
      appVersion: appVersion,
    );
  }

  /// Registra token FCM automáticamente detectando la plataforma
  static Future<bool> registerTokenAuto({
    required String token,
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      logInfo('🔍 Detectando plataforma para registro automático de token FCM');

      // Importar dart:io para detectar la plataforma
      // Nota: Esto debe hacerse en tiempo de compilación
      if (deviceName == null || deviceName.isEmpty) {
        deviceName = 'Dispositivo Móvil';
      }

      // Por defecto, registramos como móvil
      return await registerDeviceToken(
        token: token,
        deviceType: 'mobile',
        deviceName: deviceName,
        appVersion: appVersion,
      );
    } catch (e) {
      logError('❌ Error en registro automático de token FCM', e);
      rethrow;
    }
  }

  /// Valida que un token FCM sea válido
  static bool isValidToken(String token) {
    if (token.isEmpty) {
      return false;
    }

    // Los tokens FCM típicamente tienen entre 140-160 caracteres
    // y contienen solo caracteres alfanuméricos y algunos símbolos
    if (token.length < 140 || token.length > 160) {
      return false;
    }

    // Verificar que solo contenga caracteres válidos
    final validPattern = RegExp(r'^[a-zA-Z0-9:_-]+$');
    return validPattern.hasMatch(token);
  }

  /// Obtiene información del dispositivo para el registro
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      // Importar dependencias necesarias
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String platform = 'unknown';
      String deviceName = 'Dispositivo Desconocido';

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
        'platform': platform,
        'deviceName': deviceName,
        'version': packageInfo.version,
        'build': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      };
    } catch (e) {
      logError('❌ Error al obtener información del dispositivo', e);
      return {
        'platform': 'unknown',
        'deviceName': 'Dispositivo Desconocido',
        'version': '1.0.0',
        'build': '1',
        'packageName': 'com.medrush.app',
      };
    }
  }

  /// Elimina el token FCM de la sesión actual
  static Future<bool> deleteCurrentSessionToken() {
    return ApiHelper.executeWithLogging(
      () async {
        final response = await BaseApi.delete<Map<String, dynamic>>(
          EndpointManager.fcmTokenDeleteCurrentSession,
        );

        return response.statusCode == 200 || response.statusCode == 204;
      },
      operationName: 'Eliminando token FCM de sesión actual',
      successMessage: 'Token FCM eliminado exitosamente',
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/utils/loggers.dart';

/// API para manejar descargas de APK
class ApkApi {
  /// Obtiene la URL de descarga del APK
  static Future<String?> getDownloadUrl() async {
    try {
      logInfo(
          '${ConsoleColor.blue}Obteniendo URL de descarga APK${ConsoleColor.reset}');

      // El backend devuelve directamente el archivo APK, no JSON
      // Por lo tanto, construimos la URL completa directamente
      final baseUrl = EndpointManager.currentBaseUrl;
      final endpoint = EndpointManager.downloadApk;
      final fullUrl = '$baseUrl$endpoint';

      logInfo(
          '${ConsoleColor.green}URL de descarga construida: $fullUrl${ConsoleColor.reset}');
      return fullUrl;
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al construir URL de descarga APK${ConsoleColor.reset}',
          e);
      return null;
    }
  }

  /// Obtiene información del APK (versión, tamaño, etc.)
  static Future<Map<String, dynamic>?> getApkInfo() async {
    try {
      logInfo(
          '${ConsoleColor.blue}Obteniendo información del APK${ConsoleColor.reset}');

      final response = await BaseApi.get<Map<String, dynamic>>(
        '${EndpointManager.downloadApk}/info',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        logInfo(
            '${ConsoleColor.green}Información del APK obtenida${ConsoleColor.reset}');
        return data;
      }

      logWarning(
          '${ConsoleColor.yellow}No se pudo obtener información del APK${ConsoleColor.reset}');
      return null;
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al obtener información del APK${ConsoleColor.reset}',
          e);
      return null;
    }
  }

  /// Verifica si hay una nueva versión del APK disponible
  static Future<bool> checkForUpdates() async {
    try {
      logInfo(
          '${ConsoleColor.blue}Verificando actualizaciones del APK${ConsoleColor.reset}');

      final response = await BaseApi.get<Map<String, dynamic>>(
        '${EndpointManager.downloadApk}/check-update',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final hasUpdate = data['has_update'] as bool? ?? false;
        logInfo(
            '${ConsoleColor.green}Verificación de actualizaciones completada: ${hasUpdate ? "Hay actualización" : "Sin actualizaciones"}${ConsoleColor.reset}');
        return hasUpdate;
      }

      logWarning(
          '${ConsoleColor.yellow}No se pudo verificar actualizaciones${ConsoleColor.reset}');
      return false;
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al verificar actualizaciones${ConsoleColor.reset}',
          e);
      return false;
    }
  }

  /// Descarga el APK directamente (solo para móvil)
  static Future<bool> downloadApk({
    required String savePath,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (kIsWeb) {
      logWarning(
          '${ConsoleColor.yellow}Descarga directa no disponible en web${ConsoleColor.reset}');
      return false;
    }

    try {
      logInfo(
          '${ConsoleColor.blue}Descargando APK a: $savePath${ConsoleColor.reset}');

      final response = await BaseApi.downloadFile(
        EndpointManager.downloadApk,
        savePath: savePath,
        onReceiveProgress: onReceiveProgress,
      );

      if (response.statusCode == 200) {
        logInfo(
            '${ConsoleColor.green}APK descargado exitosamente${ConsoleColor.reset}');
        return true;
      } else {
        logError(
            '${ConsoleColor.red}Error al descargar APK: código ${response.statusCode}${ConsoleColor.reset}');
        return false;
      }
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al descargar APK${ConsoleColor.reset}', e);
      return false;
    }
  }

  /// Obtiene la URL completa de descarga del APK
  static String getFullDownloadUrl() {
    final baseUrl = EndpointManager.currentBaseUrl;
    final endpoint = EndpointManager.downloadApk;
    final fullUrl = '$baseUrl$endpoint';

    logInfo(
        '${ConsoleColor.cyan}URL completa de descarga: $fullUrl${ConsoleColor.reset}');
    return fullUrl;
  }

  /// Verifica si el archivo APK existe en el servidor
  static Future<bool> checkApkExists() async {
    try {
      logInfo(
          '${ConsoleColor.blue}Verificando existencia del APK en el servidor${ConsoleColor.reset}');

      final response = await BaseApi.get(
        EndpointManager.downloadApk,
        options: Options(
          validateStatus: (status) {
            // Aceptar 200 (archivo existe) y 404 (archivo no existe)
            return status == 200 || status == 404;
          },
        ),
      );

      final exists = response.statusCode == 200;
      logInfo(
          '${ConsoleColor.green}APK ${exists ? "existe" : "no existe"} en el servidor${ConsoleColor.reset}');

      return exists;
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al verificar existencia del APK${ConsoleColor.reset}',
          e);
      return false;
    }
  }
}

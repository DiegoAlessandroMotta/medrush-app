import 'package:medrush/api/apk.api.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/utils/loggers.dart';

/// Modelo para información del APK
class ApkInfo {
  final String version;
  final String buildNumber;
  final int fileSize;
  final String downloadUrl;
  final DateTime releaseDate;
  final String? changelog;

  const ApkInfo({
    required this.version,
    required this.buildNumber,
    required this.fileSize,
    required this.downloadUrl,
    required this.releaseDate,
    this.changelog,
  });

  factory ApkInfo.fromJson(Map<String, dynamic> json) {
    return ApkInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['build_number'] as String? ?? '1',
      fileSize: json['file_size'] as int? ?? 0,
      downloadUrl: json['download_url'] as String? ?? '',
      releaseDate: DateTime.tryParse(json['release_date'] as String? ?? '') ??
          DateTime.now(),
      changelog: json['changelog'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'build_number': buildNumber,
      'file_size': fileSize,
      'download_url': downloadUrl,
      'release_date': releaseDate.toIso8601String(),
      'changelog': changelog,
    };
  }

  /// Formatea el tamaño del archivo en formato legible
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}

/// Resultado de verificación de actualizaciones
class UpdateCheckResult {
  final bool hasUpdate;
  final ApkInfo? latestVersion;
  final String? currentVersion;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.currentVersion,
  });
}

/// Repositorio para manejar operaciones relacionadas con APK
class ApkRepository extends BaseRepository {
  /// Obtiene la URL de descarga del APK
  Future<RepositoryResult<String>> getDownloadUrl() {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Obteniendo URL de descarga APK${ConsoleColor.reset}');

        final url = await ApkApi.getDownloadUrl();
        if (url == null) {
          throw Exception('No se pudo obtener la URL de descarga');
        }

        return url;
      },
      errorMessage: 'Error al obtener URL de descarga del APK',
    );
  }

  /// Obtiene información detallada del APK
  Future<RepositoryResult<ApkInfo>> getApkInfo() {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Obteniendo información del APK${ConsoleColor.reset}');

        final infoData = await ApkApi.getApkInfo();
        if (infoData == null) {
          throw Exception('No se pudo obtener información del APK');
        }

        final apkInfo = ApkInfo.fromJson(infoData);
        logInfo(
            '${ConsoleColor.green}Información del APK obtenida: v${apkInfo.version}${ConsoleColor.reset}');

        return apkInfo;
      },
      errorMessage: 'Error al obtener información del APK',
    );
  }

  /// Verifica si hay actualizaciones disponibles
  Future<RepositoryResult<UpdateCheckResult>> checkForUpdates({
    String? currentVersion,
  }) {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Verificando actualizaciones del APK${ConsoleColor.reset}');

        final hasUpdate = await ApkApi.checkForUpdates();
        ApkInfo? latestVersion;

        if (hasUpdate) {
          final infoResult = await getApkInfo();
          if (infoResult.success) {
            latestVersion = infoResult.data;
          }
        }

        final result = UpdateCheckResult(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          currentVersion: currentVersion,
        );

        logInfo(
            '${ConsoleColor.green}Verificación de actualizaciones completada: ${hasUpdate ? "Hay actualización" : "Sin actualizaciones"}${ConsoleColor.reset}');

        return result;
      },
      errorMessage: 'Error al verificar actualizaciones',
    );
  }

  /// Descarga el APK directamente (solo para móvil)
  Future<RepositoryResult<bool>> downloadApk({
    required String savePath,
    Function(int received, int total)? onProgress,
  }) {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Descargando APK a: $savePath${ConsoleColor.reset}');

        final success = await ApkApi.downloadApk(
          savePath: savePath,
          onReceiveProgress: onProgress,
        );

        if (!success) {
          throw Exception('Error al descargar el APK');
        }

        logInfo(
            '${ConsoleColor.green}APK descargado exitosamente${ConsoleColor.reset}');
        return true;
      },
      errorMessage: 'Error al descargar el APK',
    );
  }

  /// Obtiene la URL completa de descarga del APK
  Future<RepositoryResult<String>> getFullDownloadUrl() {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Obteniendo URL completa de descarga${ConsoleColor.reset}');

        final url = ApkApi.getFullDownloadUrl();
        logInfo(
            '${ConsoleColor.green}URL completa obtenida: $url${ConsoleColor.reset}');

        return url;
      },
      errorMessage: 'Error al obtener URL completa de descarga',
    );
  }

  /// Valida si una URL de descarga es válida
  Future<RepositoryResult<bool>> validateDownloadUrl(String url) {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Validando URL de descarga: $url${ConsoleColor.reset}');

        // Validaciones básicas
        if (url.isEmpty) {
          throw Exception('URL vacía');
        }

        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          throw Exception('URL debe comenzar con http:// o https://');
        }

        if (!url.endsWith('.apk')) {
          logWarning(
              '${ConsoleColor.yellow}URL no termina en .apk${ConsoleColor.reset}');
        }

        logInfo(
            '${ConsoleColor.green}URL de descarga válida${ConsoleColor.reset}');
        return true;
      },
      errorMessage: 'Error al validar URL de descarga',
    );
  }

  /// Verifica si el archivo APK existe en el servidor
  Future<RepositoryResult<bool>> checkApkExists() {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Verificando existencia del APK${ConsoleColor.reset}');

        final exists = await ApkApi.checkApkExists();
        logInfo(
            '${ConsoleColor.green}Verificación completada: APK ${exists ? "existe" : "no existe"}${ConsoleColor.reset}');

        return exists;
      },
      errorMessage: 'Error al verificar existencia del APK',
    );
  }

  /// Obtiene estadísticas de descarga del APK
  Future<RepositoryResult<Map<String, dynamic>>> getDownloadStats() {
    return execute(
      () async {
        logInfo(
            '${ConsoleColor.blue}Obteniendo estadísticas de descarga${ConsoleColor.reset}');

        // Verificar si el APK existe
        final existsResult = await checkApkExists();
        if (!existsResult.success || !existsResult.data!) {
          throw Exception('El archivo APK no existe en el servidor');
        }

        // Obtener URL de descarga
        final urlResult = await getFullDownloadUrl();
        if (!urlResult.success) {
          throw Exception('No se pudo obtener URL de descarga');
        }

        final stats = {
          'download_url': urlResult.data,
          'exists': true,
          'timestamp': DateTime.now().toIso8601String(),
        };

        logInfo(
            '${ConsoleColor.green}Estadísticas de descarga obtenidas${ConsoleColor.reset}');
        return stats;
      },
      errorMessage: 'Error al obtener estadísticas de descarga',
    );
  }
}

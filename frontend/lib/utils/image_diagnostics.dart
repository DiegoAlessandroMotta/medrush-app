import 'package:flutter/foundation.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/utils/loggers.dart';

/// Utilidades para diagnóstico de problemas con imágenes en Web
class ImageDiagnostics {
  /// Diagnostica problemas comunes con URLs de imágenes
  static Future<Map<String, dynamic>> diagnoseImageUrl(String url) async {
    final diagnostics = <String, dynamic>{
      'url': url,
      'isHttps': url.startsWith('https://'),
      'isHttp': url.startsWith('http://'),
      'hasExpiry': false,
      'isNearExpiry': false,
      'isAccessible': false,
      'issues': <String>[],
      'recommendations': <String>[],
    };

    try {
      // Verificar protocolo
      if (url.startsWith('http://')) {
        diagnostics['issues'].add('URL usa HTTP en lugar de HTTPS');
        diagnostics['recommendations']
            .add('Usar HTTPS para evitar bloqueos de mixed content');
      }

      // Verificar expiración
      final uri = Uri.parse(url);
      final expiresParam = uri.queryParameters['expires'];
      if (expiresParam != null) {
        diagnostics['hasExpiry'] = true;
        diagnostics['isNearExpiry'] = BaseApi.isUrlNearExpiry(url);

        if (diagnostics['isNearExpiry'] == true) {
          diagnostics['issues'].add('URL próxima a expirar');
          diagnostics['recommendations'].add('Renovar URL firmada del backend');
        }
      }

      // Verificar accesibilidad
      if (kIsWeb) {
        diagnostics['isAccessible'] = await BaseApi.isUrlAccessible(url);
        if (diagnostics['isAccessible'] == false) {
          diagnostics['issues'].add('URL no accesible (posible CORS/HTTPS)');
          diagnostics['recommendations'].addAll([
            'Verificar CORS en el servidor de imágenes',
            'Asegurar que la app y las imágenes usen el mismo protocolo (HTTPS)',
            'Verificar headers de Cache-Control en el servidor',
          ]);
        }
      }

      // Verificar si es URL firmada
      if (uri.queryParameters.containsKey('expires') &&
          uri.queryParameters.containsKey('signature')) {
        diagnostics['isSignedUrl'] = true;

        // Verificar longitud de signature
        final signature = uri.queryParameters['signature'] ?? '';
        if (signature.length != 64) {
          diagnostics['issues'].add(
              'Signature truncada: $signature (${signature.length} caracteres, esperado 64)');
          diagnostics['recommendations']
              .add('Verificar generación de URLs firmadas en el backend');
        }

        diagnostics['recommendations']
            .add('Usar URL firmada directamente del backend');
      }
    } catch (e) {
      diagnostics['issues'].add('Error al analizar URL: $e');
      diagnostics['recommendations'].add('Verificar formato de URL');
    }

    return diagnostics;
  }

  /// Genera un reporte de diagnóstico completo
  static Future<void> generateDiagnosticReport(String url) async {
    logInfo('🔍 Generando reporte de diagnóstico para: $url');

    final diagnostics = await diagnoseImageUrl(url);

    logInfo('📊 DIAGNÓSTICO DE IMAGEN:');
    logInfo('  URL: ${diagnostics['url']}');
    logInfo('  HTTPS: ${diagnostics['isHttps']}');
    logInfo('  Accesible: ${diagnostics['isAccessible']}');
    logInfo('  Tiene expiración: ${diagnostics['hasExpiry']}');
    logInfo('  Próxima a expirar: ${diagnostics['isNearExpiry']}');

    if (diagnostics['issues'].isNotEmpty) {
      logWarning('⚠️ PROBLEMAS DETECTADOS:');
      for (final issue in diagnostics['issues']) {
        logWarning('  - $issue');
      }
    }

    if (diagnostics['recommendations'].isNotEmpty) {
      logInfo('💡 RECOMENDACIONES:');
      for (final recommendation in diagnostics['recommendations']) {
        logInfo('  - $recommendation');
      }
    }
  }

  /// Verifica configuración de CORS recomendada
  static List<String> getCorsRecommendations() {
    return [
      'Access-Control-Allow-Origin: https://tu-dominio.com',
      'Access-Control-Allow-Methods: GET, HEAD, OPTIONS',
      'Access-Control-Allow-Headers: Authorization, Content-Type',
      'Access-Control-Max-Age: 86400',
      'Cache-Control: public, max-age=3600',
    ];
  }

  /// Verifica configuración de HTTPS recomendada
  static List<String> getHttpsRecommendations() {
    return [
      'Usar HTTPS para la aplicación web',
      'Usar HTTPS para el servidor de imágenes',
      'Configurar redirects HTTP -> HTTPS',
      'Usar certificados SSL válidos',
      'Verificar que no hay mixed content warnings',
    ];
  }
}

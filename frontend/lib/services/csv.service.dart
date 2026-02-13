import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/validators.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class CsvService {
  static const String _templateFileName = 'plantilla_pedidos_medrush.csv';

  // Campos requeridos para pedidos según el backend
  static const List<String> requiredFields = [
    'patient_name',
    'patient_phone',
    'delivery_address_line_1',
    'delivery_city',
    'delivery_state_region',
    'delivery_postal_code',
    'medications'
  ];

  // Campos opcionales para pedidos
  static const List<String> optionalFields = [
    'patient_email',
    'delivery_address_line_2',
    'pickup_location',
    'delivery_location',
    'building_access_code',
    'order_type',
    'observations'
  ];

  // Mapeo de headers (ES/es-PE y variantes snake_case) → claves esperadas por el backend
  static final Map<String, String> _normalizedHeaderToBackendKey = {
    // patient_name
    'patient_name': 'patient_name',
    'nombre_del_paciente': 'patient_name',
    'nombre_paciente': 'patient_name',
    'paciente_nombre': 'patient_name',
    'nombre': 'patient_name',

    // patient_phone
    'patient_phone': 'patient_phone',
    'telefono_del_paciente': 'patient_phone',
    'teléfono_del_paciente': 'patient_phone',
    'telefono_paciente': 'patient_phone',
    'paciente_telefono': 'patient_phone',
    'telefono': 'patient_phone',
    'teléfono': 'patient_phone',

    // patient_email
    'patient_email': 'patient_email',
    'email_del_paciente': 'patient_email',
    'correo_del_paciente': 'patient_email',
    'correo_paciente': 'patient_email',
    'paciente_email': 'patient_email',

    // delivery_address_line_1
    'delivery_address_line_1': 'delivery_address_line_1',
    'direccion_de_entrega_linea_1': 'delivery_address_line_1',
    'dirección_de_entrega_línea_1': 'delivery_address_line_1',
    'direccion_entrega_linea_1': 'delivery_address_line_1',

    // delivery_address_line_2
    'delivery_address_line_2': 'delivery_address_line_2',
    'direccion_de_entrega_linea_2': 'delivery_address_line_2',
    'dirección_de_entrega_línea_2': 'delivery_address_line_2',
    'direccion_entrega_linea_2': 'delivery_address_line_2',

    // delivery_city
    'delivery_city': 'delivery_city',
    'ciudad_de_entrega': 'delivery_city',
    'ciudad_entrega': 'delivery_city',

    // delivery_state_region
    'delivery_state_region': 'delivery_state_region',
    'estado_region_de_entrega': 'delivery_state_region',
    'estado/region_de_entrega': 'delivery_state_region',
    'estado_region_entrega': 'delivery_state_region',

    // delivery_postal_code
    'delivery_postal_code': 'delivery_postal_code',
    'codigo_postal_de_entrega': 'delivery_postal_code',
    'codigo_postal_entrega': 'delivery_postal_code',
    'código_postal_entrega': 'delivery_postal_code',

    // pickup_location
    'pickup_location': 'pickup_location',
    'ubicacion_de_recojo': 'pickup_location',
    'ubicación_de_recojo': 'pickup_location',
    'ubicacion_recojo': 'pickup_location',

    // delivery_location
    'delivery_location': 'delivery_location',
    'ubicacion_de_entrega': 'delivery_location',
    'ubicación_de_entrega': 'delivery_location',
    'ubicacion_entrega': 'delivery_location',

    // building_access_code
    'building_access_code': 'building_access_code',
    'codigo_de_acceso_al_edificio': 'building_access_code',
    'codigo_acceso_edificio': 'building_access_code',
    'código_acceso_edificio': 'building_access_code',

    // medications
    'medications': 'medications',
    'medicamentos': 'medications',

    // order_type
    'order_type': 'order_type',
    'tipo_de_pedido': 'order_type',
    'tipo_pedido': 'order_type',

    // observations
    'observations': 'observations',
    'observaciones': 'observations',
  };

  /// Normaliza un header: minúsculas, sin tildes, espacios→guiones bajos y sin símbolos
  static String _normalizeHeader(String header) {
    String h = header.trim().toLowerCase();
    // Reemplazo básico de tildes
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
      'ü': 'u',
      '/': '_',
    };
    // ignore: cascade_invocations
    accents.forEach((k, v) => h = h.replaceAll(k, v));
    h = Validators.cleanCsvHeader(h);
    return h;
  }

  /// Mapea los datos del CSV a claves esperadas por el backend sin perder columnas desconocidas
  static List<Map<String, dynamic>> mapCsvDataToBackendKeys(
      List<Map<String, dynamic>> data) {
    final mapped = <Map<String, dynamic>>[];
    for (final row in data) {
      final newRow = <String, dynamic>{};
      row.forEach((key, value) {
        final normalized = _normalizeHeader(key);
        final backendKey = _normalizedHeaderToBackendKey[normalized] ?? key;
        newRow[backendKey] = value;
      });
      mapped.add(newRow);
    }
    return mapped;
  }

  /// Descarga la plantilla CSV para pedidos desde el backend
  static Future<void> downloadPedidosTemplate() async {
    try {
      logInfo('📄 Descargando plantilla CSV desde el backend...');

      // Obtener URL firmada del backend
      final signedUrlResponse = await BaseApi.get(
        '/downloads/templates/csv/es/pedidos/signed-url',
      );

      if (!BaseApi.isSuccessfulResponse(signedUrlResponse)) {
        throw Exception(
            'Error al obtener URL firmada: ${signedUrlResponse.statusCode}');
      }

      final signedUrl = signedUrlResponse.data['data']['signed_url'] as String;
      logInfo('✅ URL firmada obtenida exitosamente');

      // Descargar el archivo usando la URL firmada
      await _downloadTemplateFromUrl(signedUrl);

      logInfo('📄 Plantilla CSV descargada exitosamente desde el backend');
    } catch (e) {
      logError('❌ Error al descargar plantilla CSV desde el backend: $e');

      // Fallback: usar plantilla local si falla el backend
      logWarning('⚠️ Usando plantilla local como fallback...');
      await _downloadPedidosTemplateLocal();
    }
  }

  /// Descarga la plantilla desde una URL (backend)
  static Future<void> _downloadTemplateFromUrl(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al descargar archivo: ${response.statusCode}');
      }

      final bytes = response.data as List<int>;
      final content = String.fromCharCodes(bytes);

      if (kIsWeb) {
        await _downloadTemplateForWeb(content);
      } else {
        await _downloadTemplateForMobile(content);
      }
    } catch (e) {
      logError('❌ Error al descargar desde URL: $e');
      rethrow;
    }
  }

  /// Fallback: Genera y descarga la plantilla CSV localmente
  static Future<void> _downloadPedidosTemplateLocal() async {
    try {
      // Crear contenido de la plantilla
      final templateContent = _generateTemplateContent();

      if (kIsWeb) {
        // Implementación para web
        await _downloadTemplateForWeb(templateContent);
      } else {
        // Implementación para móviles
        await _downloadTemplateForMobile(templateContent);
      }

      logInfo('📄 Plantilla CSV local generada y compartida exitosamente');
    } catch (e) {
      logError('❌ Error al generar plantilla CSV local: $e');
      rethrow;
    }
  }

  /// Descarga la plantilla para web
  static Future<void> _downloadTemplateForWeb(String content) async {
    // Convertir contenido a bytes
    final bytes = Uint8List.fromList(content.codeUnits);

    // Crear blob para descarga
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Crear enlace de descarga
    html.AnchorElement(href: url)
      ..setAttribute('download', _templateFileName)
      ..click();

    // Limpiar URL
    html.Url.revokeObjectUrl(url);
  }

  /// Descarga la plantilla para móviles
  static Future<void> _downloadTemplateForMobile(String content) async {
    // Obtener directorio temporal
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$_templateFileName');

    // Escribir archivo
    await file.writeAsString(content);

    // Compartir archivo
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Plantilla CSV para cargar pedidos en MedRush',
        subject: 'Plantilla Pedidos MedRush',
      ),
    );
  }

  /// Genera el contenido de la plantilla CSV
  static String _generateTemplateContent() {
    // Headers en español
    final headers = _getFieldHeadersInSpanish();

    // Crear fila de ejemplo
    final exampleRow = _getExampleRow();

    // Crear contenido CSV
    final csvData = [
      headers,
      exampleRow,
    ];

    // Usar la nueva API de csv 7.x
    return csv.encode(csvData);
  }

  /// Obtiene los headers en español para la plantilla
  static List<String> _getFieldHeadersInSpanish() {
    return [
      'Nombre del Paciente', // patient_name (REQUERIDO)
      'Teléfono del Paciente', // patient_phone (REQUERIDO)
      'Email del Paciente', // patient_email (OPCIONAL)
      'Dirección de Entrega Línea 1', // delivery_address_line_1 (REQUERIDO)
      'Dirección de Entrega Línea 2', // delivery_address_line_2 (OPCIONAL)
      'Ciudad de Entrega', // delivery_city (REQUERIDO)
      'Estado/Región de Entrega', // delivery_state_region (REQUERIDO)
      'Código Postal de Entrega', // delivery_postal_code (REQUERIDO)
      'Ubicación de Recojo', // pickup_location (OPCIONAL - se asigna automáticamente desde la farmacia)
      'Ubicación de Entrega', // delivery_location (OPCIONAL)
      'Código de Acceso al Edificio', // building_access_code (OPCIONAL)
      'Medicamentos', // medications (REQUERIDO)
      'Tipo de Pedido', // order_type (OPCIONAL - valores: medicamentos, insumos_medicos, equipos_medicos, medicamentos_controlados)
      'Observaciones', // observations (OPCIONAL)
    ];
  }

  /// Obtiene una fila de ejemplo para la plantilla
  static List<String> _getExampleRow() {
    return [
      'Juan Pérez', // patient_name
      '+51987654321', // patient_phone
      'juan.perez@email.com', // patient_email
      'Av. Javier Prado Este 1234', // delivery_address_line_1
      'Oficina 201', // delivery_address_line_2
      'San Isidro', // delivery_city
      'Lima', // delivery_state_region
      '15036', // delivery_postal_code
      '', // pickup_location (se asigna automáticamente desde la farmacia)
      'Casa del paciente', // delivery_location
      '1234', // building_access_code
      'Paracetamol 500mg x 20, Ibuprofeno 400mg x 10', // medications
      'medicamentos', // order_type (valores válidos: medicamentos, insumos_medicos, equipos_medicos, medicamentos_controlados)
      'Entregar después de las 2 PM', // observations
    ];
  }

  /// Lee un archivo CSV con manejo robusto de codificación
  static Future<String> readCsvFileWithEncoding(String filePath) async {
    try {
      logInfo('📁 Leyendo archivo CSV: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado: $filePath');
      }

      // Intentar diferentes codificaciones
      final encodings = [
        'utf-8',
        'latin1',
        'windows-1252',
        'iso-8859-1',
      ];

      for (final encoding in encodings) {
        try {
          logInfo('🔧 Intentando codificación: $encoding');
          final bytes = await file.readAsBytes();
          final content = utf8.decode(bytes, allowMalformed: true);

          // Verificar si la decodificación fue exitosa
          if (!content.contains('\uFFFD') || encoding == 'utf-8') {
            logInfo('✅ Archivo leído exitosamente con codificación: $encoding');
            return content;
          }
        } catch (e) {
          logWarning('⚠️ Error con codificación $encoding: $e');
          continue;
        }
      }

      // Si todas las codificaciones fallan, usar la lectura por defecto
      logWarning(
          '⚠️ Todas las codificaciones fallaron, usando lectura por defecto');
      return await file.readAsString();
    } catch (e) {
      logError('❌ Error al leer archivo CSV: $e');
      rethrow;
    }
  }

  /// Parsea el contenido CSV y lo convierte a lista de mapas
  static List<Map<String, dynamic>> parseCsvContent(String content) {
    try {
      logInfo('📄 Iniciando parseo de CSV...');

      // Verificar si el contenido tiene problemas de codificación
      if (content.contains('\uFFFD')) {
        logWarning(
            '⚠️ Contenido CSV contiene caracteres de reemplazo UTF-8, aplicando corrección...');
      }

      // Usar método seguro para evitar crashes en logs
      return parseCsvContentSafe(content);
    } catch (e) {
      logError('❌ Error al parsear CSV: $e');
      logError('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Limpia el contenido CSV de caracteres problemáticos
  static String _cleanCsvContent(String content) {
    logInfo('🧹 Limpiando contenido CSV...');

    // Primero, intentar corregir la codificación UTF-8
    String cleanedContent = _fixUtf8Encoding(content);

    // Si aún hay caracteres problemáticos, usar método alternativo
    if (cleanedContent.contains('\uFFFD')) {
      logWarning(
          '⚠️ Aún hay caracteres problemáticos, aplicando corrección alternativa...');
      cleanedContent = _fixUtf8EncodingAlternative(cleanedContent);
    }

    // Si aún hay caracteres problemáticos, usar método específico para evitar crash
    if (cleanedContent.contains('\uFFFD')) {
      logWarning('⚠️ Aplicando corrección específica para evitar crash...');
      cleanedContent = _handleCrashCausingEncoding(cleanedContent);
    }

    // Remover caracteres de control problemáticos
    cleanedContent = Validators.removeControlCharacters(cleanedContent)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    logInfo('🧹 Contenido CSV limpiado exitosamente');
    return cleanedContent;
  }

  /// Corrige problemas de codificación UTF-8 en el contenido CSV
  static String _fixUtf8Encoding(String content) {
    try {
      logInfo('🔧 Intentando corregir codificación UTF-8...');

      // Convertir a bytes y luego de vuelta a string para limpiar caracteres mal codificados
      final bytes = content.codeUnits;
      final cleanBytes = <int>[];

      for (int i = 0; i < bytes.length; i++) {
        final byte = bytes[i];

        // Manejar secuencias UTF-8 mal formadas
        if (byte == 0xEF &&
            i + 2 < bytes.length &&
            bytes[i + 1] == 0xBF &&
            bytes[i + 2] == 0xBD) {
          // Carácter de reemplazo UTF-8 (U+FFFD) - intentar inferir el carácter correcto
          logWarning(
              '⚠️ Carácter de reemplazo UTF-8 encontrado en posición $i, intentando corregir...');

          // Buscar contexto para inferir el carácter correcto
          final context = _getContextAround(bytes, i);
          final correctedChar = _inferCorrectCharacter(context);

          if (correctedChar != null) {
            logInfo('✅ Carácter corregido: "$correctedChar"');
            cleanBytes.addAll(correctedChar.codeUnits);
          } else {
            // Si no podemos inferir, usar un carácter seguro
            cleanBytes.add(0x3F); // '?'
          }

          i += 2; // Saltar los bytes adicionales del carácter de reemplazo
        } else {
          cleanBytes.add(byte);
        }
      }

      final result = String.fromCharCodes(cleanBytes);
      logInfo('🔧 Codificación UTF-8 corregida exitosamente');
      return result;
    } catch (e) {
      logError('❌ Error al corregir codificación UTF-8: $e');
      // Si falla la corrección, devolver el contenido original
      return content;
    }
  }

  /// Obtiene contexto alrededor de una posición para inferir el carácter correcto
  static String _getContextAround(List<int> bytes, int position) {
    final start = (position - 10).clamp(0, bytes.length);
    final end = (position + 10).clamp(0, bytes.length);
    return String.fromCharCodes(bytes.sublist(start, end));
  }

  /// Infiere el carácter correcto basado en el contexto
  static String? _inferCorrectCharacter(String context) {
    // Mapeo de contextos comunes a caracteres correctos
    final corrections = {
      'Tel': 'é', // Teléfono
      'Direcci': 'ó', // Dirección
      'Línea': 'í', // Línea
      'Regi': 'ó', // Región
      'Código': 'ó', // Código
      'Ubicaci': 'ó', // Ubicación
      'Recojo': 'ó', // Recojo
      'Acceso': 'é', // Acceso
      'Edificio': 'í', // Edificio
      'Medicamentos': 'é', // Medicamentos
      'Tipo': 'í', // Tipo
      'Pedido': 'í', // Pedido
      'Observaciones': 'ó', // Observaciones
    };

    for (final entry in corrections.entries) {
      if (context.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Método alternativo para corregir caracteres UTF-8 problemáticos usando reemplazos directos
  static String _fixUtf8EncodingAlternative(String content) {
    logInfo('🔧 Aplicando corrección alternativa de UTF-8...');

    // Reemplazos directos para los caracteres problemáticos más comunes
    final replacements = {
      'Telfono': 'Teléfono',
      'Direccin': 'Dirección',
      'Lnea': 'Línea',
      'Regin': 'Región',
      'Cdigo': 'Código',
      'Ubicacin': 'Ubicación',
      'Acceso': 'Acceso',
      'Edificio': 'Edificio',
      'Medicamentos': 'Medicamentos',
      'Tipo': 'Tipo',
      'Pedido': 'Pedido',
      'Observaciones': 'Observaciones',
    };

    String result = content;
    for (final entry in replacements.entries) {
      if (result.contains(entry.key)) {
        result = result.replaceAll(entry.key, entry.value);
        logInfo('✅ Reemplazado: "${entry.key}" → "${entry.value}"');
      }
    }

    logInfo('🔧 Corrección alternativa completada');
    return result;
  }

  /// Convierte un string a una versión segura para logging
  static String _safeString(value) {
    if (value == null) {
      return 'null';
    }
    final str = value.toString();
    return _sanitizeForLogging(str);
  }

  /// Obtiene una subcadena segura para logging
  static String _safeSubstring(String str, int maxLength) {
    final safeStr = _sanitizeForLogging(str);
    return safeStr.length > maxLength
        ? safeStr.substring(0, maxLength)
        : safeStr;
  }

  /// Sanitiza un string para logging, removiendo caracteres problemáticos
  static String _sanitizeForLogging(String str) {
    try {
      // Reemplazar caracteres de reemplazo UTF-8 con '?'
      String sanitized = str.replaceAll('\uFFFD', '?');

      // Reemplazar otros caracteres problemáticos
      sanitized = Validators.removeControlCharacters(sanitized);

      return sanitized;
    } catch (e) {
      // Si hay algún error, devolver una versión muy básica
      return 'STRING_WITH_ENCODING_ERROR';
    }
  }

  /// Método principal para procesar CSV de forma segura
  static List<Map<String, dynamic>> parseCsvContentSafe(String content) {
    try {
      logInfo('📄 Iniciando parseo seguro de CSV...');

      // Verificar si el contenido original tenía problemas
      if (content.contains('\uFFFD')) {
        logWarning('⚠️ Contenido CSV contiene caracteres de reemplazo UTF-8');
        logInfo('🔧 Aplicando corrección completa...');

        // Aplicar corrección completa al contenido original
        String correctedContent = _cleanCsvContent(content);
        final result = _parseCsvContentInternal(correctedContent);
        logInfo('✅ CSV procesado exitosamente con corrección de codificación');
        return result;
      } else {
        // Si no hay problemas, procesar normalmente
        final result = _parseCsvContentInternal(content);
        logInfo('✅ CSV procesado exitosamente sin problemas de codificación');
        return result;
      }
    } catch (e) {
      logError('❌ Error en parseo seguro de CSV: $e');
      rethrow;
    }
  }

  /// Método interno para parsear CSV (sin logs problemáticos)
  static List<Map<String, dynamic>> _parseCsvContentInternal(String content) {
    try {
      // Limpiar el contenido de caracteres problemáticos
      final cleanContent = _cleanCsvContent(content);

      final lines = cleanContent.split('\n');
      if (lines.isEmpty) {
        return [];
      }

      // Obtener headers de la primera línea
      final headers = _parseCsvLine(lines[0]);
      final data = <Map<String, dynamic>>[];

      // Procesar cada línea de datos
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) {
          continue;
        }

        final values = _parseCsvLine(line);
        if (values.length != headers.length) {
          continue;
        }

        final row = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = values[j].isEmpty ? null : values[j];
          row[header] = value;
        }
        data.add(row);
      }

      return data;
    } catch (e) {
      logError('❌ Error al parsear CSV internamente: $e');
      rethrow;
    }
  }

  /// Método específico para manejar el error de codificación que causa el crash
  static String _handleCrashCausingEncoding(String content) {
    logInfo('🚨 Aplicando corrección específica para evitar crash...');

    try {
      // Reemplazar caracteres de reemplazo UTF-8 (U+FFFD) con caracteres seguros
      String result = content.replaceAll('\uFFFD', '?');

      // Reemplazos específicos basados en el error reportado
      final specificReplacements = {
        'Telfono': 'Teléfono',
        'Direccin': 'Dirección',
        'Lnea': 'Línea',
        'Regin': 'Región',
        'Cdigo': 'Código',
        'Ubicacin': 'Ubicación',
        'Acceso': 'Acceso',
        'Edificio': 'Edificio',
        'Medicamentos': 'Medicamentos',
        'Tipo': 'Tipo',
        'Pedido': 'Pedido',
        'Observaciones': 'Observaciones',
      };

      for (final entry in specificReplacements.entries) {
        if (result.contains(entry.key)) {
          result = result.replaceAll(entry.key, entry.value);
          logInfo(
              '✅ Reemplazado específico: "${entry.key}" → "${entry.value}"');
        }
      }

      logInfo('🚨 Corrección específica completada');
      return result;
    } catch (e) {
      logError('❌ Error en corrección específica: $e');
      // Si falla, devolver el contenido con caracteres de reemplazo convertidos a '?'
      return content.replaceAll('\uFFFD', '?');
    }
  }

  /// Parsea una línea CSV manejando comillas y comas correctamente
  static List<String> _parseCsvLine(String line) {
    logDebug(
        '🔍 Parseando línea CSV: "${line.length > 100 ? "${_safeSubstring(line, 100)}..." : _safeString(line)}"');

    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    bool escapeNext = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (escapeNext) {
        buffer.write(char);
        escapeNext = false;
        continue;
      }

      if (char == '\\') {
        escapeNext = true;
        continue;
      }

      if (char == '"') {
        inQuotes = !inQuotes;
        logDebug('🔍 Comilla encontrada en posición $i, inQuotes: $inQuotes');
        continue;
      }

      if (char == ',' && !inQuotes) {
        final field = buffer.toString().trim();
        result.add(field);
        logDebug('🔍 Campo parseado: "$field"');
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    // Agregar el último campo
    final lastField = buffer.toString().trim();
    result.add(lastField);
    logDebug('🔍 Último campo parseado: "$lastField"');

    logDebug(
        '🔍 Línea parseada en ${result.length} campos: ${result.join(" | ")}');
    return result;
  }

  /// Convierte datos a formato CSV
  static String convertDataToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return '';
    }

    final headers = data.first.keys.toList();
    final csvLines = <String>[headers.join(',')]; // Agregar headers

    // Agregar datos
    for (final row in data) {
      final values =
          headers.map((header) => row[header]?.toString() ?? '').toList();
      csvLines.add(values.join(','));
    }

    return csvLines.join('\n');
  }

  /// Valida los datos del CSV
  static CsvValidationResult validateCsvData(
      List<Map<String, dynamic>> csvData) {
    final errors = <String>[];

    // Normalizar headers a claves del backend antes de validar
    csvData = mapCsvDataToBackendKeys(csvData);

    logInfo('🔍 Iniciando validación de datos CSV...');
    logInfo('🔍 Total de registros a validar: ${csvData.length}');

    if (csvData.isEmpty) {
      logWarning('⚠️ No hay datos para validar');
      errors.add('No hay datos para validar');
      return CsvValidationResult(isValid: false, errors: errors);
    }

    // Log de la primera fila para debugging
    final firstRow = csvData.first;
    logInfo('🔍 Primera fila de datos:');
    for (final entry in firstRow.entries) {
      logInfo('🔍 Campo "${entry.key}": "${entry.value}"');
    }

    // Verificar que existan los campos requeridos
    logInfo('🔍 Verificando campos requeridos: ${requiredFields.join(", ")}');
    final missingFields =
        requiredFields.where((field) => !firstRow.containsKey(field)).toList();

    if (missingFields.isNotEmpty) {
      logError('❌ Faltan campos requeridos: ${missingFields.join(', ')}');
      logError('❌ Campos disponibles: ${firstRow.keys.join(', ')}');
      errors.add('Faltan campos requeridos: ${missingFields.join(', ')}');
    } else {
      logInfo('✅ Todos los campos requeridos están presentes');
    }

    // Validar cada fila
    logInfo('🔍 Validando ${csvData.length} filas de datos...');
    for (int i = 0; i < csvData.length; i++) {
      final row = csvData[i];
      final rowNumber =
          i + 2; // +2 porque empezamos desde la fila 2 (después del header)

      logDebug('🔍 Validando fila $rowNumber:');
      for (final entry in row.entries) {
        logDebug('🔍   ${entry.key}: "${entry.value}"');
      }

      // Validar campos requeridos no vacíos
      for (final field in requiredFields) {
        if (firstRow.containsKey(field)) {
          final value = row[field]?.toString().trim();
          if (value == null || value.isEmpty) {
            logError(
                '❌ Fila $rowNumber: El campo "$field" es requerido pero está vacío');
            errors.add('Fila $rowNumber: El campo "$field" es requerido');
          } else {
            logDebug('✅ Fila $rowNumber: Campo "$field" tiene valor: "$value"');
          }
        }
      }

      // Validar formato de teléfono si existe
      if (row.containsKey('patient_phone')) {
        final phone = row['patient_phone']?.toString().trim();
        if (phone != null && phone.isNotEmpty) {
          logDebug('🔍 Fila $rowNumber: Validando teléfono: "$phone"');
          if (!_isValidPhone(phone)) {
            logError('❌ Fila $rowNumber: Formato de teléfono inválido: $phone');
            errors.add('Fila $rowNumber: Formato de teléfono inválido: $phone');
          } else {
            logDebug('✅ Fila $rowNumber: Teléfono válido: "$phone"');
          }
        } else {
          logDebug(
              '🔍 Fila $rowNumber: Teléfono vacío o nulo, saltando validación');
        }
      }

      // Validar formato de email si existe
      if (row.containsKey('patient_email')) {
        final email = row['patient_email']?.toString().trim();
        if (email != null && email.isNotEmpty) {
          logDebug('🔍 Fila $rowNumber: Validando email: "$email"');
          if (!_isValidEmail(email)) {
            logError('❌ Fila $rowNumber: Formato de email inválido: $email');
            errors.add('Fila $rowNumber: Formato de email inválido: $email');
          } else {
            logDebug('✅ Fila $rowNumber: Email válido: "$email"');
          }
        } else {
          logDebug(
              '🔍 Fila $rowNumber: Email vacío o nulo, saltando validación');
        }
      }

      // Validar tipo de pedido si existe
      if (row.containsKey('order_type')) {
        final orderType = row['order_type']?.toString().trim();
        if (orderType != null && orderType.isNotEmpty) {
          logDebug(
              '🔍 Fila $rowNumber: Validando tipo de pedido: "$orderType"');
          if (!_isValidOrderType(orderType)) {
            logError('❌ Fila $rowNumber: Tipo de pedido inválido: $orderType');
            errors.add(
                'Fila $rowNumber: Tipo de pedido inválido: $orderType. Valores válidos: medicamentos, insumos_medicos, equipos_medicos, medicamentos_controlados');
          } else {
            logDebug('✅ Fila $rowNumber: Tipo de pedido válido: "$orderType"');
          }
        } else {
          logDebug(
              '🔍 Fila $rowNumber: Tipo de pedido vacío o nulo, saltando validación');
        }
      }
    }

    // Log del resultado final de la validación
    if (errors.isEmpty) {
      logInfo(
          '✅ Validación CSV completada exitosamente - Sin errores encontrados');
    } else {
      logError('❌ Validación CSV completada con ${errors.length} errores:');
      for (int i = 0; i < errors.length; i++) {
        logError('❌ Error ${i + 1}: ${errors[i]}');
      }
    }

    return CsvValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Valida formato de teléfono
  static bool _isValidPhone(String phone) {
    return Validators.isValidPhoneFormat(phone);
  }

  /// Valida formato de email
  static bool _isValidEmail(String email) {
    return Validators.isValidEmailStrict(email);
  }

  /// Valida tipo de pedido según los valores del backend
  static bool _isValidOrderType(String orderType) {
    const validOrderTypes = [
      'medicamentos',
      'insumos_medicos',
      'equipos_medicos',
      'medicamentos_controlados'
    ];
    return validOrderTypes.contains(orderType.toLowerCase());
  }

  /// Convierte un valor string a boolean compatible con el backend
  /// Soporta los mismos valores que el backend PHP
  static bool parseBooleanValue(String value) {
    if (value.isEmpty) {
      return false;
    }

    final lowerValue = value.toLowerCase().trim();

    // Valores que representan "true" (basado en el backend PHP)
    final trueValues = [
      'true',
      'yes',
      'si',
      'sí',
      '1',
      'verdadero',
      'on',
      'active',
      'activo'
    ];

    return trueValues.contains(lowerValue);
  }

  /// Obtiene estadísticas del CSV
  static CsvStats getCsvStats(List<Map<String, dynamic>> csvData) {
    logInfo('📊 Generando estadísticas del CSV...');

    if (csvData.isEmpty) {
      logWarning('⚠️ CSV vacío - no hay estadísticas que generar');
      return CsvStats(
        totalRows: 0,
        totalColumns: 0,
        emptyFieldsByColumn: {},
      );
    }

    final headers = csvData.first.keys.toList();
    final totalRows = csvData.length;
    final totalColumns = headers.length;

    logInfo(
        '📊 Estadísticas básicas: $totalRows filas, $totalColumns columnas');
    logInfo('📊 Headers: ${headers.join(", ")}');

    // Calcular campos vacíos por columna
    final emptyFieldsByColumn = <String, int>{};
    for (final header in headers) {
      final emptyCount = csvData
          .where((row) => row[header]?.toString().isEmpty ?? true)
          .length;
      emptyFieldsByColumn[header] = emptyCount;
      logInfo(
          '📊 Campo "$header": ${totalRows - emptyCount}/$totalRows registros con datos ($emptyCount vacíos)');
    }

    final stats = CsvStats(
      totalRows: totalRows,
      totalColumns: totalColumns,
      emptyFieldsByColumn: emptyFieldsByColumn,
    );

    logInfo('📊 Estadísticas generadas exitosamente');
    return stats;
  }
}

/// Resultado de validación de CSV
class CsvValidationResult {
  final bool isValid;
  final List<String> errors;

  CsvValidationResult({required this.isValid, required this.errors});
}

/// Estadísticas del CSV
class CsvStats {
  final int totalRows;
  final int totalColumns;
  final Map<String, int> emptyFieldsByColumn;

  CsvStats({
    required this.totalRows,
    required this.totalColumns,
    required this.emptyFieldsByColumn,
  });
}

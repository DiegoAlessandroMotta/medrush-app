import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/models/pagination.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseApi {
  static Dio? _dio;
  static final _storage = const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: "medrush_secure_storage",
      publicKey: "medrush_public_key",
    ),
  );

  /// Obtiene la instancia de Dio configurada
  static Dio get client {
    _dio ??= _createDio();
    return _dio!;
  }

  /// Prueba la conexión al backend
  static Future<bool> testConnection() async {
    try {
      logInfo(
          '${ConsoleColor.blue}Probando conexión al backend: ${EndpointManager.currentBaseUrl}${ConsoleColor.reset}');

      // Usar endpoint de login para verificar conectividad (endpoint público)
      final response = await client.get(EndpointManager.login,
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            validateStatus: (status) {
              // Aceptar 405 (Method Not Allowed) como conexión exitosa
              // ya que el endpoint existe pero no acepta GET
              return status != null && (status == 200 || status == 405);
            },
          ));

      logInfo(
          '${ConsoleColor.green}Conexión exitosa: ${response.statusCode}${ConsoleColor.reset}');
      return true;
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error de conexión al backend${ConsoleColor.reset}',
          e);
      return false;
    }
  }

  /// Crea y configura la instancia de Dio
  static Dio _createDio() {
    final baseUrl = EndpointManager.currentBaseUrl;
    final serverDomain = EndpointManager.serverDomain;
    logInfo(
        '${ConsoleColor.cyan}Configurando Dio con baseUrl: $baseUrl${ConsoleColor.reset}');
    logInfo(
        '${ConsoleColor.cyan}Server Domain: $serverDomain${ConsoleColor.reset}');
    if (kDebugMode) {
      logInfo('${ConsoleColor.cyan}Debug Info: ${EndpointManager.debugInfo}${ConsoleColor.reset}');
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout:
          const Duration(milliseconds: EndpointManager.connectTimeout),
      receiveTimeout:
          const Duration(milliseconds: EndpointManager.receiveTimeout),
      sendTimeout: const Duration(milliseconds: EndpointManager.sendTimeout),
      headers: EndpointManager.defaultHeaders,
    ));

    // Interceptor para logging
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final methodColor = ConsoleColor.getHttpMethodColor(options.method);
        // Agregar timestamp para calcular tiempo de respuesta
        options.extra['requestStartTime'] =
            DateTime.now().millisecondsSinceEpoch;

        // Construir URL completa con parámetros de query
        final fullUrl = _buildFullUrl(options.path, options.queryParameters);
        logInfo(
            '$methodColor[${options.method}]${ConsoleColor.reset} $fullUrl');

        // Verificar si se está enviando el token (solo en desarrollo)
        final authHeader = options.headers['Authorization'];
        if (authHeader != null) {
          if (kDebugMode) {
            logInfo(
                '${ConsoleColor.blue}Token enviado: ${authHeader.toString().substring(0, 20)}...${ConsoleColor.reset}');
          }
        } else {
          logWarning(
              '${ConsoleColor.yellow}NO se está enviando token de autenticación${ConsoleColor.reset}');
        }

        if (options.data != null) {
          logDebug(
              'Request Data: ${_sanitizeLogData(options.data, httpMethod: options.method)}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final statusColor = _getStatusColorForLog(response.statusCode ?? 0);
        final methodColor =
            ConsoleColor.getHttpMethodColor(response.requestOptions.method);

        // Calcular tiempo de respuesta
        final requestStartTime =
            response.requestOptions.extra['requestStartTime'] as int?;
        final responseTime = requestStartTime != null
            ? DateTime.now().millisecondsSinceEpoch - requestStartTime
            : null;

        final timeInfo = responseTime != null
            ? ' ${ConsoleColor.formatResponseTime(responseTime)}'
            : '';

        // Construir URL completa para el log de respuesta
        final fullUrl = _buildFullUrl(response.requestOptions.path,
            response.requestOptions.queryParameters);

        logInfo(
            '$statusColor[${response.statusCode}]${ConsoleColor.reset} $methodColor[${response.requestOptions.method}]${ConsoleColor.reset} $fullUrl$timeInfo');
        logDebug(
            'Response Data: ${_sanitizeLogData(response.data, httpMethod: response.requestOptions.method)}');

        // Log de paginación si existe
        final data = response.data;
        if (data is Map && data['pagination'] is Map<String, dynamic>) {
          final paginationData = data['pagination'] as Map<String, dynamic>;
          logPagination(
              paginationData, response.requestOptions.queryParameters);
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        // Interceptor para manejar tokens expirados y errores de autorización
        if (error.response?.statusCode == 401) {
          // Solo limpiar si se envió Authorization previamente
          final hadAuth = error.requestOptions.headers['Authorization'] != null;
          if (hadAuth) {
            logWarning(
                '${ConsoleColor.red}Error 401 con Authorization presente - limpiando sesión${ConsoleColor.reset}');
            await _handleTokenExpired();
          } else {
            logWarning(
                '${ConsoleColor.yellow}401 sin Authorization - no se limpia sesión${ConsoleColor.reset}');
          }
        }
        final statusColor =
            _getStatusColorForLog(error.response?.statusCode ?? 0);
        final methodColor =
            ConsoleColor.getHttpMethodColor(error.requestOptions.method);

        // Construir URL completa para el log de error
        final fullUrl = _buildFullUrl(
            error.requestOptions.path, error.requestOptions.queryParameters);

        logError(
            '$statusColor[${error.response?.statusCode}]${ConsoleColor.reset} $methodColor[${error.requestOptions.method}]${ConsoleColor.reset} $fullUrl',
            error);
        handler.next(error);
      },
    ));

    return dio;
  }

  /// Maneja tokens expirados automáticamente
  static Future<void> _handleTokenExpired() async {
    logWarning(
        '${ConsoleColor.red}Token expirado, limpiando datos de autenticación${ConsoleColor.reset}');
    await clearAuthData();
  }

  /// Método base para ejecutar operaciones HTTP con logging mejorado
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    String? operationName,
    String method = 'HTTP',
    String origin = '',
  }) async {
    final String opName = operationName ?? 'Operación HTTP';

    try {
      logInfo('${ConsoleColor.blue}Ejecutando: $opName${ConsoleColor.reset}');
      final stopwatch = Stopwatch()..start();

      final result = await operation();

      stopwatch.stop();
      logInfo(
          '${ConsoleColor.green}$opName completada en ${stopwatch.elapsedMilliseconds}ms${ConsoleColor.reset}');

      return result;
    } catch (e) {
      final message = errorMessage ?? 'Error en operación HTTP';
      logError(
          '${ConsoleColor.red}$opName falló: $message${ConsoleColor.reset}', e);

      // Log detalles del error HTTP
      if (e is DioException) {
        int statusCode = e.response?.statusCode ?? 0;
        String? responseData = e.response?.data?.toString();
        logError(
            '${ConsoleColor.cyan}DioException - Código HTTP: $statusCode, Respuesta: $responseData${ConsoleColor.reset}');
      }

      throw Exception('$message: $e');
    }
  }

  /// Método para consultas GET
  static Future<Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await client.get<T>(
      endpoint,
      queryParameters: queryParameters,
      options: options,
    );
    return response;
  }

  /// Método para consultas POST
  static Future<Response<T>> post<T>(
    String endpoint, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return client.post<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Método para consultas PUT
  static Future<Response<T>> put<T>(
    String endpoint, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return client.put<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Método para consultas PATCH
  static Future<Response<T>> patch<T>(
    String endpoint, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return client.patch<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Método para consultas DELETE
  static Future<Response<T>> delete<T>(
    String endpoint, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return client.delete<T>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Método para subir archivos (compatible con web y móvil)
  static Future<Response<T>> uploadFile<T>(
    String endpoint, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    MultipartFile multipartFile;

    if (kIsWeb) {
      // Para web, necesitamos convertir el archivo de manera diferente
      // Como no tenemos acceso directo al archivo en web desde filePath,
      // necesitamos que se pase el archivo directamente
      throw UnsupportedError(
          'uploadFile con filePath no es compatible con web. '
          'Use uploadFileFromBytes para web.');
    } else {
      // Para móvil/desktop
      multipartFile = await MultipartFile.fromFile(filePath);
    }

    final formData = FormData.fromMap({
      fieldName: multipartFile,
      ...?extraData,
    });

    return client.post<T>(
      endpoint,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// Método para subir archivos desde bytes (compatible con web)
  static Future<Response<T>> uploadFileFromBytes<T>(
    String endpoint, {
    required List<int> fileBytes,
    required String fileName,
    required String fieldName,
    Map<String, dynamic>? extraData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) {
    final multipartFile = MultipartFile.fromBytes(
      fileBytes,
      filename: fileName,
    );

    final formData = FormData.fromMap({
      fieldName: multipartFile,
      ...?extraData,
    });

    return client.post<T>(
      endpoint,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// Método para envío multipart con datos y archivos
  static Future<Response<T>> postMultipart<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    List<Map<String, dynamic>>? files,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    final formDataMap = <String, dynamic>{};

    // Agregar datos regulares
    if (data != null) {
      formDataMap.addAll(data);
    }

    // Agregar archivos
    if (files != null) {
      for (final file in files) {
        final field = file['field'] as String;
        final path = file['path'] as String;
        formDataMap[field] = await MultipartFile.fromFile(path);
      }
    }

    final formData = FormData.fromMap(formDataMap);

    return client.post<T>(
      endpoint,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// Método para subir archivos desde memoria (bytes) - compatible con Web
  static Future<Response<T>> uploadBytes<T>(
    String endpoint, {
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename),
      ...?extraData,
    });

    return client.post<T>(
      endpoint,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// Método para subir múltiples archivos
  static Future<Response<T>> uploadMultipleFiles<T>(
    String endpoint, {
    required List<String> filePaths,
    String fieldName = 'files',
    Map<String, dynamic>? extraData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    final files = await Future.wait(
      filePaths.map(MultipartFile.fromFile),
    );

    final formData = FormData.fromMap({
      fieldName: files,
      ...?extraData,
    });

    return client.post<T>(
      endpoint,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// Método para descargar archivos
  static Future<Response> downloadFile(
    String endpoint, {
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) {
    return client.download(
      endpoint,
      savePath,
      queryParameters: queryParameters,
      options: options,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Extrae un mensaje de error legible desde una excepción DioException
  /// Prioriza mensajes específicos del servidor sobre mensajes genéricos
  static String extractErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      // Para errores 422 (Validación), extraer el mensaje específico del servidor
      if (statusCode == 422 && responseData != null) {
        try {
          // Intentar extraer mensaje del formato Laravel
          if (responseData is Map<String, dynamic>) {
            // Buscar en error.errors (formato Laravel validation)
            final errorData = responseData['error'];
            if (errorData is Map<String, dynamic>) {
              final errors = errorData['errors'] as Map<String, dynamic>?;
              if (errors != null && errors.isNotEmpty) {
                // Tomar el primer error del primer campo
                final firstFieldErrors = errors.values.first;
                if (firstFieldErrors is List && firstFieldErrors.isNotEmpty) {
                  return firstFieldErrors.first as String;
                }
              }
            }

            // Buscar en errors directamente (formato alternativo)
            final errors = responseData['errors'] as Map<String, dynamic>?;
            if (errors != null && errors.isNotEmpty) {
              final firstFieldErrors = errors.values.first;
              if (firstFieldErrors is List && firstFieldErrors.isNotEmpty) {
                return firstFieldErrors.first as String;
              }
            }

            // Buscar mensaje general
            final message = responseData['message'] as String?;
            if (message != null && message.isNotEmpty) {
              return message;
            }
          }
        } catch (_) {
          // Si falla el parseo, usar mensaje genérico
        }

        return 'Las credenciales proporcionadas son incorrectas.';
      }

      // Para otros códigos de error HTTP, intentar extraer mensaje del servidor primero
      String? serverMessage;
      if (responseData is Map<String, dynamic>) {
        serverMessage = responseData['message'] as String?;
      }

      // Usar mensaje del servidor si está disponible, sino usar mensajes genéricos
      switch (statusCode) {
        case 400:
          return serverMessage ?? 'Solicitud incorrecta';
        case 401:
          return serverMessage ??
              'Credenciales incorrectas. Verifica tu email y contraseña.';
        case 403:
          return serverMessage ?? 'No tienes permisos para acceder.';
        case 404:
          return serverMessage ?? 'Servicio no encontrado.';
        case 500:
          return serverMessage ??
              'Error interno del servidor. Intenta más tarde.';
        case 503:
          return serverMessage ?? 'Servicio temporalmente no disponible.';
        default:
          if (statusCode != null) {
            return serverMessage ?? 'Error del servidor (código $statusCode)';
          }
      }
    }

    // Para otros tipos de errores
    final errorString = error.toString();
    if (errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout')) {
      return 'Error de conexión. Verifica tu internet.';
    }

    return 'Error al procesar la solicitud. Intenta nuevamente.';
  }

  /// Método para manejar errores HTTP con logging detallado
  /// @deprecated Use extractErrorMessage() en su lugar para obtener mensajes más específicos
  static String handleError(Object error) {
    final errorMessage = extractErrorMessage(error);

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      logError(
          '${ConsoleColor.cyan}DioException - Código: $statusCode, Mensaje: $errorMessage${ConsoleColor.reset}');
      if (responseData != null) {
        logDebug(
            '${ConsoleColor.blue}Respuesta del servidor: ${_sanitizeLogData(responseData, httpMethod: 'ERROR')}${ConsoleColor.reset}');
      }
    } else if (error is Exception) {
      logError(
          '${ConsoleColor.yellow}Exception genérica: $errorMessage${ConsoleColor.reset}');
    } else {
      logError(
          '${ConsoleColor.red}Error desconocido: $errorMessage${ConsoleColor.reset}');
    }

    return errorMessage;
  }

  /// Sanitiza datos para logging (versión simplificada para apps privadas)
  static Map<String, dynamic> _sanitizeLogData(data, {String? httpMethod}) {
    if (data is! Map<String, dynamic>) {
      return {'data': data.toString()};
    }

    // Para apps privadas, mostrar todos los datos completos sin protección
    return data;
  }

  /// Obtiene estadísticas de rendimiento de la API
  static Future<Map<String, dynamic>> getPerformanceStats() {
    return execute(() async {
      logInfo(
          '${ConsoleColor.cyan}Obteniendo estadísticas de rendimiento${ConsoleColor.reset}');

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'base_url': EndpointManager.currentBaseUrl,
      };
    }, operationName: 'Estadísticas de rendimiento');
  }

  // ===== MÉTODOS DE AUTENTICACIÓN =====

  /// Obtiene el token almacenado
  static Future<String?> getToken() async {
    try {
      String? token;

      logInfo('🔐 Buscando token en FlutterSecureStorage...');
      // Intentar obtener desde FlutterSecureStorage primero
      token = await _storage.read(key: EndpointManager.tokenKey);
      logInfo(
          '🔐 Token desde FlutterSecureStorage: ${token != null ? "ENCONTRADO" : "NO ENCONTRADO"}');

      // Si no hay token y estamos en web, intentar con SharedPreferences como fallback
      if (token == null && kIsWeb) {
        logInfo(
            '🔐 Token no encontrado en FlutterSecureStorage, intentando SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(EndpointManager.tokenKey);
        logInfo(
            '🔐 Token desde SharedPreferences: ${token != null ? "ENCONTRADO" : "NO ENCONTRADO"}');
        if (token != null) {
          logInfo('🔐 Token restaurado desde SharedPreferences (fallback)');
          // Migrar a FlutterSecureStorage para futuras operaciones
          await _storage.write(key: EndpointManager.tokenKey, value: token);
        }
      }

      if (token != null) {
        logInfo(
            '🔐 Token restaurado desde storage: ${token.substring(0, 10)}...');
      } else {
        logInfo('🔐 No se encontró token en ningún storage');
      }
      return token;
    } catch (e) {
      logError('Error al obtener token desde storage', e);
      return null;
    }
  }

  /// Verifica si el usuario está autenticado
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Verifica si el token actual es válido haciendo una request de prueba
  static Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Hacer una request simple para verificar si el token es válido
      final response = await client.get('/auth/me');
      return response.statusCode == 200;
    } catch (e) {
      logWarning('Token no válido: $e');
      return false;
    }
  }

  /// Almacena el token de autenticación
  static Future<void> storeToken(String token) async {
    try {
      // Guardar en FlutterSecureStorage
      await _storage.write(key: EndpointManager.tokenKey, value: token);

      // En web, también guardar en SharedPreferences como backup
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(EndpointManager.tokenKey, token);
        logInfo(
            '🔐 Token guardado en FlutterSecureStorage y SharedPreferences (web)');
      } else {
        logInfo('🔐 Token guardado en FlutterSecureStorage');
      }

      setAuthToken(token);
      logInfo(
          '${ConsoleColor.green}Token almacenado y configurado${ConsoleColor.reset}');
    } catch (e) {
      logError('Error al almacenar token', e);
      rethrow;
    }
  }

  /// Elimina el token almacenado
  static Future<void> removeToken() async {
    try {
      // Eliminar de FlutterSecureStorage
      await _storage.delete(key: EndpointManager.tokenKey);

      // En web, también eliminar de SharedPreferences
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(EndpointManager.tokenKey);
        logInfo(
            '🔐 Token eliminado de FlutterSecureStorage y SharedPreferences (web)');
      } else {
        logInfo('🔐 Token eliminado de FlutterSecureStorage');
      }

      clearAuthToken();
      logInfo('${ConsoleColor.yellow}Token removido${ConsoleColor.reset}');
    } catch (e) {
      logError('Error al eliminar token', e);
      rethrow;
    }
  }

  /// Almacena datos del usuario
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    await _storage.write(
        key: EndpointManager.userKey, value: userData.toString());
    logInfo('👤 Datos de usuario almacenados');
  }

  /// Obtiene datos del usuario almacenados
  static Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: EndpointManager.userKey);
    if (data != null) {
      try {
        // Convertir string a Map (simplificado)
        return {'user_data': data};
      } catch (e) {
        logError(
            '${ConsoleColor.red}Error al parsear datos de usuario${ConsoleColor.reset}',
            e);
        return null;
      }
    }
    return null;
  }

  /// Almacena el último email utilizado para el login
  static Future<void> storeLastUsedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(EndpointManager.lastUsedEmailKey, email);
      logInfo('📧 Email recordado: $email');
    } catch (e) {
      logError('Error al guardar el último email', e);
    }
  }

  /// Obtiene el último email utilizado
  static Future<String?> getLastUsedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(EndpointManager.lastUsedEmailKey);
    } catch (e) {
      logError('Error al obtener el último email', e);
      return null;
    }
  }

  /// Limpia todos los datos de autenticación
  static Future<void> clearAuthData() async {
    await _storage.deleteAll();
    clearAuthToken();
    logInfo('🧹 Todos los datos de autenticación limpiados');
  }

  /// Configura el token de autenticación para todas las requests
  static void setAuthToken(String token) {
    client.options.headers['Authorization'] = 'Bearer $token';
    logInfo(
        '${ConsoleColor.green}Token de autenticación configurado${ConsoleColor.reset}');
  }

  /// Remueve el token de autenticación
  static void clearAuthToken() {
    client.options.headers.remove('Authorization');
    logInfo(
        '${ConsoleColor.yellow}Token de autenticación removido${ConsoleColor.reset}');
  }

  // ===== MÉTODOS DE ALMACENAMIENTO DE IMÁGENES =====

  /// Determina el nombre del campo según el endpoint
  static String _getFieldNameForEndpoint(String endpoint) {
    if (endpoint.contains('/user/') && endpoint.contains('/foto')) {
      return 'avatar';
    } else if (endpoint.contains('/licencia')) {
      return 'foto_licencia';
    } else if (endpoint.contains('/seguro-vehiculo')) {
      return 'foto_seguro_vehiculo';
    } else if (endpoint.contains('/entregar')) {
      return 'foto_entrega';
    } else {
      return 'file'; // Campo por defecto
    }
  }

  /// Selecciona una imagen desde la galería o cámara
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 800,
    int maxHeight = 800,
    int imageQuality = 80,
  }) async {
    try {
      logInfo('📸 Seleccionando imagen desde ${source.name}');

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        logInfo(
            '${ConsoleColor.green}Imagen seleccionada: ${image.name}${ConsoleColor.reset}');
        return image;
      } else {
        logInfo(
            '${ConsoleColor.red}No se seleccionó ninguna imagen${ConsoleColor.reset}');
        return null;
      }
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al seleccionar imagen${ConsoleColor.reset}',
          e);
      rethrow;
    }
  }

  /// Sube una imagen al backend Laravel (compatible con web y móvil)
  static Future<String?> uploadImage({
    required XFile imageFile,
    required String userId,
    String? customPath,
    String? endpoint,
  }) async {
    // Construir endpoint correcto si no se proporciona
    final String finalEndpoint = endpoint ?? EndpointManager.userFoto(userId);

    try {
      logInfo('Subiendo imagen para usuario: $userId');
      logInfo('Endpoint: $finalEndpoint');
      logInfo('Archivo: ${imageFile.name}');

      // Generar nombre único para el archivo
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      // Determinar el nombre del campo según el endpoint
      final String fieldName = _getFieldNameForEndpoint(finalEndpoint);
      logInfo('Campo del archivo: $fieldName');

      Response<Map<String, dynamic>> response;

      if (kIsWeb) {
        // Para web, leer el archivo como bytes
        final List<int> fileBytes = await imageFile.readAsBytes();
        logInfo('Tamaño del archivo: ${fileBytes.length} bytes');

        response = await uploadFileFromBytes<Map<String, dynamic>>(
          finalEndpoint,
          fileBytes: fileBytes,
          fileName: fileName,
          fieldName: fieldName,
          extraData: {}, // Simplificar - solo enviar el archivo
        );
      } else {
        // Para móvil/desktop, usar el método tradicional
        response = await uploadFile<Map<String, dynamic>>(
          finalEndpoint,
          filePath: imageFile.path,
          fieldName: fieldName,
          extraData: {}, // Simplificar - solo enviar el archivo
        );
      }

      logInfo('Respuesta del servidor: ${response.statusCode}');
      logInfo('Datos de respuesta: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        logInfo(
            '${ConsoleColor.blue}Respuesta del backend: ${response.data}${ConsoleColor.reset}');

        final data = response.data;
        if (data != null && data['data'] != null) {
          final url = data['data']['url'] as String?;
          if (url != null) {
            logInfo(
                '${ConsoleColor.green}Imagen subida exitosamente: $url${ConsoleColor.reset}');
            return url;
          } else {
            logError(
                '${ConsoleColor.red}Error: URL no encontrada en data.url${ConsoleColor.reset}');
            return null;
          }
        } else {
          logError(
              '${ConsoleColor.red}Error: data no encontrada en la respuesta${ConsoleColor.reset}');
          return null;
        }
      } else {
        logError(
            '${ConsoleColor.red}Error: código de estado ${response.statusCode}${ConsoleColor.reset}');
        return null;
      }
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al subir imagen${ConsoleColor.reset}', e);
      rethrow;
    }
  }

  /// Sube una imagen de avatar
  static Future<String?> uploadAvatar({
    required XFile imageFile,
    required String userId,
  }) {
    return uploadImage(
      imageFile: imageFile,
      userId: userId,
    );
  }

  /// Sube o elimina foto de perfil del usuario
  static Future<RepositoryResult<String?>> uploadProfilePicture(
    String userId,
    File? imageFile,
  ) async {
    try {
      logInfo('📸 Subiendo foto de perfil para usuario: $userId');

      final endpoint = '/user/$userId/foto';
      Response<Map<String, dynamic>> response;

      if (imageFile == null) {
        // Eliminar foto - enviar request sin archivo
        logInfo('Eliminando foto de perfil');
        response = await post<Map<String, dynamic>>(
          endpoint,
          data: {}, // Sin archivo = eliminar
        );
      } else {
        // Subir nueva foto
        logInfo('Subiendo nueva foto de perfil');

        if (kIsWeb) {
          // Para web, leer el archivo como bytes
          final List<int> fileBytes = await imageFile.readAsBytes();
          final String fileName =
              'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

          response = await uploadFileFromBytes<Map<String, dynamic>>(
            endpoint,
            fileBytes: fileBytes,
            fileName: fileName,
            fieldName: 'avatar',
          );
        } else {
          // Para móvil/desktop
          final multipartFile = await MultipartFile.fromFile(imageFile.path);
          final formData = FormData.fromMap({
            'avatar': multipartFile,
          });

          response = await post<Map<String, dynamic>>(
            endpoint,
            data: formData,
          );
        }
      }

      logInfo('📸 Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['status'] == 'success') {
          final url = data['data']?['url'] as String?;
          logInfo('Foto de perfil procesada exitosamente');
          return RepositoryResult.success(url);
        } else {
          final error = data?['message'] ?? 'Error desconocido del servidor';
          logError('Error del servidor: $error');
          return RepositoryResult.error(error);
        }
      } else {
        final error = 'Error HTTP ${response.statusCode}';
        logError(error);
        return RepositoryResult.error(error);
      }
    } catch (e) {
      logError('Error al subir foto de perfil', e);
      return RepositoryResult.error('Error al procesar la foto: $e');
    }
  }

  /// Sube una imagen de firma digital (se envía como texto SVG en el endpoint de entrega)
  static Future<String?> uploadSignature({
    required XFile imageFile,
    required String userId,
    int? pedidoId,
  }) {
    // Las firmas se envían como texto SVG, no como archivo
    logWarning(
        '⚠️ uploadSignature: Las firmas se envían como texto SVG, no como archivo');
    return Future.value();
  }

  /// Sube una foto de evidencia (para entregas de pedidos)
  static Future<String?> uploadPhoto({
    required XFile imageFile,
    required String userId,
    String? context,
  }) {
    // Las fotos de evidencia se suben a través del endpoint de entrega
    logWarning(
        '⚠️ uploadPhoto: Usar el endpoint de entrega de pedidos para fotos de evidencia');
    return Future.value();
  }

  /// Sube una imagen de licencia de repartidor
  static Future<String?> uploadLicense({
    required XFile imageFile,
    required String repartidorId,
  }) {
    return uploadImage(
      imageFile: imageFile,
      userId: repartidorId,
      endpoint: '/user/repartidores/$repartidorId/licencia',
    );
  }

  /// Elimina una imagen del backend (solo para foto de perfil)
  static Future<bool> deleteImage(String imageUrl,
      {String endpoint = '/user/foto'}) async {
    try {
      logInfo(
          '${ConsoleColor.yellow}Eliminando imagen: $imageUrl${ConsoleColor.reset}');

      // Para foto de perfil, enviar request sin archivo para eliminar
      final response = await post<Map<String, dynamic>>(
        endpoint,
        data: {}, // Sin archivo = eliminar
      );

      if (response.statusCode == 200) {
        logInfo(
            '${ConsoleColor.green}Imagen eliminada exitosamente${ConsoleColor.reset}');
        return true;
      } else {
        logError(
            '${ConsoleColor.red}Error al eliminar imagen: código ${response.statusCode}${ConsoleColor.reset}');
        return false;
      }
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al eliminar imagen${ConsoleColor.reset}',
          e);
      return false;
    }
  }

  /// Valida si una URL es una imagen válida
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    final lowerUrl = url.toLowerCase();

    return validExtensions.any(lowerUrl.contains);
  }

  /// URLs HTTP del mismo host que la API se convierten a HTTPS para que carguen
  /// (mixed content en HTTPS, o API solo accesible por HTTPS en producción).
  static String? imageUrlForDisplay(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    if (!url.startsWith('http://')) {
      return url;
    }
    try {
      final uri = Uri.parse(url);
      final apiHost = EndpointManager.serverDomain;
      final isApiUrl = uri.host == apiHost || apiHost.contains(uri.host);
      if (kIsWeb && (Uri.base.scheme == 'https' || isApiUrl)) {
        return url.replaceFirst('http://', 'https://');
      }
    } catch (_) {}
    return url;
  }

  /// Obtiene la URL de una imagen con fallback (usa HTTPS en web cuando la app es HTTPS)
  static String getImageUrl(String? imageUrl, {String fallback = ''}) {
    if (!isValidImageUrl(imageUrl)) {
      return fallback;
    }
    final normalized = imageUrlForDisplay(imageUrl);
    return normalized ?? imageUrl!;
  }

  /// Genera una URL permanente para una imagen usando el nombre del archivo
  static String getPermanentImageUrl(String? signedUrl) {
    if (signedUrl == null || signedUrl.isEmpty) {
      return '';
    }

    // Si ya es una URL completa, extraer el nombre del archivo
    if (signedUrl.startsWith('http://') || signedUrl.startsWith('https://')) {
      // Extraer el nombre del archivo de la URL firmada
      // Ej: http://138.68.38.65/uploads/img/pfp-uuid.webp?expires=...&signature=...
      // -> pfp-uuid.webp
      final uri = Uri.parse(signedUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        // Generar URL permanente sin parámetros de expiración
        return '${EndpointManager.currentBaseUrl.replaceAll('/api', '')}/uploads/img/$fileName';
      }
    }

    return signedUrl;
  }

  /// Obtiene una URL de imagen válida, manejando URLs firmadas y permanentes
  static String getValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // Si es una URL firmada, usar directamente (el backend maneja la expiración)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Si es solo un nombre de archivo, construir la URL completa
    if (!imageUrl.contains('/')) {
      return '${EndpointManager.currentBaseUrl.replaceAll('/api', '')}/uploads/img/$imageUrl';
    }

    return imageUrl;
  }

  /// Verifica si una URL firmada está próxima a expirar (menos de 5 minutos)
  static bool isUrlNearExpiry(String? signedUrl) {
    if (signedUrl == null || signedUrl.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse(signedUrl);
      final expiresParam = uri.queryParameters['expires'];
      if (expiresParam != null) {
        final expiresTimestamp = int.tryParse(expiresParam);
        if (expiresTimestamp != null) {
          final expiresTime =
              DateTime.fromMillisecondsSinceEpoch(expiresTimestamp * 1000);
          final now = DateTime.now();
          final timeUntilExpiry = expiresTime.difference(now);
          return timeUntilExpiry.inMinutes <
              5; // Renovar si quedan menos de 5 minutos
        }
      }
    } catch (e) {
      logWarning('Error al verificar expiración de URL: $e');
    }

    return false;
  }

  /// Genera una URL con timestamp para forzar recarga en Web
  static String addCacheBuster(String url) {
    if (url.isEmpty) {
      return url;
    }

    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Valida si una URL es accesible (para diagnóstico)
  static Future<bool> isUrlAccessible(String url) async {
    try {
      final response = await client.head(url);
      return response.statusCode == 200;
    } catch (e) {
      logWarning('URL no accesible: $url - $e');
      return false;
    }
  }

  /// Valida si una URL firmada está correctamente formada
  static bool isValidSignedUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse(url);

      // Verificar que tenga los parámetros requeridos
      final hasExpires = uri.queryParameters.containsKey('expires');
      final hasSignature = uri.queryParameters.containsKey('signature');

      if (!hasExpires || !hasSignature) {
        logWarning('URL firmada incompleta - faltan parámetros: $url');
        return false;
      }

      // Verificar que la signature tenga la longitud correcta (64 caracteres hex)
      final signature = uri.queryParameters['signature'] ?? '';
      if (signature.length != 64) {
        logError(
            '❌ Signature truncada: $signature (${signature.length} caracteres, esperado 64)');
        return false;
      }

      // Verificar que expires sea un número válido
      final expires = uri.queryParameters['expires'] ?? '';
      final expiresTimestamp = int.tryParse(expires);
      if (expiresTimestamp == null) {
        logError('Timestamp de expiración inválido: $expires');
        return false;
      }

      // Verificar que no esté expirada
      final expiresTime =
          DateTime.fromMillisecondsSinceEpoch(expiresTimestamp * 1000);
      final now = DateTime.now();
      if (expiresTime.isBefore(now)) {
        logWarning('URL firmada expirada: $url');
        return false;
      }

      return true;
    } catch (e) {
      logError('Error al validar URL firmada: $e');
      return false;
    }
  }

  // ===== MÉTODOS DE VALIDACIÓN =====
  /// Valida si una respuesta HTTP es exitosa
  static bool isSuccessfulResponse(Response response) {
    return response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;
  }

  /// Valida si una respuesta indica error del cliente (4xx)
  static bool isClientError(Response response) {
    return response.statusCode != null &&
        response.statusCode! >= 400 &&
        response.statusCode! < 500;
  }

  /// Valida si una respuesta indica error del servidor (5xx)
  static bool isServerError(Response response) {
    return response.statusCode != null &&
        response.statusCode! >= 500 &&
        response.statusCode! < 600;
  }

  // ===== MÉTODOS DE UTILIDAD =====

  /// Construye parámetros de consulta para paginación
  static Map<String, dynamic> buildPaginationParams({
    int page = 1,
    int limit = 20,
    String? orderBy,
    String? orderDirection,
  }) {
    final params = <String, dynamic>{
      'current_page': page,
      'per_page': limit,
    };

    if (orderBy != null) {
      params['order_by'] = orderBy;
    }
    if (orderDirection != null) {
      params['order_direction'] = orderDirection;
    }

    return params;
  }

  /// Método genérico para obtener datos paginados del backend
  static Future<PaginatedResponse<T>> getPaginated<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    int page = 1,
    int perPage = 20,
    Map<String, dynamic>? filters,
    String?
        orderBy, // FIX: Removido valor por defecto - el backend maneja el ordenamiento
    String?
        orderDirection, // FIX: Removido valor por defecto - el backend maneja el ordenamiento
    Options? options,
  }) async {
    try {
      // Construir parámetros de paginación
      final paginationParams = buildPaginationParams(
        page: page,
        limit: perPage,
        orderBy: orderBy,
        orderDirection: orderDirection,
      );

      // Combinar con filtros adicionales
      final queryParams = <String, dynamic>{
        ...paginationParams,
        ...?filters,
      };

      logInfo(
          '${ConsoleColor.blue}Obteniendo datos paginados: $endpoint (página $page, $perPage por página)${ConsoleColor.reset}');

      final response = await get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParams,
        options: options,
      );

      if (response.data == null) {
        throw Exception('Respuesta vacía del servidor');
      }

      final data = response.data!;

      // Verificar estructura de respuesta del backend Laravel
      if (data['status'] != 'success') {
        throw Exception(
            'Error en respuesta del servidor: ${data['message'] ?? 'Desconocido'}');
      }

      // Extraer datos y metadatos de paginación
      final List<dynamic> itemsData = data['data'] ?? [];
      final Map<String, dynamic>? paginationData = data['pagination'];

      // Convertir items usando la función fromJson
      final List<T> items = itemsData
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      // Crear objeto de paginación
      final pagination = PaginationInfo.fromJson(paginationData ?? {});

      return PaginatedResponse<T>(
        items: items,
        pagination: pagination,
      );
    } catch (e) {
      logError(
          '${ConsoleColor.red}Error al obtener datos paginados de $endpoint${ConsoleColor.reset}',
          e);
      rethrow;
    }
  }

  /// Obtiene estadísticas detalladas de la API
  static Future<Map<String, dynamic>> getDetailedStats() {
    return execute(() async {
      logInfo(
          '${ConsoleColor.cyan}Obteniendo estadísticas detalladas${ConsoleColor.reset}');

      final token = await getToken();
      final authStatus = await isLoggedIn();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'base_url': EndpointManager.currentBaseUrl,
        'auth_status': authStatus ? 'authenticated' : 'unauthenticated',
        'has_token': token != null,
        'token_length': token?.length ?? 0,
        'headers_count': client.options.headers.length,
      };
    }, operationName: 'Estadísticas detalladas');
  }

  // ===== MÉTODOS AUXILIARES PARA COLORES =====

  /// Obtiene el color para el código de estado HTTP
  static String _getStatusColorForLog(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return ConsoleColor.green; // 2xx - Éxito
    } else if (statusCode >= 300 && statusCode < 400) {
      return ConsoleColor.blue; // 3xx - Redirección
    } else if (statusCode >= 400 && statusCode < 500) {
      return ConsoleColor.yellow; // 4xx - Error del cliente
    } else if (statusCode >= 500) {
      return ConsoleColor.red; // 5xx - Error del servidor
    } else {
      return ConsoleColor.reset; // Otros
    }
  }

  /// Construye la URL completa con parámetros de query para logging
  static String _buildFullUrl(
      String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return path;
    }

    final queryString = queryParameters.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    return '$path?$queryString';
  }
}

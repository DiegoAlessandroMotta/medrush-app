import 'package:medrush/api/base.api.dart';
import 'package:medrush/utils/loggers.dart';

/// Helper centralizado para operaciones comunes de API
class ApiHelper {
  /// Procesa respuestas estándar del backend Laravel
  static List<T> processListResponse<T>(
    Map<String, dynamic>? responseData,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = (responseData?['data'] as List?) ?? const [];
    return data.map((json) => fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Procesa respuesta de un solo item del backend Laravel
  static T? processSingleResponse<T>(
    Map<String, dynamic>? responseData,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = responseData?['data'] as Map<String, dynamic>?;
    return data != null ? fromJson(data) : null;
  }

  /// Ejecuta operación con logging optimizado
  static Future<T> executeWithLogging<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool enableLogging = true,
  }) async {
    try {
      if (enableLogging && operationName != null) {
        logInfo('Iniciando: $operationName');
      }

      final result = await operation();

      if (enableLogging && operationName != null) {
        logInfo('Completado: $operationName');
      }

      return result;
    } catch (e) {
      if (enableLogging && operationName != null) {
        logError('Error en: $operationName', e);
      }
      rethrow;
    }
  }

  /// Ejecuta operación GET con procesamiento estándar
  static Future<List<T>> getList<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: queryParameters,
        );
        return processListResponse(response.data, fromJson);
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación GET para un solo item
  static Future<T?> getSingle<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: queryParameters,
        );
        return processSingleResponse(response.data, fromJson);
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación POST con procesamiento estándar
  static Future<T> postSingle<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.post<Map<String, dynamic>>(
          endpoint,
          data: data,
        );
        return processSingleResponse(response.data, fromJson)!;
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación PATCH con procesamiento estándar
  static Future<T> patchSingle<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.patch<Map<String, dynamic>>(
          endpoint,
          data: data,
        );
        return processSingleResponse(response.data, fromJson)!;
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación DELETE
  static Future<bool> deleteItem(
    String endpoint, {
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        await BaseApi.delete(endpoint);
        return true;
      },
      operationName: operationName,
    );
  }

  /// Valida respuesta del backend
  static bool isValidResponse(Map<String, dynamic>? responseData) {
    return responseData?['status'] == 'success';
  }

  /// Extrae mensaje de error del backend
  static String getErrorMessage(Map<String, dynamic>? responseData) {
    return responseData?['message'] ?? 'Error desconocido';
  }

  /// Procesa respuesta estándar del backend Laravel con validación de status
  static T processStandardResponse<T>(
    Map<String, dynamic>? responseData,
    T Function(Map<String, dynamic>) fromJson, {
    String? dataKey,
  }) {
    if (!isValidResponse(responseData)) {
      throw Exception(getErrorMessage(responseData));
    }

    final data = dataKey != null
        ? responseData?['data']?[dataKey] as Map<String, dynamic>?
        : responseData?['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Datos no encontrados en la respuesta');
    }

    return fromJson(data);
  }

  /// Procesa lista de respuesta estándar del backend Laravel con validación de status
  static List<T> processStandardListResponse<T>(
    Map<String, dynamic>? responseData,
    T Function(Map<String, dynamic>) fromJson, {
    String? dataKey,
  }) {
    if (!isValidResponse(responseData)) {
      throw Exception(getErrorMessage(responseData));
    }

    final data = dataKey != null
        ? responseData?['data']?[dataKey] as List?
        : responseData?['data'] as List?;

    if (data == null) {
      return [];
    }

    return data.map((json) => fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Ejecuta operación GET con procesamiento estándar y manejo de errores
  static Future<List<T>> getListWithStandardProcessing<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
    String? dataKey,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: queryParameters,
        );
        return processStandardListResponse(
          response.data,
          fromJson,
          dataKey: dataKey,
        );
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación GET para un solo item con procesamiento estándar
  static Future<T?> getSingleWithStandardProcessing<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
    String? dataKey,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: queryParameters,
        );

        if (!isValidResponse(response.data)) {
          return null;
        }

        final data = dataKey != null
            ? response.data?['data']?[dataKey] as Map<String, dynamic>?
            : response.data?['data'] as Map<String, dynamic>?;

        return data != null ? fromJson(data) : null;
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación POST con procesamiento estándar y manejo de errores
  static Future<T?> postSingleWithStandardProcessing<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? dataKey,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.post<Map<String, dynamic>>(
          endpoint,
          data: data,
        );

        if (!isValidResponse(response.data)) {
          throw Exception(getErrorMessage(response.data));
        }

        final responseData = dataKey != null
            ? response.data?['data']?[dataKey] as Map<String, dynamic>?
            : response.data?['data'] as Map<String, dynamic>?;

        return responseData != null ? fromJson(responseData) : null;
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación PATCH con procesamiento estándar y manejo de errores
  static Future<T?> patchSingleWithStandardProcessing<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? dataKey,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.patch<Map<String, dynamic>>(
          endpoint,
          data: data,
        );

        if (!isValidResponse(response.data)) {
          throw Exception(getErrorMessage(response.data));
        }

        final responseData = dataKey != null
            ? response.data?['data']?[dataKey] as Map<String, dynamic>?
            : response.data?['data'] as Map<String, dynamic>?;

        return responseData != null ? fromJson(responseData) : null;
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación PUT con procesamiento estándar y manejo de errores
  static Future<T?> putSingleWithStandardProcessing<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    String? dataKey,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.put<Map<String, dynamic>>(
          endpoint,
          data: data,
        );

        if (!isValidResponse(response.data)) {
          throw Exception(getErrorMessage(response.data));
        }

        final responseData = dataKey != null
            ? response.data?['data']?[dataKey] as Map<String, dynamic>?
            : response.data?['data'] as Map<String, dynamic>?;

        return responseData != null ? fromJson(responseData) : null;
      },
      operationName: operationName,
    );
  }

  /// Ejecuta operación DELETE con manejo de errores estándar
  static Future<bool> deleteItemWithStandardProcessing(
    String endpoint, {
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.delete<Map<String, dynamic>>(endpoint);

        // Para DELETE, el backend puede devolver 204 (No Content) o 200 con status success
        if (response.statusCode == 204 ||
            (response.data != null && isValidResponse(response.data))) {
          return true;
        }

        throw Exception(getErrorMessage(response.data));
      },
      operationName: operationName,
    );
  }

  /// Obtiene datos de respuesta sin procesar (para casos especiales)
  static Future<Map<String, dynamic>> getRawData(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? operationName,
  }) {
    return executeWithLogging(
      () async {
        final response = await BaseApi.get<Map<String, dynamic>>(
          endpoint,
          queryParameters: queryParameters,
        );
        return response.data ?? <String, dynamic>{};
      },
      operationName: operationName,
    );
  }
}

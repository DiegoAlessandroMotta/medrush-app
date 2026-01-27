import 'package:flutter/foundation.dart';
import 'package:medrush/utils/validators.dart';

/// Resultado de una operación del repositorio
class RepositoryResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final RepositoryErrorType? errorType;

  const RepositoryResult._({
    required this.success,
    this.data,
    this.error,
    this.errorType,
  });

  /// Constructor para resultado exitoso
  factory RepositoryResult.success(T data) {
    return RepositoryResult._(
      success: true,
      data: data,
    );
  }

  /// Constructor para resultado con error
  factory RepositoryResult.error(
    String error, {
    RepositoryErrorType? type,
  }) {
    return RepositoryResult._(
      success: false,
      error: error,
      errorType: type ?? RepositoryErrorType.unknown,
    );
  }

  /// Constructor para error de conexión
  factory RepositoryResult.connectionError([String? message]) {
    return RepositoryResult._(
      success: false,
      error: message ?? 'Error de conexión',
      errorType: RepositoryErrorType.connection,
    );
  }

  /// Constructor para error de autenticación
  factory RepositoryResult.authError([String? message]) {
    return RepositoryResult._(
      success: false,
      error: message ?? 'Error de autenticación',
      errorType: RepositoryErrorType.authentication,
    );
  }

  /// Constructor para error de validación
  factory RepositoryResult.validationError(String message) {
    return RepositoryResult._(
      success: false,
      error: message,
      errorType: RepositoryErrorType.validation,
    );
  }

  /// Constructor para recurso no encontrado
  factory RepositoryResult.notFound([String? message]) {
    return RepositoryResult._(
      success: false,
      error: message ?? 'Recurso no encontrado',
      errorType: RepositoryErrorType.notFound,
    );
  }
}

/// Tipos de errores del repositorio
enum RepositoryErrorType {
  connection,
  authentication,
  validation,
  notFound,
  serverError,
  unknown,
}

/// Clase base abstracta para todos los repositorios
abstract class BaseRepository {
  /// Maneja la ejecución de operaciones del repositorio con captura de errores
  @protected
  Future<RepositoryResult<T>> execute<T>(
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      final result = await operation();
      return RepositoryResult.success(result);
    } catch (e) {
      debugPrint('Repository Error: $e');

      // Determinar el tipo de error basado en la excepción
      if (e.toString().contains('connection') ||
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        return RepositoryResult.connectionError(
            errorMessage ?? 'Error de conexión');
      }

      if (e.toString().contains('auth') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('403') ||
          e.toString().contains('401')) {
        return RepositoryResult.authError(
            errorMessage ?? 'Error de autenticación');
      }

      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return RepositoryResult.notFound(
            errorMessage ?? 'Recurso no encontrado');
      }

      return RepositoryResult.error(
        errorMessage ?? e.toString(),
        type: RepositoryErrorType.unknown,
      );
    }
  }

  /// Valida que un objeto no sea nulo
  @protected
  bool validateNotNull(Object? value, String fieldName) {
    if (value == null) {
      throw ArgumentError('$fieldName no puede ser nulo');
    }
    return true;
  }

  /// Valida que una cadena no esté vacía
  @protected
  bool validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw ArgumentError('$fieldName no puede estar vacío');
    }
    return true;
  }

  /// Valida un email
  @protected
  bool validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      throw ArgumentError('Email no puede estar vacío');
    }

    if (!Validators.isValidEmailStrict(email)) {
      throw ArgumentError('Email no tiene un formato válido');
    }

    return true;
  }

  /// Valida un ID
  @protected
  bool validateId(id, String fieldName) {
    if (id == null) {
      throw ArgumentError('$fieldName no puede ser nulo');
    }

    if (id is String && id.trim().isEmpty) {
      throw ArgumentError('$fieldName no puede estar vacío');
    }

    if (id is int && id <= 0) {
      throw ArgumentError('$fieldName debe ser mayor a 0');
    }

    return true;
  }
}


/// Interface para repositorios paginables
abstract class PaginatedRepository<T> extends BaseRepository {
  /// Resultado paginado
  static const int defaultPageSize = 20;

  /// Obtiene elementos paginados
  Future<RepositoryResult<PaginatedResult<T>>> getPaginated({
    int page = 1,
    int pageSize = defaultPageSize,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool ascending = true,
  });
}

/// Resultado paginado
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  bool get hasNextPage => currentPage * pageSize < totalCount;
  bool get hasPrevPage => currentPage > 1;
  int get totalPages => (totalCount / pageSize).ceil();
}

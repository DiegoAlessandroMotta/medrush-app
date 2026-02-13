import 'package:medrush/l10n/app_localizations.dart';

/// Modelo para información de paginación del backend Laravel
class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;
  final String? firstPageUrl;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String path;
  final List<Map<String, dynamic>> links;

  const PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    this.firstPageUrl,
    this.lastPageUrl,
    this.nextPageUrl,
    this.prevPageUrl,
    required this.path,
    required this.links,
  });

  /// Crea PaginationInfo desde JSON del backend Laravel
  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
      firstPageUrl: json['first_page_url'],
      lastPageUrl: json['last_page_url'],
      nextPageUrl: json['next_page_url'],
      prevPageUrl: json['prev_page_url'],
      path: json['path'] ?? '',
      links: (json['links'] as List<dynamic>?)
              ?.map((link) => link as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'from': from,
      'to': to,
      'first_page_url': firstPageUrl,
      'last_page_url': lastPageUrl,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
      'path': path,
      'links': links,
    };
  }

  /// Número total de páginas
  int get totalPages => lastPage;

  /// Indica si hay página siguiente
  bool get hasNextPage => nextPageUrl != null;

  /// Indica si hay página anterior
  bool get hasPrevPage => prevPageUrl != null;

  /// Indica si es la primera página
  bool get isFirstPage => currentPage == 1;

  /// Indica si es la última página
  bool get isLastPage => currentPage == lastPage;

  /// Indica si hay datos
  bool get hasData => total > 0;

  /// Rango de elementos mostrados (ej: "1-20 de 150")
  String rangeText(AppLocalizations l10n) {
    if (!hasData) {
      return l10n.noData;
    }
    return '$from-$to de $total';
  }

  /// Información de página (ej: "Página 1 de 5")
  String pageText(AppLocalizations l10n) {
    if (!hasData) {
      return l10n.noPages;
    }
    return l10n.pageXOfY(currentPage, lastPage);
  }

  @override
  String toString() {
    return 'PaginationInfo(currentPage: $currentPage, lastPage: $lastPage, perPage: $perPage, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PaginationInfo &&
        other.currentPage == currentPage &&
        other.lastPage == lastPage &&
        other.perPage == perPage &&
        other.total == total;
  }

  @override
  int get hashCode {
    return currentPage.hashCode ^
        lastPage.hashCode ^
        perPage.hashCode ^
        total.hashCode;
  }
}

/// Respuesta paginada genérica
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationInfo pagination;

  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  /// Crea PaginatedResponse desde JSON del backend Laravel
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<dynamic> itemsData = json['data'] ?? [];
    final Map<String, dynamic>? paginationData = json['pagination'];

    final List<T> items = itemsData
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();

    final pagination = PaginationInfo.fromJson(paginationData ?? {});

    return PaginatedResponse<T>(
      items: items,
      pagination: pagination,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) {
    return {
      'data': items.map((item) => toJson(item)).toList(),
      'pagination': pagination.toJson(),
    };
  }

  /// Número de elementos en esta página
  int get itemCount => items.length;

  /// Indica si hay elementos
  bool get hasItems => items.isNotEmpty;

  /// Indica si hay página siguiente
  bool get hasNextPage => pagination.hasNextPage;

  /// Indica si hay página anterior
  bool get hasPrevPage => pagination.hasPrevPage;

  /// Total de elementos
  int get totalItems => pagination.total;

  /// Página actual
  int get currentPage => pagination.currentPage;

  /// Total de páginas
  int get totalPages => pagination.totalPages;

  /// Elementos por página
  int get perPage => pagination.perPage;

  @override
  String toString() {
    return 'PaginatedResponse(items: ${items.length}, pagination: $pagination)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PaginatedResponse<T> &&
        other.items.length == items.length &&
        other.pagination == pagination;
  }

  @override
  int get hashCode {
    return items.length.hashCode ^ pagination.hashCode;
  }
}

/// Resultado paginado para repositorios
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });

  /// Crea desde PaginatedResponse
  factory PaginatedResult.fromPaginatedResponse(PaginatedResponse<T> response) {
    return PaginatedResult<T>(
      items: response.items,
      totalCount: response.totalItems,
      currentPage: response.currentPage,
      pageSize: response.perPage,
      totalPages: response.totalPages,
    );
  }

  /// Indica si hay página siguiente
  bool get hasNextPage => currentPage < totalPages;

  /// Indica si hay página anterior
  bool get hasPrevPage => currentPage > 1;

  /// Indica si es la primera página
  bool get isFirstPage => currentPage == 1;

  /// Indica si es la última página
  bool get isLastPage => currentPage == totalPages;

  /// Indica si hay elementos
  bool get hasItems => items.isNotEmpty;

  /// Número de elementos en esta página
  int get itemCount => items.length;

  @override
  String toString() {
    return 'PaginatedResult(items: ${items.length}, currentPage: $currentPage/$totalPages, total: $totalCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PaginatedResult<T> &&
        other.items.length == items.length &&
        other.totalCount == totalCount &&
        other.currentPage == currentPage &&
        other.pageSize == pageSize &&
        other.totalPages == totalPages;
  }

  @override
  int get hashCode {
    return items.length.hashCode ^
        totalCount.hashCode ^
        currentPage.hashCode ^
        pageSize.hashCode ^
        totalPages.hashCode;
  }
}

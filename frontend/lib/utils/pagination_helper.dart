import 'package:medrush/models/pagination.model.dart';
import 'package:medrush/utils/loggers.dart';

/// Helper para manejar lógica de paginación en pantallas
class PaginationHelper<T> {
  // Estado de paginación
  List<T> _items = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  DateTime? _lastLoadTime;

  // Getters
  List<T> get items => _items;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => _isLoadingMore;

  /// Inicializa la paginación
  void initialize() {
    _items = [];
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _hasMoreData = true;
    _isLoadingMore = false;
    _lastLoadTime = null;
  }

  /// Actualiza el estado con datos de la primera página
  void updateFirstPage(PaginatedResponse<T> paginatedData) {
    final uniqueItems = <T>[];
    final seenIds = <String>{};

    for (final item in paginatedData.items) {
      final itemId = _getItemId(item);
      if (!seenIds.contains(itemId)) {
        seenIds.add(itemId);
        uniqueItems.add(item);
      }
    }

    if (uniqueItems.length != paginatedData.items.length) {
      logWarning(
          '⚠️ Se encontraron ${paginatedData.items.length - uniqueItems.length} pedidos duplicados en la primera página, omitiendo...');
    }

    _items = uniqueItems;
    _currentPage = paginatedData.pagination.currentPage;
    _totalPages = paginatedData.pagination.lastPage;
    _totalItems = paginatedData.pagination.total;
    _hasMoreData = paginatedData.pagination.currentPage <
        paginatedData.pagination.lastPage;
    _isLoadingMore = false;

    logInfo(
        '✅ [PAGINATION] Primera página actualizada: ${_items.length} items, página $_currentPage/$_totalPages');
  }

  /// Actualiza el estado con datos de páginas adicionales
  void updateAdditionalPage(PaginatedResponse<T> paginatedData) {
    final existingIds = _items.map(_getItemId).toSet();
    final newItems = paginatedData.items
        .where((item) => !existingIds.contains(_getItemId(item)))
        .toList();

    if (newItems.length != paginatedData.items.length) {
      logWarning(
          '⚠️ Se encontraron ${paginatedData.items.length - newItems.length} pedidos duplicados, omitiendo...');
    }

    _items.addAll(newItems);
    _currentPage = _currentPage + 1;
    _totalPages = paginatedData.pagination.lastPage;
    _totalItems = paginatedData.pagination.total;
    _hasMoreData = _currentPage < _totalPages;
    _isLoadingMore = false;

    logInfo(
        '✅ Página adicional cargada: ${newItems.length} items únicos (total: ${_items.length}/$_totalItems) - Página $_currentPage/$_totalPages');
  }

  /// Método para corregir el currentPage después del auto-skip
  void setCurrentPage(int page) {
    _currentPage = page;
    logInfo('🔧 [PAGINATION] currentPage actualizado a $page');
  }

  /// Método para actualizar página con auto-skip (para historial)
  void updatePageWithAutoSkip(
      PaginatedResponse<T> paginatedData, int actualPage) {
    // Verificar duplicados
    final uniqueItems = <T>[];
    final seenIds = <String>{};

    for (final item in paginatedData.items) {
      final itemId = _getItemId(item);
      if (!seenIds.contains(itemId)) {
        seenIds.add(itemId);
        uniqueItems.add(item);
      }
    }

    if (uniqueItems.length != paginatedData.items.length) {
      logWarning(
          '⚠️ Se encontraron ${paginatedData.items.length - uniqueItems.length} pedidos duplicados, omitiendo...');
    }

    // Si es la primera página o no hay items, usar updateFirstPage
    if (_items.isEmpty) {
      _items = uniqueItems;
      _currentPage = actualPage;
      _totalPages = paginatedData.pagination.lastPage;
      _totalItems = paginatedData.pagination.total;
      _hasMoreData = actualPage < paginatedData.pagination.lastPage;
      _isLoadingMore = false;
      logInfo(
          '✅ [PAGINATION] Primera página con auto-skip: ${_items.length} items, página $_currentPage/$_totalPages');
    } else {
      // Si ya hay items, agregar como página adicional
      final existingIds = _items.map(_getItemId).toSet();
      final newItems = uniqueItems
          .where((item) => !existingIds.contains(_getItemId(item)))
          .toList();

      _items.addAll(newItems);
      _currentPage = actualPage;
      _totalPages = paginatedData.pagination.lastPage;
      _totalItems = paginatedData.pagination.total;
      _hasMoreData = _currentPage < _totalPages;
      _isLoadingMore = false;
      logInfo(
          '✅ [PAGINATION] Página adicional con auto-skip: ${newItems.length} items nuevos (total: ${_items.length}), página $_currentPage/$_totalPages');
    }
  }

  /// Verifica si se puede cargar más datos
  bool canLoadMore() {
    // Verificar si ya estamos en la última página
    if (_currentPage >= _totalPages) {
      logInfo('⚠️ Ya estamos en la última página ($_currentPage/$_totalPages)');
      return false;
    }

    // Verificar si ya tenemos todos los items
    if (_items.length >= _totalItems) {
      logInfo('⚠️ Ya tenemos todos los items (${_items.length}/$_totalItems)');
      return false;
    }

    // Verificar si ya está cargando
    if (_isLoadingMore) {
      logInfo('⚠️ Ya está cargando más datos');
      return false;
    }

    return true;
  }

  /// Verifica debounce (evita llamadas muy rápidas)
  bool canMakeRequest() {
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!).inSeconds < 1) {
      logInfo(
          '⚠️ Saltando carga por debounce (última llamada hace ${now.difference(_lastLoadTime!).inSeconds}s)');
      return false;
    }
    return true;
  }

  /// Marca como cargando
  void setLoadingMore({required bool loading}) {
    _isLoadingMore = loading;
    if (loading) {
      _lastLoadTime = DateTime.now();
    }
  }

  /// Obtiene la siguiente página a cargar
  int getNextPage() {
    return _currentPage + 1;
  }

  /// Verifica si se completó la carga de todos los datos
  bool isComplete() {
    return _currentPage >= _totalPages || _items.length >= _totalItems;
  }

  /// Obtiene información de estado para logs
  String getStatusInfo() {
    return 'Página $_currentPage/$_totalPages • ${_items.length}/$_totalItems items • Más datos: $_hasMoreData';
  }

  /// Obtiene información detallada de paginación para debugging
  Map<String, dynamic> getPaginationDebugInfo() {
    return {
      'frontend_current_page': _currentPage,
      'frontend_total_pages': _totalPages,
      'frontend_total_items': _totalItems,
      'frontend_items_loaded': _items.length,
      'frontend_has_more_data': _hasMoreData,
      'frontend_is_loading': _isLoadingMore,
    };
  }

  /// Filtra items localmente (para búsqueda)
  List<T> filterItems(bool Function(T) filter) {
    return _items.where(filter).toList();
  }

  /// Limpia todos los datos
  void clear() {
    _items.clear();
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _hasMoreData = true;
    _isLoadingMore = false;
    _lastLoadTime = null;
  }

  /// Obtiene el ID único de un item (para verificar duplicados)
  String _getItemId(T item) {
    if (item is Map<String, dynamic>) {
      return (item['id'] ?? '').toString();
    }

    try {
      final dynamic id = (item as dynamic).id;
      return id?.toString() ?? '';
    } catch (e) {
      return item.toString();
    }
  }
}

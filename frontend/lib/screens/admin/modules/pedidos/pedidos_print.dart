import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/pagination_helper.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/pagination_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidosPrintScreen extends StatefulWidget {
  final VoidCallback? onClose;

  const PedidosPrintScreen({
    super.key,
    this.onClose,
  });

  @override
  State<PedidosPrintScreen> createState() => _PedidosPrintScreenState();
}

class _PedidosPrintScreenState extends State<PedidosPrintScreen> {
  final Set<String> _pedidosSeleccionados = <String>{};
  bool _selectAll = false;
  bool _isPrinting = false;
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final PaginationHelper<Pedido> _paginationHelper = PaginationHelper<Pedido>();

  // Estado de carga
  List<Pedido> _pedidos = [];
  bool _isLoading = true;
  String? _error;

  // Búsqueda y filtros
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  // Filtrado múltiple por estado (solo estados relevantes para PDF)
  final Map<EstadoPedido, bool> _estadosSeleccionados = {
    EstadoPedido.pendiente: true, // Por defecto solo pendientes
    EstadoPedido.asignado: false,
    EstadoPedido.recogido: false,
    EstadoPedido.enRuta: false,
  };

  // Lista filtrada de pedidos
  // La búsqueda se hace en el backend, no localmente
  List<Pedido> get _pedidosFiltrados => _pedidos;

  // Lista de pedidos agrupados por fecha
  List<Widget> _pedidosAgrupadosPorFecha(BuildContext context) {
    if (_pedidosFiltrados.isEmpty) {
      return [];
    }

    // Agrupar pedidos por fecha
    final Map<String, List<Pedido>> pedidosPorFecha = {};

    for (final pedido in _pedidosFiltrados) {
      final fecha = pedido.createdAt;
      if (fecha != null) {
        final fechaKey = _obtenerClaveFecha(fecha);

        if (!pedidosPorFecha.containsKey(fechaKey)) {
          pedidosPorFecha[fechaKey] = [];
        }
        pedidosPorFecha[fechaKey]!.add(pedido);
      }
    }

    // Ordenar fechas (más recientes primero)
    final fechasOrdenadas = pedidosPorFecha.keys.toList()
      ..sort(_compararFechas);

    // Crear widgets con separadores
    final List<Widget> widgets = [];

    for (final fechaKey in fechasOrdenadas) {
      final pedidosDelDia = pedidosPorFecha[fechaKey]!;

      // Agregar separador de fecha
      widgets.add(_buildSeparadorFecha(context, fechaKey, pedidosDelDia.length));

      // Agregar pedidos del día
      for (final pedido in pedidosDelDia) {
        final isSelected = _pedidosSeleccionados.contains(pedido.id);
        widgets.add(_buildPedidoCard(pedido, isSelected));
      }
    }

    return widgets;
  }

  @override
  void initState() {
    super.initState();
    // Cargar pedidos desde la API
    _loadPedidos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPedidos() async {
    if (!mounted) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _paginationHelper.initialize();
      });

      logInfo('Cargando pedidos para generación de PDF');

      // Obtener pedidos según filtros seleccionados
      final estadosFiltrados = _getEstadosSeleccionados();
      final result = await _pedidoRepository.obtenerPaginados(
        perPage: 50, // 50 pedidos por página
        estados: estadosFiltrados.isNotEmpty
            ? estadosFiltrados
            : [EstadoPedido.pendiente],
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);

        setState(() {
          _pedidos = result.data!.items;
          _isLoading = false;
        });

        // Actualizar selección después de cargar
        _actualizarSeleccion();

        logInfo('${_pedidos.length} pedidos cargados para PDF');
      } else {
        setState(() {
          _error = result.error ?? AppLocalizations.of(context).errorLoadingOrders;
          _isLoading = false;
        });
        logError('Error al cargar pedidos para PDF: ${result.error}');
      }
    } catch (e) {
      logError('Error al cargar pedidos para PDF', e);
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).errorLoadingOrdersWithError(e);
          _isLoading = false;
        });
      }
    }
  }

  void _actualizarSeleccion() {
    // NO limpiar selección existente - mantener pedidos de otras páginas
    // Solo actualizar el estado de seleccionar todos para la página actual
    if (_pedidosFiltrados.isNotEmpty) {
      final pedidosActuales = _pedidosFiltrados.map((p) => p.id).toSet();
      final todosSeleccionados =
          pedidosActuales.every(_pedidosSeleccionados.contains);
      _selectAll = todosSeleccionados;
    } else {
      _selectAll = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context).generatePdfTitle} - ${_getFiltroTexto(context)}'),
        backgroundColor: MedRushTheme.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          _buildSearchAndFilterBar(),

          // Lista de pedidos con códigos de barras
          Expanded(
            child: _buildPedidosList(),
          ),

          // Barra de acciones
          _buildActionBar(),

          // Widget de paginación
          if (_paginationHelper.totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPedidosList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_pedidosFiltrados.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingMd),
      children: _pedidosAgrupadosPorFecha(context),
    );
  }

  Widget _buildPedidoCard(Pedido pedido, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        border: Border.all(
          color:
              isSelected ? MedRushTheme.primaryGreen : MedRushTheme.borderLight,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _togglePedidoSelection(pedido.id),
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.all(MedRushTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con checkbox y información del pedido
              Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _togglePedidoSelection(pedido.id),
                    activeColor: MedRushTheme.primaryGreen,
                  ),
                  const SizedBox(width: MedRushTheme.spacingSm),

                  // Información del pedido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pedido.pacienteNombre,
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyLarge,
                            fontWeight: MedRushTheme.fontWeightBold,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: MedRushTheme.spacingXs),
                        Text(
                          pedido.direccionEntrega,
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: MedRushTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Estado del pedido
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MedRushTheme.spacingSm,
                      vertical: MedRushTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: StatusHelpers.estadoPedidoColor(pedido.estado),
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          StatusHelpers.estadoPedidoIcon(pedido.estado),
                          size: 12,
                          color: MedRushTheme.textInverse,
                        ),
                        const SizedBox(width: 4),
                        Builder(
                          builder: (context) => Text(
                            StatusHelpers.estadoPedidoTexto(pedido.estado, AppLocalizations.of(context)),
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              color: MedRushTheme.textInverse,
                              fontWeight: MedRushTheme.fontWeightMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      decoration: const BoxDecoration(
        color: MedRushTheme.surface,
        border: Border(
          bottom: BorderSide(color: MedRushTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: MedRushTheme.backgroundSecondary,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: MedRushTheme.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) async {
                  setState(() {
                    _searchTerm = value;
                  });
                  // Recargar datos con el nuevo término de búsqueda
                  await _loadPedidos();
                },
                decoration: InputDecoration(
                  filled: false,
                  hintText: AppLocalizations.of(context).filterByNameAddressHint,
                  hintStyle: const TextStyle(
                    color: MedRushTheme.textSecondary,
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: MedRushTheme.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingMd,
                    vertical: MedRushTheme.spacingSm,
                  ),
                ),
                style: const TextStyle(
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
              ),
            ),
          ),

          const SizedBox(width: MedRushTheme.spacingMd),

          // Botón de seleccionar/deseleccionar todos
          DecoratedBox(
            decoration: BoxDecoration(
              color: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              border: Border.all(color: MedRushTheme.borderLight),
            ),
            child: TextButton.icon(
              onPressed: _toggleSelectAll,
              icon: Icon(
                _selectAll ? LucideIcons.check : LucideIcons.square,
                color: MedRushTheme.textSecondary,
                size: 18,
              ),
              label: Text(
                _selectAll ? AppLocalizations.of(context).deselectAll : AppLocalizations.of(context).selectAll,
                style: const TextStyle(
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
              ),
            ),
          ),

          const SizedBox(width: MedRushTheme.spacingMd),

          // Botón de filtros
          DecoratedBox(
            decoration: BoxDecoration(
              color: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              border: Border.all(color: MedRushTheme.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'dropdown_filter',
                padding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingMd),
                dropdownColor: MedRushTheme.backgroundSecondary,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                style: const TextStyle(
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: 'dropdown_filter',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.slidersHorizontal,
                          color: MedRushTheme.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingXs),
                        Text(
                          _getFiltroTexto(context),
                          style: const TextStyle(
                            color: MedRushTheme.textPrimary,
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estados con checkboxes (solo estados relevantes para PDF)
                  ..._estadosSeleccionados.keys.map((estado) {
                    return DropdownMenuItem<String>(
                      value: 'estado_${estado.name}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: 250,
                          child: Row(
                            children: [
                              Checkbox(
                                value: _estadosSeleccionados[estado] ?? false,
                                onChanged: null,
                                activeColor: MedRushTheme.primaryGreen,
                              ),
                              const SizedBox(width: MedRushTheme.spacingXs),
                              Icon(
                                StatusHelpers.estadoPedidoIcon(estado),
                                size: 16,
                                color: StatusHelpers.estadoPedidoColor(estado),
                              ),
                              const SizedBox(width: MedRushTheme.spacingXs),
                              Expanded(
                                child: Builder(
                                  builder: (context) => Text(
                                    StatusHelpers.estadoPedidoTexto(estado, AppLocalizations.of(context)),
                                    style: const TextStyle(
                                      fontSize: MedRushTheme.fontSizeBodyMedium,
                                      color: MedRushTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  // Botones de acción
                  const DropdownMenuItem<String>(
                    value: 'actions',
                    child: Divider(),
                  ),
                  DropdownMenuItem<String>(
                    value: 'select_all',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.check,
                          color: MedRushTheme.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingXs),
                        Text(
                          AppLocalizations.of(context).selectAllOrders,
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.x,
                          color: MedRushTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: MedRushTheme.spacingXs),
                        Text(
                          AppLocalizations.of(context).clearFilters,
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    // Manejar selección de estados
                    if (newValue.startsWith('estado_')) {
                      final estadoName = newValue.replaceFirst('estado_', '');
                      final estado = EstadoPedido.values.firstWhere(
                        (e) => e.name == estadoName,
                        orElse: () => EstadoPedido.pendiente,
                      );

                      setState(() {
                        _estadosSeleccionados[estado] =
                            !(_estadosSeleccionados[estado] ?? false);
                      });
                      await _loadPedidos();
                    }
                    // Manejar acciones especiales
                    else if (newValue == 'select_all') {
                      setState(() {
                        for (var estado in _estadosSeleccionados.keys) {
                          _estadosSeleccionados[estado] = true;
                        }
                      });
                      await _loadPedidos();
                    } else if (newValue == 'clear_all') {
                      setState(() {
                        for (var estado in _estadosSeleccionados.keys) {
                          _estadosSeleccionados[estado] = false;
                        }
                        // Mantener solo pendientes por defecto
                        _estadosSeleccionados[EstadoPedido.pendiente] = true;
                      });
                      await _loadPedidos();
                    }
                  }
                },
                icon: const Icon(
                  LucideIcons.chevronDown,
                  color: MedRushTheme.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(width: MedRushTheme.spacingMd),

          // Contador de selección
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MedRushTheme.spacingSm,
              vertical: MedRushTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
              border: Border.all(color: MedRushTheme.borderLight),
            ),
            child: Text(
              '${_pedidosSeleccionados.length} pedidos seleccionados',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                color: MedRushTheme.textSecondary,
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    // Calcular valores para la paginación
    final itemsPerPage = 50; // 50 pedidos por página
    final currentPageStart =
        ((_paginationHelper.currentPage - 1) * itemsPerPage) + 1;
    final currentPageEnd = (_paginationHelper.currentPage * itemsPerPage)
        .clamp(0, _paginationHelper.totalItems);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        MedRushTheme.spacingLg,
        0,
        MedRushTheme.spacingLg,
        MedRushTheme.spacingMd, // Aún más espacio abajo
      ),
      child: PaginationWidget(
        currentPage: _paginationHelper.currentPage,
        totalPages: _paginationHelper.totalPages,
        totalItems: _paginationHelper.totalItems,
        itemsPerPage: itemsPerPage,
        currentPageStart: currentPageStart,
        currentPageEnd: currentPageEnd,
        onPageChanged: (page) async {
          await _loadPage(page);
        },
        onItemsPerPageChanged: (perPage) async {
          await _loadPedidosWithPerPage(perPage);
        },
      ),
    );
  }

  Future<void> _loadPage(int page) async {
    if (!mounted) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final estadosFiltrados = _getEstadosSeleccionados();
      final result = await _pedidoRepository.obtenerPaginados(
        page: page,
        perPage: 50,
        estados: estadosFiltrados.isNotEmpty
            ? estadosFiltrados
            : [EstadoPedido.pendiente],
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);
        setState(() {
          _pedidos = result.data!.items;
          _isLoading = false;
        });

        // Actualizar selección después de cargar
        _actualizarSeleccion();
      } else {
        setState(() {
          _error = result.error ?? AppLocalizations.of(context).errorLoadingPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '${AppLocalizations.of(context).errorLoadingPage}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPedidosWithPerPage(int perPage) async {
    if (!mounted) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _paginationHelper.initialize();
      });

      final estadosFiltrados = _getEstadosSeleccionados();
      final result = await _pedidoRepository.obtenerPaginados(
        perPage: perPage,
        estados: estadosFiltrados.isNotEmpty
            ? estadosFiltrados
            : [EstadoPedido.pendiente],
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);
        setState(() {
          _pedidos = result.data!.items;
          _isLoading = false;
        });

        // Actualizar selección después de cargar
        _actualizarSeleccion();
      } else {
        setState(() {
          _error = result.error ?? AppLocalizations.of(context).errorChangingItemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '${AppLocalizations.of(context).errorChangingItemsPerPage}: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      decoration: const BoxDecoration(
        color: MedRushTheme.surface,
        border: Border(
          top: BorderSide(color: MedRushTheme.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón de copiar códigos
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _pedidosSeleccionados.isNotEmpty ? _copiarCodigos : null,
              icon: const Icon(LucideIcons.copy, size: 18),
              label: Text(AppLocalizations.of(context).copyData),
              style: OutlinedButton.styleFrom(
                foregroundColor: MedRushTheme.primaryBlue,
                side: const BorderSide(color: MedRushTheme.primaryBlue),
                padding: const EdgeInsets.symmetric(
                    vertical: MedRushTheme.spacingMd),
              ),
            ),
          ),

          const SizedBox(width: MedRushTheme.spacingMd),

          // Botón de generar PDF
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pedidosSeleccionados.isNotEmpty && !_isPrinting
                  ? _imprimirCodigos
                  : null,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MedRushTheme.textInverse,
                      ),
                    )
                  : const Icon(LucideIcons.download, size: 18),
              label: Text(_isPrinting ? AppLocalizations.of(context).generatingPdf : AppLocalizations.of(context).generatePdfTitle),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedRushTheme.primaryGreen,
                foregroundColor: MedRushTheme.textInverse,
                padding: const EdgeInsets.symmetric(
                    vertical: MedRushTheme.spacingMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: MedRushTheme.primaryBlue,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            AppLocalizations.of(context).loadingOrdersForPdf,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              color: MedRushTheme.textPrimary,
              fontWeight: MedRushTheme.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.x,
            size: 64,
            color: MedRushTheme.primaryBlue,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            l10n.errorLoadingOrders,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          Text(
            _error ?? l10n.unknownError,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: _loadPedidos,
            icon: const Icon(LucideIcons.refreshCw),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryBlue,
              foregroundColor: MedRushTheme.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.barcode,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            l10n.noPendingOrdersForPdf,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          Text(
            l10n.pendingOrdersPdfDescription,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      final pedidosActuales = _pedidosFiltrados.map((p) => p.id).toSet();

      if (_selectAll) {
        // Deseleccionar TODOS los pedidos (de todas las páginas)
        _pedidosSeleccionados.clear();
        _selectAll = false;
      } else {
        // Seleccionar solo los pedidos de la página actual
        _pedidosSeleccionados.addAll(pedidosActuales);
        _selectAll = true;
      }
    });
  }

  void _togglePedidoSelection(String pedidoId) {
    setState(() {
      if (_pedidosSeleccionados.contains(pedidoId)) {
        _pedidosSeleccionados.remove(pedidoId);
      } else {
        _pedidosSeleccionados.add(pedidoId);
      }

      // Actualizar estado de "seleccionar todos" solo para la página actual
      final pedidosActuales = _pedidosFiltrados.map((p) => p.id).toSet();
      _selectAll = pedidosActuales.every(_pedidosSeleccionados.contains);
    });
  }

  // Toggle selección de grupo por fecha
  void _toggleSeleccionGrupo(String fechaKey, List<Pedido> pedidosDelDia) {
    setState(() {
      final pedidosIds = pedidosDelDia.map((p) => p.id).toSet();
      final todosSeleccionados =
          pedidosIds.every(_pedidosSeleccionados.contains);

      if (todosSeleccionados) {
        // Deseleccionar todos los pedidos de este grupo
        _pedidosSeleccionados.removeAll(pedidosIds);
      } else {
        // Seleccionar todos los pedidos de este grupo
        _pedidosSeleccionados.addAll(pedidosIds);
      }

      // Actualizar estado de "seleccionar todos" para la página actual
      final pedidosActuales = _pedidosFiltrados.map((p) => p.id).toSet();
      _selectAll = pedidosActuales.every(_pedidosSeleccionados.contains);
    });
  }

  // Obtener clave de fecha para agrupación
  String _obtenerClaveFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final anteayer = hoy.subtract(const Duration(days: 2));
    final hace3Dias = hoy.subtract(const Duration(days: 3));

    final fechaPedido = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaPedido == hoy) {
      return 'hoy';
    } else if (fechaPedido == ayer) {
      return 'ayer';
    } else if (fechaPedido == anteayer) {
      return 'anteayer';
    } else if (fechaPedido == hace3Dias) {
      return 'hace3dias';
    } else {
      // Para fechas más antiguas, usar la fecha completa
      return '${fechaPedido.year}-${fechaPedido.month.toString().padLeft(2, '0')}-${fechaPedido.day.toString().padLeft(2, '0')}';
    }
  }

  // Comparar fechas para ordenamiento
  int _compararFechas(String fechaA, String fechaB) {
    // Ordenar por prioridad: hoy > ayer > anteayer > hace3dias > fechas específicas
    const prioridades = {
      'hoy': 0,
      'ayer': 1,
      'anteayer': 2,
      'hace3dias': 3,
    };

    final prioridadA = prioridades[fechaA] ?? 4;
    final prioridadB = prioridades[fechaB] ?? 4;

    if (prioridadA != prioridadB) {
      return prioridadA.compareTo(prioridadB);
    }

    // Si ambas son fechas específicas, comparar por fecha
    if (prioridadA == 4) {
      return fechaB.compareTo(fechaA); // Más recientes primero
    }

    return 0;
  }

  // Construir separador de fecha
  Widget _buildSeparadorFecha(BuildContext context, String fechaKey, int cantidad) {
    final l10n = AppLocalizations.of(context);
    String titulo;
    String subtitulo;

    switch (fechaKey) {
      case 'hoy':
        titulo = l10n.dateToday;
        subtitulo = l10n.ordersCountLabel(cantidad);
      case 'ayer':
        titulo = l10n.dateYesterday;
        subtitulo = l10n.ordersCountLabel(cantidad);
      case 'anteayer':
        titulo = l10n.dateDayBeforeYesterday;
        subtitulo = l10n.ordersCountLabel(cantidad);
      case 'hace3dias':
        titulo = l10n.dateThreeDaysAgo;
        subtitulo = l10n.ordersCountLabel(cantidad);
      default:
        // Fecha específica
        final partes = fechaKey.split('-');
        if (partes.length == 3) {
          final fecha = DateTime(
            int.parse(partes[0]), // año
            int.parse(partes[1]), // mes
            int.parse(partes[2]), // día
          );
          titulo = '${fecha.day}/${fecha.month}/${fecha.year}';
          subtitulo = l10n.ordersCountLabel(cantidad);
        } else {
          titulo = fechaKey;
          subtitulo = l10n.ordersCountLabel(cantidad);
        }
    }

    // Verificar si todos los pedidos de esta fecha están seleccionados
    final pedidosDelDia = _pedidosFiltrados.where((pedido) {
      if (pedido.createdAt == null) {
        return false;
      }
      final fechaKeyPedido = _obtenerClaveFecha(pedido.createdAt!);
      return fechaKeyPedido == fechaKey;
    }).toList();

    final todosSeleccionados = pedidosDelDia
        .every((pedido) => _pedidosSeleccionados.contains(pedido.id));

    return Container(
      margin: const EdgeInsets.only(
        top: MedRushTheme.spacingLg,
        bottom: MedRushTheme.spacingMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: MedRushTheme.borderLight,
            ),
          ),
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingMd),
            padding: const EdgeInsets.symmetric(
              horizontal: MedRushTheme.spacingMd,
              vertical: MedRushTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
              border: Border.all(color: MedRushTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de selección del grupo
                GestureDetector(
                  onTap: () => _toggleSeleccionGrupo(fechaKey, pedidosDelDia),
                  child: Container(
                    padding: const EdgeInsets.all(MedRushTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: todosSeleccionados
                          ? MedRushTheme.primaryGreen
                          : MedRushTheme.backgroundPrimary,
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                      border: Border.all(
                        color: todosSeleccionados
                            ? MedRushTheme.primaryGreen
                            : MedRushTheme.borderLight,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      todosSeleccionados
                          ? LucideIcons.check
                          : LucideIcons.square,
                      size: 16,
                      color: todosSeleccionados
                          ? MedRushTheme.textInverse
                          : MedRushTheme.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(width: MedRushTheme.spacingSm),

                // Información del grupo
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        fontWeight: MedRushTheme.fontWeightBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: MedRushTheme.borderLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copiarCodigos() async {
    try {
      // Obtener todos los pedidos seleccionados de todas las páginas
      final pedidosSeleccionados =
          _pedidos.where((p) => _pedidosSeleccionados.contains(p.id)).toList();

      final codigos = pedidosSeleccionados
          .map((p) => '${p.pacienteNombre} - ${p.codigoBarra}')
          .join('\n');

      await Clipboard.setData(ClipboardData(text: codigos));

      if (mounted) {
        NotificationService.showSuccess(
          '${pedidosSeleccionados.length} etiquetas copiadas al portapapeles',
          context: context,
        );
      }

      logInfo(
          'Datos de etiquetas copiados: ${pedidosSeleccionados.length} pedidos');
    } catch (e) {
      logError('Error al copiar datos de etiquetas', e);
      if (mounted) {
        NotificationService.showError(
          'Error al copiar datos: $e',
          context: context,
        );
      }
    }
  }

  Future<void> _imprimirCodigos() async {
    if (_pedidosSeleccionados.isEmpty) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    setState(() {
      _isPrinting = true;
    });

    try {
      // Obtener todos los pedidos seleccionados de todas las páginas
      final pedidosSeleccionados =
          _pedidos.where((p) => _pedidosSeleccionados.contains(p.id)).toList();

      final pedidosIds = pedidosSeleccionados.map((p) => p.id).toList();

      logInfo(
          'Generando PDF con ${pedidosSeleccionados.length} etiquetas de envío - Iniciado a las ${DateTime.now().toIso8601String()}');

      // Guardar l10n antes del async para evitar problemas con BuildContext
      final l10n = AppLocalizations.of(context);

      // Mostrar progreso al usuario
      if (mounted) {
        NotificationService.showInfo(
          'Generando PDF... Por favor espere',
          context: context,
        );
      }

      // Generar PDF usando el backend
      final result = await _pedidoRepository
          .generarEtiquetasPdf(
        pedidosIds: pedidosIds,
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout: La generación del PDF tardó demasiado');
        },
      );

      if (result.success && result.data != null) {
        final pdfData = result.data!;
        final fileUrl = pdfData['file_url'] as String?;
        final filename = pdfData['filename'] as String;

        if (fileUrl != null) {
          // PDF está listo, descargar inmediatamente
          await _descargarPdfDesdeUrl(fileUrl, filename, l10n);

          if (mounted) {
            NotificationService.showSuccess(
              '${pedidosSeleccionados.length} etiquetas de envío descargadas como PDF',
              context: context,
            );
          }
        } else {
          throw Exception(l10n.pdfDownloadUrlNotReceived);
        }

        stopwatch.stop();
        final totalSeconds = stopwatch.elapsedMilliseconds / 1000;
        logInfo(
            'Solicitud de PDF procesada: ${pedidosSeleccionados.length} etiquetas - Tiempo total del proceso: ${totalSeconds.toStringAsFixed(2)}s (${stopwatch.elapsedMilliseconds}ms)');
      } else {
        throw Exception(result.error ?? l10n.unknownErrorGeneratingPdf);
      }
    } catch (e) {
      logError('Error al generar PDF', e);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final String errorMessage = e.toString().contains('Timeout')
            ? l10n.pdfGenerationTimeout
            : l10n.errorGeneratingPdfWithError(e);

        NotificationService.showError(
          errorMessage,
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  /// Descarga el PDF desde una URL del backend
  Future<void> _descargarPdfDesdeUrl(
      String downloadUrl, String filename, AppLocalizations l10n) async {
    final stopwatch = Stopwatch()..start();
    try {
      // Usar url_launcher para abrir la URL de descarga
      final uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode:
              LaunchMode.externalApplication, // Abrir en nueva pestaña/ventana
        );

        stopwatch.stop();
        logInfo(
            'PDF abierto para descarga desde backend - Tiempo: ${stopwatch.elapsedMilliseconds}ms');
      } else {
        throw Exception(l10n.couldNotOpenDownloadLink);
      }
    } catch (e) {
      logError('Error al abrir PDF desde URL', e);
      rethrow;
    }
  }

  // Métodos para filtrado múltiple
  List<EstadoPedido> _getEstadosSeleccionados() {
    return _estadosSeleccionados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  String _getFiltroTexto(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seleccionados = _getEstadosSeleccionados();
    if (seleccionados.isEmpty) {
      return l10n.onlyPending;
    } else if (seleccionados.length == 1) {
      return StatusHelpers.estadoPedidoTexto(seleccionados.first, l10n);
    } else {
      return l10n.statesCount(seleccionados.length);
    }
  }
}

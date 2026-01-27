import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/screens/admin/modules/pedidos/pedidos_csv.dart';
import 'package:medrush/screens/admin/modules/pedidos/pedidos_detalles.dart';
import 'package:medrush/screens/admin/modules/pedidos/pedidos_form.dart';
import 'package:medrush/screens/admin/modules/pedidos/pedidos_list.dart';
import 'package:medrush/screens/admin/modules/pedidos/pedidos_print.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/pagination_helper.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/pagination_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';

class EntregasScreen extends StatefulWidget {
  const EntregasScreen({super.key});

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen> {
  final PedidoRepository _repository = PedidoRepository();
  final PaginationHelper<Pedido> _paginationHelper = PaginationHelper<Pedido>();
  final TextEditingController _searchController = TextEditingController();

  List<Pedido> _pedidosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  EstadoPedido? _filtroEstado;
  String _searchTerm = ''; // FIX: Agregar término de búsqueda
  bool _isTableView =
      true; // FIX: Controlar vista de tabla vs tarjetas - se ajusta según dispositivo

  // Filtrado múltiple
  final Map<EstadoPedido, bool> _estadosSeleccionados = {
    EstadoPedido.pendiente: false,
    EstadoPedido.asignado: false,
    EstadoPedido.recogido: false,
    EstadoPedido.enRuta: false,
    EstadoPedido.entregado: false,
    EstadoPedido.fallido: false,
    EstadoPedido.cancelado: false,
  };

  @override
  void initState() {
    super.initState();
    _loadPedidos();

    // FIX: Ajustar vista inicial según el dispositivo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth <= 600;
        setState(() {
          _isTableView = !isMobile; // Lista en móvil, tabla en desktop
        });
      }
    });
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

      logInfo('Cargando pedidos desde el repositorio');

      // FIX: Usar query params para búsqueda y filtros múltiples
      final estadosFiltrados = _getEstadosSeleccionados();
      final result = await _repository.obtenerPaginados(
        estados: estadosFiltrados.isNotEmpty ? estadosFiltrados : null,
        estado: estadosFiltrados.isEmpty
            ? _filtroEstado
            : null, // Fallback al filtro simple
        search: _searchTerm.isNotEmpty
            ? _searchTerm
            : null, // FIX: Incluir búsqueda
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);

        setState(() {
          _pedidosFiltrados = result.data!.items;
          _isLoading = false;
        });

        logInfo('${result.data!.items.length} pedidos cargados exitosamente');
      } else {
        setState(() {
          _error = result.error ?? 'Error desconocido al cargar pedidos';
          _isLoading = false;
        });
        logError('Error al cargar pedidos: ${result.error}');
      }
    } catch (e) {
      logError('Error al cargar pedidos', e);

      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Error al cargar los pedidos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await _loadPedidos();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;
    final isMobile = screenWidth <= 600;

    final double fabBottom = MediaQuery.of(context).padding.bottom + 8;
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      body: SafeArea(
        child: isDesktop
            ? _buildResponsiveBody(isDesktop, isTablet, isMobile)
            : Column(
                children: [
                  // Barra de paginación (solo móvil/tablet)
                  _buildPaginationInfo(),

                  // Filtro por estado y búsqueda (solo móvil/tablet)
                  _buildFilterBar(),

                  // Contenido principal
                  Expanded(
                    child: _buildResponsiveBody(isDesktop, isTablet, isMobile),
                  ),
                ],
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FAB para imprimir códigos de barras (solo desktop)
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                heroTag: 'fab_print_barcodes',
                onPressed: _mostrarPantallaImpresion,
                backgroundColor: MedRushTheme.primaryBlue,
                tooltip: 'Imprimir Etiquetas de Envío',
                child: const Icon(LucideIcons.printer),
              ),
            ),
          // FAB para cargar CSV
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton(
              heroTag: 'fab_upload_csv',
              onPressed: () {
                PedidosCsvScreen.show(context);
              },
              backgroundColor: MedRushTheme.neutralGrey700,
              tooltip: 'Cargar CSV',
              child: const Icon(LucideIcons.upload),
            ),
          ),
          // FAB para agregar pedido individual
          Padding(
            padding: EdgeInsets.only(bottom: fabBottom),
            child: FloatingActionButton(
              heroTag: 'fab_add_entrega',
              onPressed: () {
                showMaterialModalBottomSheet(
                  context: context,
                  expand: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => EntregasForm(
                    onSave: (pedido) async {
                      Navigator.of(context).pop();
                      if (mounted) {
                        await _loadPedidos();
                      }
                    },
                  ),
                );
              },
              backgroundColor: MedRushTheme.primaryGreen,
              tooltip: 'Agregar Pedido',
              child: const Icon(LucideIcons.plus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveBody(bool isDesktop, bool isTablet, bool isMobile) {
    if (isDesktop) {
      return _buildDesktopLayout();
    } else {
      // Tablet y móvil usan el mismo layout de lista
      return _buildListLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      child: Column(
        children: [
          // Barra de búsqueda, filtro y toggle de vista en una sola fila
          _buildDesktopSearchBarAndFilter(),
          const SizedBox(height: MedRushTheme.spacingMd),
          // Contenido principal
          Expanded(
            child: _buildContent(),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          // Widget de paginación en la parte inferior
          if (_paginationHelper.totalPages > 1) _buildDesktopPagination(),
        ],
      ),
    );
  }

  Widget _buildListLayout() {
    return _buildContent();
  }

  Widget _buildViewToggleButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón vista de tabla
          InkWell(
            onTap: () {
              setState(() {
                _isTableView = true;
              });
            },
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            child: Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingSm),
              decoration: BoxDecoration(
                color: _isTableView
                    ? MedRushTheme.primaryGreen
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
              ),
              child: Icon(
                LucideIcons.tableProperties,
                color: _isTableView
                    ? MedRushTheme.textInverse
                    : MedRushTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
          // Botón vista de lista
          InkWell(
            onTap: () {
              setState(() {
                _isTableView = false;
              });
            },
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            child: Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingSm),
              decoration: BoxDecoration(
                color: !_isTableView
                    ? MedRushTheme.primaryGreen
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
              ),
              child: Icon(
                LucideIcons.layoutList,
                color: !_isTableView
                    ? MedRushTheme.textInverse
                    : MedRushTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSearchBarAndFilter() {
    return Row(
      children: [
        // Barra de búsqueda (izquierda)
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.only(right: MedRushTheme.spacingMd),
            decoration: BoxDecoration(
              color: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              border: Border.all(color: MedRushTheme.borderLight),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) async {
                setState(() {
                  _searchTerm = value;
                });
                await _loadPedidos();
              },
              decoration: const InputDecoration(
                filled: false,
                hintText: 'Buscar por cliente, código, teléfono...',
                hintStyle: TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: MedRushTheme.textSecondary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
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

        // Filtro múltiple de estados (centro)
        Container(
          margin: const EdgeInsets.only(right: MedRushTheme.spacingMd),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'dropdown_filter', // Valor fijo para evitar conflictos
              padding: const EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingMd),
              dropdownColor: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
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
                        _getFiltroTexto(),
                        style: const TextStyle(
                          color: MedRushTheme.textPrimary,
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                // Estados con checkboxes
                ...EstadoPedido.values.map((estado) {
                  return DropdownMenuItem<String>(
                    value: 'estado_${estado.name}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        width:
                            250, // Ancho fijo para evitar problemas de layout
                        child: Row(
                          children: [
                            Checkbox(
                              value: _estadosSeleccionados[estado] ?? false,
                              onChanged:
                                  null, // Deshabilitado, se maneja en onChanged
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
                              child: Text(
                                StatusHelpers.estadoPedidoTexto(estado),
                                style: const TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodyMedium,
                                  color: MedRushTheme.textPrimary,
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
                const DropdownMenuItem<String>(
                  value: 'select_all',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.check,
                        color: MedRushTheme.primaryGreen,
                        size: 16,
                      ),
                      SizedBox(width: MedRushTheme.spacingXs),
                      Text(
                        'Seleccionar Todos',
                        style: TextStyle(
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                          color: MedRushTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const DropdownMenuItem<String>(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.x,
                        color: MedRushTheme.textSecondary,
                        size: 16,
                      ),
                      SizedBox(width: MedRushTheme.spacingXs),
                      Text(
                        'Limpiar Filtros',
                        style: TextStyle(
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                          color: MedRushTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (String? newValue) {
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
                    _loadPedidos();
                  }
                  // Manejar acciones especiales
                  else if (newValue == 'select_all') {
                    setState(() {
                      for (var estado in EstadoPedido.values) {
                        _estadosSeleccionados[estado] = true;
                      }
                    });
                    _loadPedidos();
                  } else if (newValue == 'clear_all') {
                    setState(() {
                      for (var estado in EstadoPedido.values) {
                        _estadosSeleccionados[estado] = false;
                      }
                    });
                    _loadPedidos();
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

        // Botón de toggle de vista (derecha)
        _buildViewToggleButton(),
      ],
    );
  }

  Widget _buildDesktopPagination() {
    // Calcular valores para la paginación
    final itemsPerPage = 20; // 20 pedidos por página
    final currentPageStart =
        ((_paginationHelper.currentPage - 1) * itemsPerPage) + 1;
    final currentPageEnd = (_paginationHelper.currentPage * itemsPerPage)
        .clamp(0, _paginationHelper.totalItems);

    return PaginationWidget(
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
      final result = await _repository.obtenerPaginados(
        page: page,
        estados: estadosFiltrados.isNotEmpty ? estadosFiltrados : null,
        estado: estadosFiltrados.isEmpty ? _filtroEstado : null,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);
        setState(() {
          _pedidosFiltrados = result.data!.items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Error al cargar la página';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Error al cargar la página: $e';
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
      final result = await _repository.obtenerPaginados(
        perPage: perPage,
        estados: estadosFiltrados.isNotEmpty ? estadosFiltrados : null,
        estado: estadosFiltrados.isEmpty ? _filtroEstado : null,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);
        setState(() {
          _pedidosFiltrados = result.data!.items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Error al cambiar items por página';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Error al cambiar items por página: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          DecoratedBox(
            decoration: BoxDecoration(
              color: MedRushTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedRushTheme.borderPrimary),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) async {
                setState(() {
                  _searchTerm = value;
                });
                // FIX: Recargar datos cuando cambie la búsqueda
                await _loadPedidos();
              },
              decoration: const InputDecoration(
                filled: false,
                hintText: 'Buscar por cliente, código, teléfono...',
                hintStyle: TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: MedRushTheme.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingMd,
                  vertical: MedRushTheme.spacingMd,
                ),
              ),
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtro múltiple por estado
          DecoratedBox(
            decoration: BoxDecoration(
              color: MedRushTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MedRushTheme.borderPrimary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'dropdown_filter', // Valor fijo para evitar conflictos
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        Expanded(
                          child: Text(
                            _getFiltroTexto(),
                            style: const TextStyle(
                              color: MedRushTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estados con checkboxes
                  ...EstadoPedido.values.map((estado) {
                    return DropdownMenuItem<String>(
                      value: 'estado_${estado.name}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: 280, // Ancho fijo para mobile/tablet
                          child: Row(
                            children: [
                              Checkbox(
                                value: _estadosSeleccionados[estado] ?? false,
                                onChanged:
                                    null, // Deshabilitado, se maneja en onChanged
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
                                child: Text(
                                  StatusHelpers.estadoPedidoTexto(estado),
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeBodyMedium,
                                    color: MedRushTheme.textPrimary,
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
                  const DropdownMenuItem<String>(
                    value: 'select_all',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.check,
                          color: MedRushTheme.primaryGreen,
                          size: 16,
                        ),
                        SizedBox(width: MedRushTheme.spacingXs),
                        Text(
                          'Seleccionar Todos',
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const DropdownMenuItem<String>(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.x,
                          color: MedRushTheme.textSecondary,
                          size: 16,
                        ),
                        SizedBox(width: MedRushTheme.spacingXs),
                        Text(
                          'Limpiar Filtros',
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                            color: MedRushTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
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
                      _loadPedidos();
                    }
                    // Manejar acciones especiales
                    else if (newValue == 'select_all') {
                      setState(() {
                        for (var estado in EstadoPedido.values) {
                          _estadosSeleccionados[estado] = true;
                        }
                      });
                      _loadPedidos();
                    } else if (newValue == 'clear_all') {
                      setState(() {
                        for (var estado in EstadoPedido.values) {
                          _estadosSeleccionados[estado] = false;
                        }
                      });
                      _loadPedidos();
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_pedidosFiltrados.isEmpty) {
      return _buildEmptyState();
    }

    // FIX: Mostrar vista de tabla o tarjetas según el toggle
    if (_isTableView) {
      return Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingMd),
        child: PedidosTableView(
          pedidos: _pedidosFiltrados,
          onRefresh: _onRefresh,
          onEdit: (pedido) => _showPedidoForm(pedido: pedido),
          onView: _showPedidoDetails,
          onDelete: _deletePedido,
          isLoading: _isLoading,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          MedRushTheme.spacingMd,
          0,
          MedRushTheme.spacingMd,
          MedRushTheme.spacingMd, // Padding reducido para el FAB
        ),
        itemCount: _pedidosFiltrados.length,
        itemBuilder: (context, index) {
          final pedido = _pedidosFiltrados[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
            child: _buildEntregaCard(pedido),
          );
        },
      ),
    );
  }

  Widget _buildEntregaCard(Pedido pedido) {
    return Container(
      margin: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MedRushTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre del cliente e iconos
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _copiarInformacionCliente(pedido),
                    child: Text(
                      pedido.pacienteNombre,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyLarge,
                        fontWeight: MedRushTheme.fontWeightBold,
                        color: MedRushTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                // Iconos de acción
                Row(
                  children: [
                    // Botón principal: Asignar si pendiente, Ver si no
                    IconButton(
                      icon: Icon(
                        pedido.estado == EstadoPedido.pendiente
                            ? LucideIcons.userPlus
                            : LucideIcons.eye,
                        color: MedRushTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: pedido.estado == EstadoPedido.pendiente
                          ? 'Asignar Repartidor'
                          : 'Ver',
                      onPressed: () {
                        if (pedido.estado == EstadoPedido.pendiente) {
                          _showAsignarRepartidorDialog(pedido);
                        } else {
                          showMaterialModalBottomSheet(
                            context: context,
                            expand: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                EntregasDetalles(pedido: pedido),
                          );
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.barcode,
                        color: MedRushTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Código de barras',
                      onPressed: () => _showBarcodeDialog(pedido),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    // Botón Editar solo para pedidos pendientes
                    if (pedido.estado == EstadoPedido.pendiente)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.pencil,
                          color: MedRushTheme.textSecondary,
                          size: 20,
                        ),
                        tooltip: 'Editar',
                        onPressed: () {
                          showMaterialModalBottomSheet(
                            context: context,
                            expand: true,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            builder: (context) => EntregasForm(
                              onSave: (pedido) {
                                Navigator.of(context).pop();
                                _loadPedidos();
                              },
                              initialData: pedido,
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    // Menú de más opciones
                    PopupMenuButton<String>(
                      icon: const Icon(
                        LucideIcons.ellipsis,
                        color: MedRushTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Más opciones',
                      onSelected: (value) async {
                        switch (value) {
                          case 'editar':
                            showMaterialModalBottomSheet(
                              context: context,
                              expand: true,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              builder: (context) => EntregasForm(
                                onSave: (pedido) {
                                  Navigator.of(context).pop();
                                  _loadPedidos();
                                },
                                initialData: pedido,
                              ),
                            );
                          case 'asignar':
                            _showAsignarRepartidorDialog(pedido);
                          case 'cancelar':
                            await _showCancelarPedidoDialog(pedido);
                          case 'fallo':
                            await _showMarcarFalloDialog(pedido);
                          case 'eliminar':
                            _deletePedido(pedido);
                        }
                      },
                      itemBuilder: (context) => [
                        // Editar (siempre visible)
                        const PopupMenuItem<String>(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.pencil,
                                color: MedRushTheme.textSecondary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        // Asignar Repartidor (solo para pendientes)
                        if (pedido.estado == EstadoPedido.pendiente)
                          const PopupMenuItem<String>(
                            value: 'asignar',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.userPlus,
                                  color: MedRushTheme.primaryGreen,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Asignar Repartidor'),
                              ],
                            ),
                          ),
                        // Cancelar (solo si está asignado)
                        if (pedido.estado == EstadoPedido.asignado)
                          const PopupMenuItem<String>(
                            value: 'cancelar',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.x,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Cancelar Pedido'),
                              ],
                            ),
                          ),
                        // Opciones para pedidos recogidos y en ruta (pueden ser fallidos)
                        if ((pedido.estado == EstadoPedido.recogido ||
                                pedido.estado == EstadoPedido.enRuta) &&
                            pedido.estado != EstadoPedido.entregado &&
                            pedido.estado != EstadoPedido.fallido &&
                            pedido.estado != EstadoPedido.cancelado) ...[
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'cancelar',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.x,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Cancelar Pedido'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'fallo',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.badgeAlert,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Marcar como Fallido'),
                              ],
                            ),
                          ),
                        ],
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trash2,
                                color: Colors.red,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MedRushTheme.spacingXs),

            // Código de barras
            Text(
              'Código: ${pedido.codigoBarra}',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                color: MedRushTheme.textSecondary,
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingXs),

            // Dirección de entrega
            Text(
              pedido.direccionEntrega,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textSecondary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingSm),

            // Información del repartidor
            if (pedido.repartidor != null || pedido.repartidorId != null)
              Row(
                children: [
                  const Icon(
                    LucideIcons.user,
                    size: 14,
                    color: MedRushTheme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pedido.repartidor != null
                        ? pedido.repartidor!.nombre
                        : pedido.repartidorId != null
                            ? 'Asignado'
                            : 'Sin asignar',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      fontWeight: MedRushTheme.fontWeightMedium,
                      color: pedido.repartidorId != null
                          ? MedRushTheme.primaryGreen
                          : MedRushTheme.textSecondary,
                    ),
                  ),
                  if (pedido.repartidor?.verificado == true) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.check,
                      color: MedRushTheme.primaryGreen,
                      size: 12,
                    ),
                  ],
                ],
              ),
            if (pedido.repartidor != null || pedido.repartidorId != null)
              const SizedBox(height: MedRushTheme.spacingSm),

            // Fila inferior con estado, fecha y botón
            Row(
              children: [
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
                        size: 14,
                        color: MedRushTheme.textInverse,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        StatusHelpers.estadoPedidoTexto(pedido.estado),
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeBodySmall,
                          color: MedRushTheme.textInverse,
                          fontWeight: MedRushTheme.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MedRushTheme.spacingSm),

                // Fecha relativa
                Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: MedRushTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      StatusHelpers
                          .obtenerFechaRelativaSegunPrioridadOptimizada(pedido),
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Botón Ver Detalles
                ElevatedButton(
                  onPressed: () {
                    showMaterialModalBottomSheet(
                      context: context,
                      expand: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => EntregasDetalles(pedido: pedido),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedRushTheme.primaryGreen,
                    foregroundColor: MedRushTheme.textInverse,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MedRushTheme.spacingMd,
                      vertical: MedRushTheme.spacingXs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ver Detalles',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      fontWeight: MedRushTheme.fontWeightMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.x,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          const Text(
            'Error al cargar los pedidos',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          Text(
            _error ?? 'Error desconocido',
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
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: MedRushTheme.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.truck,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          SizedBox(height: MedRushTheme.spacingLg),
          Text(
            'No se encontraron entregas',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          SizedBox(height: MedRushTheme.spacingMd),
          Text(
            'No hay pedidos que coincidan con los filtros aplicados',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingLg),
      padding: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingMd,
        vertical: MedRushTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando ${_paginationHelper.items.length} de ${_paginationHelper.totalItems} pedidos',
            style: const TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodySmall,
            ),
          ),
          if (_paginationHelper.totalPages > 1)
            Text(
              'Página ${_paginationHelper.currentPage} de ${_paginationHelper.totalPages}',
              style: const TextStyle(
                color: MedRushTheme.primaryGreen,
                fontSize: MedRushTheme.fontSizeBodySmall,
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
            ),
        ],
      ),
    );
  }

  // Métodos para filtrado múltiple
  List<EstadoPedido> _getEstadosSeleccionados() {
    return _estadosSeleccionados.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  String _getFiltroTexto() {
    final seleccionados = _getEstadosSeleccionados();
    if (seleccionados.isEmpty) {
      return 'Todos los estados';
    } else if (seleccionados.length == 1) {
      return StatusHelpers.estadoPedidoTexto(seleccionados.first);
    } else {
      return '${seleccionados.length} estados';
    }
  }

  void _showBarcodeDialog(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.barcode,
              color: MedRushTheme.neutralGrey700,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Código de Barras'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pedido #${pedido.id}',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingLg),
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: MedRushTheme.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: MedRushTheme.shadowLight,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: pedido.codigoBarra,
                    width: 250,
                    height: 80,
                    color: MedRushTheme.textPrimary,
                    backgroundColor: MedRushTheme.surface,
                  ),
                  const SizedBox(height: MedRushTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MedRushTheme.spacingMd,
                      vertical: MedRushTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: MedRushTheme.backgroundSecondary,
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: Text(
                      pedido.codigoBarra,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        fontWeight: MedRushTheme.fontWeightBold,
                        fontFamily: 'monospace',
                        color: MedRushTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                  const Text(
                    'Código de barras del pedido',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // FIX: Métodos para manejar acciones de pedidos
  void _showPedidoDetails(Pedido pedido) {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => EntregasDetalles(pedido: pedido),
    );
  }

  void _showPedidoForm({Pedido? pedido}) {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => EntregasForm(
        onSave: (pedido) {
          Navigator.of(context).pop();
          _loadPedidos();
        },
        initialData: pedido,
      ),
    ).then((value) {
      if (value == true) {
        _loadPedidos(); // Recargar pedidos si se hizo un cambio
      }
    });
  }

  void _deletePedido(Pedido pedido) {
    _showDeleteConfirmation(pedido);
  }

  void _showDeleteConfirmation(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.triangleAlert,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar el pedido #${pedido.id}?',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: MedRushTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer. El pedido será eliminado permanentemente.',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeletePedido(pedido);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeletePedido(Pedido pedido) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      logInfo('Eliminando pedido ${pedido.id}');
      final result = await _repository.eliminarPedido(pedido.id);

      // Cerrar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          NotificationService.showSuccess(
            'Pedido #${pedido.id} eliminado exitosamente',
            context: context,
          );
        }

        // Recargar la lista
        await _loadPedidos();
      } else {
        // Mostrar mensaje de error
        if (mounted) {
          NotificationService.showError(
            'Error al eliminar pedido: ${result.error}',
            context: context,
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
      }

      logError('Error al eliminar pedido ${pedido.id}', e);

      // Mostrar mensaje de error
      if (mounted) {
        NotificationService.showError(
          'Error al eliminar pedido: $e',
          context: context,
        );
      }
    }
  }

  Future<void> _copiarInformacionCliente(Pedido pedido) async {
    try {
      final informacion =
          'Cliente: ${pedido.pacienteNombre}\nID Pedido: ${pedido.id}';

      await Clipboard.setData(ClipboardData(text: informacion));

      if (mounted) {
        NotificationService.showSuccess(
          'Información copiada al portapapeles',
          context: context,
        );
      }

      logInfo(
          'Información del cliente copiada: ${pedido.pacienteNombre} - ${pedido.id}');
    } catch (e) {
      logError('Error al copiar información del cliente', e);
      if (mounted) {
        NotificationService.showError(
          'Error al copiar información',
          context: context,
        );
      }
    }
  }

  Future<void> _showAsignarRepartidorDialog(Pedido pedido) async {
    try {
      final repartidorRepository = RepartidorRepository();
      final result = await repartidorRepository.getRepartidoresActivos();

      if (!mounted) {
        return;
      }

      if (!result.success || result.data == null) {
        if (mounted) {
          NotificationService.showError(
            'Error al cargar repartidores: ${result.error}',
            context: context,
          );
        }
        return;
      }

      final repartidores = result.data!;
      Usuario? seleccionado;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  LucideIcons.userPlus,
                  color: MedRushTheme.primaryGreen,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text('Asignar Repartidor'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selecciona un repartidor para el pedido de ${pedido.pacienteNombre}',
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (repartidores.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No hay repartidores disponibles',
                        style: TextStyle(
                          color: MedRushTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: repartidores.length,
                        itemBuilder: (context, index) {
                          final r = repartidores[index];
                          final isSelected = seleccionado?.id == r.id;
                          return ListTile(
                            leading: _buildRepartidorAvatar(r),
                            title: Text(r.nombre),
                            subtitle:
                                r.telefono != null ? Text(r.telefono!) : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                seleccionado = r;
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              if (repartidores.isNotEmpty)
                ElevatedButton(
                  onPressed: seleccionado != null
                      ? () async {
                          final repartidorNombre = seleccionado!.nombre;
                          // Capturamos el contexto del diálogo para validarlo tras el gap async
                          final dialogContext = context;

                          try {
                            final result = await _repository.asignarPedido(
                              pedido.id,
                              seleccionado!.id,
                            );

                            if (!mounted || !dialogContext.mounted) {
                              return;
                            }

                            if (result.success) {
                              Navigator.of(dialogContext).pop();
                              NotificationService.showSuccess(
                                'Repartidor $repartidorNombre asignado exitosamente',
                                context: dialogContext,
                              );
                              await _loadPedidos();
                            } else {
                              NotificationService.showError(
                                'Error: ${result.error}',
                                context: dialogContext,
                              );
                            }
                          } catch (e) {
                            if (!mounted || !dialogContext.mounted) {
                              return;
                            }
                            NotificationService.showError(
                              'Error al asignar: $e',
                              context: dialogContext,
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedRushTheme.primaryGreen,
                    foregroundColor: MedRushTheme.textInverse,
                  ),
                  child: const Text('Confirmar Asignación'),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      logError('Error al cargar repartidores', e);
      if (mounted) {
        NotificationService.showError(
          'Error al cargar repartidores: $e',
          context: context,
        );
      }
    }
  }

  Widget _buildRepartidorAvatar(Usuario r) {
    final hasPhoto = r.foto != null && r.foto!.isNotEmpty;

    if (hasPhoto) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(r.foto!),
        backgroundColor: MedRushTheme.backgroundSecondary,
      );
    } else {
      // Fallback a iniciales
      final iniciales = r.nombre
          .split(' ')
          .take(2)
          .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
          .join();

      return CircleAvatar(
        radius: 16,
        backgroundColor: MedRushTheme.primaryGreen,
        child: Text(
          iniciales,
          style: const TextStyle(
            color: MedRushTheme.textInverse,
            fontSize: 12,
            fontWeight: MedRushTheme.fontWeightBold,
          ),
        ),
      );
    }
  }

  /// Muestra la pantalla de impresión de códigos de barras
  void _mostrarPantallaImpresion() {
    logInfo('Abriendo pantalla de etiquetas de envío');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PedidosPrintScreen(),
      ),
    );
  }

  /// Muestra el diálogo para cancelar un pedido
  Future<void> _showCancelarPedidoDialog(Pedido pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.x,
              color: Colors.orange,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Cancelar Pedido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas cancelar el pedido #${pedido.id}?',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: MedRushTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Esta acción cambiará el estado del pedido a "Cancelado" y no se podrá revertir.',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelarPedido(pedido);
    }
  }

  /// Cancela un pedido
  Future<void> _cancelarPedido(Pedido pedido) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Cancelar pedido usando el repositorio
      final result = await _repository.cancelarPedido(pedido.id);

      // Cerrar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          NotificationService.showSuccess(
            'Pedido #${pedido.id} cancelado exitosamente',
            context: context,
          );
        }

        // Recargar la lista
        await _loadPedidos();
      } else {
        // Mostrar mensaje de error
        if (mounted) {
          NotificationService.showError(
            'Error al cancelar pedido: ${result.error}',
            context: context,
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      if (mounted) {
        NotificationService.showError(
          'Error al cancelar pedido: $e',
          context: context,
        );
      }
    }
  }

  /// Muestra el diálogo para marcar un pedido como fallido
  Future<void> _showMarcarFalloDialog(Pedido pedido) async {
    MotivoFalla? motivoSeleccionado;
    final TextEditingController observacionesController =
        TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                LucideIcons.badgeAlert,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: MedRushTheme.spacingSm),
              Text('Marcar como Fallido'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el motivo del fallo para el pedido #${pedido.id}',
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingMd),

                // Selector de motivo de fallo
                DropdownButtonFormField<MotivoFalla>(
                  initialValue: motivoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del fallo',
                    border: OutlineInputBorder(),
                  ),
                  items: StatusHelpers.obtenerMotivosFallo().map((motivo) {
                    return DropdownMenuItem<MotivoFalla>(
                      value: motivo,
                      child: Row(
                        children: [
                          Icon(
                            StatusHelpers.motivoFallaIcono(motivo),
                            color: StatusHelpers.motivoFallaColor(motivo),
                            size: 16,
                          ),
                          const SizedBox(width: MedRushTheme.spacingXs),
                          Text(StatusHelpers.motivoFallaTexto(motivo)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (MotivoFalla? value) {
                    setState(() {
                      motivoSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: MedRushTheme.spacingMd),

                // Campo de observaciones
                TextFormField(
                  controller: observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Detalles adicionales sobre el fallo...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: MedRushTheme.spacingMd),

                Container(
                  padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: MedRushTheme.spacingSm),
                      Expanded(
                        child: Text(
                          'Esta acción cambiará el estado del pedido a "Fallido" y registrará la ubicación actual.',
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: motivoSeleccionado != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar Fallo'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && motivoSeleccionado != null) {
      await _marcarPedidoFallido(
        pedido,
        motivoSeleccionado!,
        observacionesController.text.trim(),
      );
    }
  }

  /// Marca un pedido como fallido
  Future<void> _marcarPedidoFallido(
    Pedido pedido,
    MotivoFalla motivo,
    String observaciones,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener ubicación actual (simulada por ahora)
      // FIX: Implementar obtención real de ubicación GPS
      const double latitud = 26.037737; // EEUU
      const double longitud = -80.179550;

      // Marcar como fallido usando el repositorio
      final result = await _repository.marcarPedidoFallido(
        pedido.id,
        motivoFallo: StatusHelpers.motivoFallaToBackend(motivo),
        observacionesFallo: observaciones.isNotEmpty ? observaciones : null,
        latitud: latitud,
        longitud: longitud,
      );

      // Cerrar indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          NotificationService.showSuccess(
            'Pedido #${pedido.id} marcado como fallido',
            context: context,
          );
        }

        // Recargar la lista
        await _loadPedidos();
      } else {
        // Mostrar mensaje de error
        if (mounted) {
          NotificationService.showError(
            'Error al marcar pedido como fallido: ${result.error}',
            context: context,
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      if (mounted) {
        NotificationService.showError(
          'Error al marcar pedido como fallido: $e',
          context: context,
        );
      }
    }
  }
}

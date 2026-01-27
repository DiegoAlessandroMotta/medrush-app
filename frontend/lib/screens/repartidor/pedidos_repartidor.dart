import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/pagination.model.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/screens/repartidor/entregar_repartidor.dart';
import 'package:medrush/screens/repartidor/modules/pedidos/pedidos_detalle_repartidor.dart';
import 'package:medrush/screens/repartidor/widgets/grid_pedidos_infinite.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/debug_helpers.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/pagination_helper.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidosListScreen extends StatefulWidget {
  const PedidosListScreen({super.key});

  @override
  State<PedidosListScreen> createState() => _PedidosListScreenState();
}

class _PedidosListScreenState extends State<PedidosListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;
  final PedidoRepository _repository = PedidoRepository();

  // Helper de paginación
  final PaginationHelper<Pedido> _paginationHelper = PaginationHelper<Pedido>();

  bool _isLoading = true;
  String? _error;
  EstadoPedido? _filtroEstado;
  final bool _mostrarSoloPrioritarios = false;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setupScrollListener();
    _loadPedidos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Verificar que el widget esté montado y el controller tenga clients
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final scrollPosition = _scrollController.position.pixels;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;

      // Usar un threshold más grande para páginas con más items (50 items)
      // 400px es aproximadamente 3-4 cards antes del final
      final threshold = maxScrollExtent - 400;

      // Solo cargar más si:
      // 1. Hay más datos disponibles
      // 2. No está cargando actualmente
      // 3. No hay carga inicial en progreso
      // 4. El usuario ha scrolleado cerca del final
      if (_paginationHelper.hasMoreData &&
          !_paginationHelper.isLoadingMore &&
          !_isLoading &&
          scrollPosition >= threshold) {
        _loadMorePedidos();
      }
    });
  }

  Future<void> _loadPedidos({bool refresh = false}) async {
    if (!mounted) {
      logInfo('[LOAD_PEDIDOS] Widget no montado, cancelando...');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        if (refresh) {
          _paginationHelper.initialize();
        }
      });

      logInfo(
          '[LOAD_PEDIDOS] Cargando pedidos desde repositorio (página ${_paginationHelper.currentPage})');

      final result = await _obtenerPedidosActivos();

      if (!mounted) {
        logInfo('[LOAD_PEDIDOS] Widget desmontado durante la carga');
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);

        DebugHelpers.checkDuplicates(result.data!.items, 'DUPLICADOS');

        setState(() {
          _isLoading = false;
        });

        logInfo('[LOAD_PEDIDOS] ${_paginationHelper.getStatusInfo()}');
      } else {
        setState(() {
          _error = result.error ?? 'Error desconocido al cargar pedidos';
          _isLoading = false;
        });
        logError('[LOAD_PEDIDOS] Error al cargar pedidos: ${result.error}');
      }
    } catch (e) {
      logError('[LOAD_PEDIDOS] Error al cargar pedidos', e);
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Error al cargar los pedidos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePedidos() async {
    // Validaciones previas
    if (!mounted) {
      return;
    }

    if (!_scrollController.hasClients) {
      return;
    }

    // Verificar si se puede cargar más usando el helper
    if (!_paginationHelper.canLoadMore()) {
      return;
    }

    if (!_paginationHelper.canMakeRequest()) {
      return;
    }

    try {
      // Marcar como cargando
      _paginationHelper.setLoadingMore(loading: true);
      if (mounted) {
        setState(() {});
      }

      final nextPage = _paginationHelper.getNextPage();
      logInfo(
          '[LOAD_MORE] Cargando página $nextPage de ${_paginationHelper.totalPages}');

      // Obtener la siguiente página
      final result = await _obtenerPedidosActivos(page: nextPage);

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        // Verificar duplicados en la respuesta
        DebugHelpers.checkDuplicates(result.data!.items, 'DUPLICADOS');

        // Actualizar con la nueva página
        _paginationHelper.updateAdditionalPage(result.data!);

        if (mounted) {
          setState(() {});
        }

        logInfo(
            '[LOAD_MORE] Cargada exitosamente: ${_paginationHelper.getStatusInfo()}');
      } else {
        // Error al cargar
        _paginationHelper.setLoadingMore(loading: false);
        if (mounted) {
          setState(() {});
        }
        logError('[LOAD_MORE] Error: ${result.error}');
      }
    } catch (e) {
      logError('[LOAD_MORE] Excepción al cargar más pedidos', e);
      if (mounted) {
        _paginationHelper.setLoadingMore(loading: false);
        setState(() {});
      }
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await _loadPedidos(refresh: true);
  }

  /// Obtiene pedidos usando filtros del backend
  Future<RepositoryResult<PaginatedResponse<Pedido>>> _obtenerPedidosActivos(
      {int? page}) {
    final targetPage = page ?? _paginationHelper.currentPage;
    logInfo('[OBTENER_PEDIDOS] Solicitando página $targetPage');

    // Si hay un filtro específico, usarlo
    if (_filtroEstado != null) {
      logInfo('[OBTENER_PEDIDOS] Con filtro de estado: $_filtroEstado');
      return _repository.obtenerPaginados(
        page: targetPage,
        perPage: 50, // 50 pedidos por página
        estado: _filtroEstado,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );
    }

    // El backend soporta múltiples estados con el parámetro "estados"
    logInfo(
        '[OBTENER_PEDIDOS] Sin filtro específico, obteniendo pedidos activos del backend');

    return _repository.obtenerPaginados(
      page: targetPage,
      perPage: 50, // 50 pedidos por página
      estados: [
        EstadoPedido.asignado,
        EstadoPedido.recogido,
        EstadoPedido.enRuta,
      ],
      search: _searchTerm.isNotEmpty ? _searchTerm : null,
    );
  }

  /// Recarga los pedidos
  Future<void> _limpiarCacheYRecargar() async {
    try {
      logInfo('Recargando pedidos...');
    } catch (e) {
      logError('Error al recargar pedidos', e);
    }

    if (!mounted) {
      return;
    }

    await _loadPedidos(refresh: true);
  }

  List<Pedido> get _pedidosFiltrados {
    var filtered = _paginationHelper.items;

    // El backend ahora maneja estos filtros

    // Filtrar prioritarios si está activado
    if (_mostrarSoloPrioritarios) {
      filtered = filtered.where((p) => p.prioridad > 1).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(MedRushTheme.spacingLg),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        border: Border.all(color: MedRushTheme.borderLight),
        boxShadow: const [
          BoxShadow(
            color: MedRushTheme.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) async {
                setState(() {
                  _searchTerm = value;
                });
                await _limpiarCacheYRecargar();
              },
              decoration: const InputDecoration(
                filled: false,
                hintText: 'Buscar pedidos...',
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingMd),
            child: DropdownButton<EstadoPedido?>(
              value: _filtroEstado,
              underline: Container(),
              items: [
                const DropdownMenuItem<EstadoPedido?>(
                  child: Text('Filtrar'),
                ),
                // Solo incluir estados relevantes para repartidor
                ...EstadoPedido.values
                    .where((estado) =>
                        estado == EstadoPedido.asignado ||
                        estado == EstadoPedido.recogido ||
                        estado == EstadoPedido.enRuta)
                    .map((estado) => DropdownMenuItem<EstadoPedido?>(
                          value: estado,
                          child: Text(StatusHelpers.estadoPedidoTexto(estado)),
                        )),
              ],
              onChanged: (EstadoPedido? newValue) async {
                setState(() {
                  _filtroEstado = newValue;
                  // Actualizar el filtro de texto para mostrar
                });
                await _limpiarCacheYRecargar();
              },
            ),
          ),
        ],
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
                    IconButton(
                      icon: const Icon(
                        LucideIcons.phone,
                        color: MedRushTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Llamar',
                      onPressed: () => _llamarCliente(pedido),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.route,
                        color: MedRushTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Navegar',
                      onPressed: () => _abrirNavegacion(pedido),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    // Botón Entregar (solo si está en ruta)
                    if (pedido.estado == EstadoPedido.enRuta)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.packageOpen,
                          color: MedRushTheme.primaryBlue,
                          size: 20,
                        ),
                        tooltip: 'Entregar',
                        onPressed: () => _entregarPedido(pedido),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                  ],
                ),
              ],
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
                  onPressed: () => _verDetallePedido(pedido),
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
            'No tienes pedidos activos',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              color: MedRushTheme.textPrimary,
              fontWeight: MedRushTheme.fontWeightBold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los pedidos asignados, recogidos y en ruta aparecerán aquí',
            style: TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _verDetallePedido(Pedido pedido) {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PedidoDetalleScreen(pedidoId: pedido.id),
    );
  }

  void _entregarPedido(Pedido pedido) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EntregarRepartidorScreen(
          pedido: pedido,
        ),
      ),
    )
        .then((entregado) {
      if (entregado == true) {
        // Si se entregó exitosamente, recargar la lista
        _loadPedidos(refresh: true);
      }
    });
  }

  Future<void> _abrirNavegacion(Pedido pedido) async {
    final lat = pedido.latitudEntrega;
    final lng = pedido.longitudEntrega;
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        NotificationService.showError(
          'No se puede abrir navegación',
          context: context,
        );
      }
    }
  }

  Future<void> _llamarCliente(Pedido pedido) async {
    // TODO: Agregar teléfono del cliente cuando esté disponible en el backend
    final telefono = pedido.telefonoCliente ?? 'No disponible';

    if (telefono == 'No disponible') {
      if (mounted) {
        NotificationService.showError(
          'Teléfono del cliente no disponible',
          context: context,
        );
      }
      return;
    }

    final Uri uri = Uri.parse('tel:$telefono');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        NotificationService.showError(
          'No se puede realizar la llamada',
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

  Widget _buildResponsiveBody() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: GridPedidosInfinite(
            pedidos: _pedidosFiltrados,
            paginationHelper: _paginationHelper,
            scrollController: _scrollController,
            buildPedidoCard: _buildEntregaCard,
            onRefresh: _onRefresh,
            isLoading: _isLoading,
            error: _error,
            onRetry: _loadPedidos,
            emptyWidget: _buildEmptyState(),
          ),
        ),
      ],
    );
  }
}

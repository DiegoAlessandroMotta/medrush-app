import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/pagination.model.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/repositories/base.repository.dart';
import 'package:medrush/repositories/pedido.repository.dart';
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

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final PedidoRepository _repository = PedidoRepository();
  final PaginationHelper<Pedido> _paginationHelper = PaginationHelper<Pedido>();
  late ScrollController _scrollController;

  List<Pedido> _pedidosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Todos los estados';
  EstadoPedido? _filtroEstado;
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setupScrollListener();
    _loadHistorial();
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

      // Usar un threshold más grande para mejor UX (50 items por página)
      final threshold = maxScrollExtent - 400;

      // Solo cargar más si hay más datos disponibles y no está cargando
      if (_paginationHelper.hasMoreData &&
          !_paginationHelper.isLoadingMore &&
          !_isLoading &&
          scrollPosition >= threshold) {
        _loadMoreHistorial();
      }
    });
  }

  Future<void> _loadHistorial({bool refresh = false}) async {
    if (!mounted) {
      logInfo('[LOAD_HISTORIAL] Widget no montado, cancelando...');
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
          '[LOAD_HISTORIAL] Cargando historial desde repositorio (página ${_paginationHelper.currentPage})');

      final result = await _obtenerHistorialActivos();

      if (!mounted) {
        logInfo('[LOAD_HISTORIAL] Widget desmontado durante la carga');
        return;
      }

      if (result.success && result.data != null) {
        DebugHelpers.checkDuplicates(
            result.data!.items, 'DUPLICADOS_HISTORIAL');
        _paginationHelper.updateFirstPage(result.data!);
        setState(() {
          _pedidosFiltrados = result.data!.items;
          _isLoading = false;
        });
        logInfo('[LOAD_HISTORIAL] ${_paginationHelper.getStatusInfo()}');
      } else {
        setState(() {
          _error = result.error ?? AppLocalizations.of(context).errorLoadingHistory;
          _isLoading = false;
        });
        logError('[LOAD_HISTORIAL] Error al cargar historial: ${result.error}');
      }
    } catch (e) {
      logError('[LOAD_HISTORIAL] Error al cargar historial', e);

      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            AppLocalizations.of(context).errorLoadingHistoryWithError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreHistorial() async {
    // Validaciones previas
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    // Verificar si se puede cargar más usando el helper
    if (!_paginationHelper.canLoadMore() ||
        !_paginationHelper.canMakeRequest()) {
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
          '[LOAD_MORE_HISTORIAL] Cargando página $nextPage de ${_paginationHelper.totalPages}');

      // Obtener la siguiente página
      final result = await _obtenerHistorialActivos(page: nextPage);

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        // Verificar duplicados en la respuesta
        DebugHelpers.checkDuplicates(
            result.data!.items, 'DUPLICADOS_HISTORIAL');

        // Actualizar con la nueva página
        _paginationHelper.updateAdditionalPage(result.data!);

        if (mounted) {
          setState(() {
            _pedidosFiltrados = _paginationHelper.items;
          });
        }

        logInfo(
            '[LOAD_MORE_HISTORIAL] Cargada exitosamente: ${_paginationHelper.getStatusInfo()}');
      } else {
        // Error al cargar
        _paginationHelper.setLoadingMore(loading: false);
        if (mounted) {
          setState(() {});
        }
        logError('[LOAD_MORE_HISTORIAL] Error: ${result.error}');
      }
    } catch (e) {
      logError('[LOAD_MORE_HISTORIAL] Excepción al cargar más pedidos', e);
      if (mounted) {
        _paginationHelper.setLoadingMore(loading: false);
        setState(() {});
      }
    }
  }

  /// Obtiene solo pedidos del historial (entregado, cancelado, fallido)
  /// Ordena por updated_at (fecha de último cambio) para mostrar los más recientes primero
  Future<RepositoryResult<PaginatedResponse<Pedido>>> _obtenerHistorialActivos(
      {int? page}) {
    final targetPage = page ?? _paginationHelper.currentPage;
    logInfo('[OBTENER_HISTORIAL] Solicitando página $targetPage');

    // Si hay un filtro específico, usarlo
    if (_filtroEstado != null) {
      logInfo('[OBTENER_HISTORIAL] Con filtro de estado: $_filtroEstado');
      return _repository.obtenerPaginados(
        page: targetPage,
        perPage: 50, // 50 pedidos por página
        estado: _filtroEstado,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );
    }

    // Usar filtro múltiple de estados del historial
    logInfo('[OBTENER_HISTORIAL] Con filtro múltiple de estados del historial');
    return _repository.obtenerPaginados(
      page: targetPage,
      perPage: 50, // 50 pedidos por página
      estados: [
        EstadoPedido.entregado,
        EstadoPedido.cancelado,
        EstadoPedido.fallido
      ],
      search: _searchTerm.isNotEmpty ? _searchTerm : null,
    );
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await _loadHistorial(refresh: true);
  }

  void _verDetallePedido(Pedido pedido) {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PedidoDetalleScreen(pedidoId: pedido.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Barra de paginación
            _buildPaginationInfo(),

            // Filtro por estado
            _buildFilterBar(),

            // Contenido principal
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
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
                await _loadHistorial(refresh: true);
              },
              decoration: InputDecoration(
                filled: false,
                hintText: AppLocalizations.of(context).searchOrders,
                hintStyle: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: MedRushTheme.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
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
            child: DropdownButton<String>(
              value: _selectedFilter,
              underline: Container(),
              items: [
                DropdownMenuItem<String>(
                  value: 'Todos los estados',
                  child: Text(AppLocalizations.of(context).allStatuses),
                ),
                DropdownMenuItem<String>(
                  value: 'Entregados',
                  child: Text(AppLocalizations.of(context).filterDelivered),
                ),
                DropdownMenuItem<String>(
                  value: 'Cancelados',
                  child: Text(AppLocalizations.of(context).filterCancelled),
                ),
                DropdownMenuItem<String>(
                  value: 'Fallidos',
                  child: Text(AppLocalizations.of(context).filterFailed),
                ),
              ],
              onChanged: (String? newValue) async {
                setState(() {
                  _selectedFilter = newValue!;
                  // Actualizar el filtro de estado
                  switch (newValue) {
                    case 'Entregados':
                      _filtroEstado = EstadoPedido.entregado;
                    case 'Cancelados':
                      _filtroEstado = EstadoPedido.cancelado;
                    case 'Fallidos':
                      _filtroEstado = EstadoPedido.fallido;
                    default:
                      _filtroEstado = null;
                  }
                });
                // Recargar con el nuevo filtro
                await _loadHistorial(refresh: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return GridPedidosInfinite(
      pedidos: _pedidosFiltrados,
      paginationHelper: _paginationHelper,
      scrollController: _scrollController,
      buildPedidoCard: _buildHistorialCard,
      onRefresh: _onRefresh,
      isLoading: _isLoading,
      error: _error,
      onRetry: _loadHistorial,
      emptyWidget: _buildEmptyState(),
    );
  }

  Widget _buildHistorialCard(Pedido pedido) {
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
                      tooltip: AppLocalizations.of(context).call,
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
                      tooltip: AppLocalizations.of(context).navigate,
                      onPressed: () => _abrirNavegacion(pedido),
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
                        StatusHelpers.estadoPedidoTexto(pedido.estado, AppLocalizations.of(context)),
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

                // Fecha
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
                          .obtenerFechaRelativaSegunPrioridadOptimizada(pedido, AppLocalizations.of(context)),
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
                  child: Text(
                    AppLocalizations.of(context).viewDetails,
                    style: const TextStyle(
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
            LucideIcons.history,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          SizedBox(height: MedRushTheme.spacingLg),
          Text(
            'No hay historial disponible',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          SizedBox(height: MedRushTheme.spacingMd),
          Text(
            'Aún no tienes pedidos entregados, cancelados o fallidos',
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
          AppLocalizations.of(context).cannotOpenNavigation,
          context: context,
        );
      }
    }
  }

  Future<void> _llamarCliente(Pedido pedido) async {
    final telefono = pedido.telefonoCliente ??
        AppLocalizations.of(context).notAvailable;

    if (telefono == AppLocalizations.of(context).notAvailable) {
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).clientPhoneNotAvailable,
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
          AppLocalizations.of(context).cannotMakeCall,
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
          AppLocalizations.of(context).infoCopied,
          context: context,
        );
      }

      logInfo(
          'Información del cliente copiada: ${pedido.pacienteNombre} - ${pedido.id}');
    } catch (e) {
      logError('Error al copiar información del cliente', e);
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorCopyingInfo,
          context: context,
        );
      }
    }
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
}

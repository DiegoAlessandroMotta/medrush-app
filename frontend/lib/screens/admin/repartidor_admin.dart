import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/repartidor.repository.dart';
import 'package:medrush/screens/admin/modules/repartidor/repartidor_detalles.dart';
import 'package:medrush/screens/admin/modules/repartidor/repartidor_form.dart';
import 'package:medrush/screens/admin/modules/repartidor/repartidor_list.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RepartidorRepository _repo = RepartidorRepository();

  List<Usuario> _repartidores = [];
  List<Usuario> _repartidoresFiltrados = [];
  bool _isLoading = true;
  String? _error;
  EstadoRepartidor? _filtroEstado;
  Timer? _autoRefreshTimer;
  bool _expandInactivos = false;
  bool _isTableView =
      true; // FIX: Controlar vista de tabla vs tarjetas - se ajusta según dispositivo

  @override
  void initState() {
    super.initState();
    _loadRepartidores();
    _searchController.addListener(_filterRepartidores);
    // Auto refresco cada 2 minutos
    _autoRefreshTimer =
        Timer.periodic(const Duration(minutes: 2), (_) => _loadRepartidores());

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
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRepartidores() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      logInfo('Cargando repartidores en UI de administración');

      // Los repositorios gestionan su propio caché
      final result = await _repo.getAllRepartidores();

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        setState(() {
          _repartidores = result.data!;
          _repartidoresFiltrados = result.data!;
          _isLoading = false;
        });
        logInfo('${result.data!.length} repartidores cargados en la UI');
      } else {
        setState(() {
          _error = result.error ?? 'No se pudo cargar la lista de repartidores';
          _isLoading = false;
        });
      }
    } catch (e) {
      logError('Error al cargar repartidores en la UI', e);
      setState(() {
        _error = 'Error al cargar repartidores: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      logInfo('🔄 Refreshing datos de repartidores - limpiando cache');

      // FIX: Cache deshabilitado - métodos de limpieza eliminados

      // Recargar datos
      await _loadRepartidores();

      logInfo('✅ Refresh completado - cache limpiado y datos recargados');
    } catch (e) {
      logError('Error durante refresh de repartidores', e);
    }
  }

  void _filterRepartidores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _repartidoresFiltrados = _repartidores.where((repartidor) {
        final matchesSearch = query.isEmpty ||
            repartidor.nombre.toLowerCase().contains(query) ||
            repartidor.email.toLowerCase().contains(query) ||
            (repartidor.telefono?.toLowerCase().contains(query) ?? false) ||
            (repartidor.vehiculoPlaca?.toLowerCase().contains(query) ?? false);

        final matchesEstado = _filtroEstado == null ||
            repartidor.estadoRepartidor == _filtroEstado;

        return matchesSearch && matchesEstado;
      }).toList();
    });
  }

  void _showRepartidorForm({Usuario? repartidor}) {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => RepartidorForm(
        initialData: repartidor,
        onSave: (nuevoRepartidor) {
          Navigator.of(context).pop();
          _loadRepartidores();
          NotificationService.showSuccess(
              repartidor == null
                  ? 'Repartidor creado exitosamente'
                  : 'Repartidor actualizado exitosamente',
              context: context);
        },
        onImageUpdated: () {
          // Refrescar la lista cuando se actualiza una imagen
          logInfo('📸 Imagen actualizada - refrescando lista de repartidores');
          _loadRepartidores();
        },
      ),
    );
  }

  void _showRepartidorDetalles(Usuario repartidor) {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => RepartidorDetalles(
        repartidor: repartidor,
        onEdit: () {
          Navigator.of(context).pop();
          _showRepartidorForm(repartidor: repartidor);
        },
        onDelete: () => _deleteRepartidor(repartidor),
      ),
    );
  }

  Future<void> _deleteRepartidor(Usuario repartidor) async {
    try {
      logInfo('Eliminando repartidor: ${repartidor.nombre}');
      final result = await _repo.deleteRepartidor(repartidor.id);
      if (!result.success) {
        throw Exception(result.error ?? 'No se pudo eliminar el repartidor');
      }

      _loadRepartidores(); // Recargar la lista

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo de detalles
        NotificationService.showSuccess(
            'Repartidor "${repartidor.nombre}" eliminado exitosamente',
            context: context);
      }
    } catch (e) {
      logError('Error al eliminar repartidor', e);
      if (mounted) {
        NotificationService.showError('Error al eliminar repartidor: $e',
            context: context);
      }
    }
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
        child: _buildResponsiveBody(isDesktop, isTablet, isMobile),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottom),
        child: FloatingActionButton(
          heroTag: 'fab_add_repartidor',
          onPressed: _showRepartidorForm,
          backgroundColor: MedRushTheme.primaryGreen,
          child: const Icon(LucideIcons.plus),
        ),
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

  Widget _buildListLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildRepartidoresList(),
        ),
      ],
    );
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
        ],
      ),
    );
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
              decoration: const InputDecoration(
                filled: false,
                hintText: 'Buscar repartidores...',
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

        // Filtro de estado (centro)
        Container(
          margin: const EdgeInsets.only(right: MedRushTheme.spacingMd),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<EstadoRepartidor?>(
              value: _filtroEstado,
              padding: const EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingMd),
              dropdownColor: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
              items: [
                const DropdownMenuItem<EstadoRepartidor?>(
                  child: Text('Todos los estados'),
                ),
                ...EstadoRepartidor.values.map((estado) {
                  return DropdownMenuItem<EstadoRepartidor?>(
                    value: estado,
                    child: Text(StatusHelpers.estadoRepartidorTexto(estado)),
                  );
                }),
              ],
              onChanged: (EstadoRepartidor? newValue) {
                setState(() {
                  _filtroEstado = newValue;
                });
                _filterRepartidores();
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

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_repartidoresFiltrados.isEmpty) {
      return _buildEmptyState();
    }

    // FIX: Mostrar vista de tabla o tarjetas según el toggle
    if (_isTableView) {
      return Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingMd),
        child: RepartidoresTableView(
          repartidores: _repartidoresFiltrados,
          onRefresh: _onRefresh,
          onEdit: (repartidor) => _showRepartidorForm(repartidor: repartidor),
          onView: _showRepartidorDetalles,
          onDelete: _deleteRepartidor,
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
        itemCount: _repartidoresFiltrados.length,
        itemBuilder: (context, index) {
          final repartidor = _repartidoresFiltrados[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
            child: _buildRepartidorCard(repartidor),
          );
        },
      ),
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
            'Error al cargar los repartidores',
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
            onPressed: _loadRepartidores,
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
              decoration: const InputDecoration(
                filled: false,
                hintText: 'Buscar repartidores...',
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
            child: DropdownButton<EstadoRepartidor?>(
              value: _filtroEstado,
              underline: Container(),
              hint: const Text('Estado'),
              dropdownColor: MedRushTheme.surface,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
              items: [
                const DropdownMenuItem<EstadoRepartidor?>(
                  child: Text('Todos los estados'),
                ),
                ...EstadoRepartidor.values.map((estado) {
                  return DropdownMenuItem<EstadoRepartidor?>(
                    value: estado,
                    child: Text(StatusHelpers.estadoRepartidorTexto(estado)),
                  );
                }),
              ],
              onChanged: (EstadoRepartidor? newValue) {
                setState(() {
                  _filtroEstado = newValue;
                });
                _filterRepartidores();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepartidoresList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRepartidores,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_repartidoresFiltrados.isEmpty) {
      return _buildEmptyState();
    }

    final activos = _repartidoresFiltrados.where((r) => r.activo).toList();
    final inactivos = _repartidoresFiltrados.where((r) => !r.activo).toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingLg),
        children: [
          // Activos primero
          ...activos.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
                child: _buildRepartidorCard(r),
              )),
          if (inactivos.isNotEmpty) ...[
            const SizedBox(height: MedRushTheme.spacingSm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusLg),
                border: Border.all(color: MedRushTheme.borderLight),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _expandInactivos,
                  onExpansionChanged: (v) =>
                      setState(() => _expandInactivos = v),
                  tilePadding: const EdgeInsets.symmetric(
                      horizontal: MedRushTheme.spacingLg),
                  childrenPadding: const EdgeInsets.fromLTRB(
                      MedRushTheme.spacingLg,
                      0,
                      MedRushTheme.spacingLg,
                      MedRushTheme.spacingLg),
                  title: Row(
                    children: [
                      const Icon(Icons.visibility_off,
                          color: MedRushTheme.textSecondary),
                      const SizedBox(width: MedRushTheme.spacingSm),
                      Text(
                        'Repartidores desactivados (${inactivos.length})',
                        style: const TextStyle(
                          color: MedRushTheme.textSecondary,
                          fontWeight: MedRushTheme.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    ...inactivos.map((r) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: MedRushTheme.spacingMd),
                          child: _buildRepartidorCard(r),
                        )),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: MedRushTheme.spacingLg),
        ],
      ),
    );
  }

  Widget _buildRepartidorCard(Usuario repartidor) {
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
            // Header con nombre del repartidor e iconos
            Row(
              children: [
                // Avatar del repartidor
                _buildRepartidorAvatar(repartidor),
                const SizedBox(width: MedRushTheme.spacingMd),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _copiarInformacionRepartidor(repartidor),
                    child: Text(
                      repartidor.nombre,
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
                        color: MedRushTheme.primaryGreen,
                        size: 20,
                      ),
                      tooltip: 'Llamar',
                      onPressed: () => _llamarRepartidor(repartidor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.pencil,
                        color: MedRushTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Editar',
                      onPressed: () =>
                          _showRepartidorForm(repartidor: repartidor),
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

            // Email del repartidor
            Text(
              repartidor.email,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textSecondary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingSm),

            // Información del teléfono
            if (repartidor.telefono != null)
              Row(
                children: [
                  const Icon(
                    LucideIcons.phone,
                    size: 14,
                    color: MedRushTheme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    repartidor.telefono!,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            if (repartidor.telefono != null)
              const SizedBox(height: MedRushTheme.spacingXs),

            // Información del vehículo
            if (repartidor.vehiculoPlaca != null)
              Row(
                children: [
                  const Icon(
                    LucideIcons.car,
                    size: 14,
                    color: MedRushTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    repartidor.vehiculoPlaca!,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: MedRushTheme.spacingSm),

            // Fila inferior con estado, última actividad y botón
            Row(
              children: [
                // Estado del repartidor
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingSm,
                    vertical: MedRushTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: StatusHelpers.estadoRepartidorColor(
                        repartidor.estadoRepartidor ??
                            EstadoRepartidor.desconectado),
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        StatusHelpers.estadoRepartidorIcon(
                            repartidor.estadoRepartidor ??
                                EstadoRepartidor.desconectado),
                        size: 14,
                        color: MedRushTheme.textInverse,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        StatusHelpers.estadoRepartidorTexto(
                            repartidor.estadoRepartidor ??
                                EstadoRepartidor.desconectado),
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

                // Última actividad
                Row(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: MedRushTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatLastSeen(repartidor.updatedAt),
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
                  onPressed: () => _showRepartidorDetalles(repartidor),
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

  String _formatLastSeen(DateTime? last) {
    // ignore: always_put_control_body_on_new_line
    if (last == null) return 'sin actividad';
    final diff = DateTime.now().difference(last);
    if (diff.inMinutes < 1) {
      return 'justo ahora';
    }
    if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'hace ${diff.inHours} h';
    }
    return 'hace ${diff.inDays} d';
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(MedRushTheme.spacingLg),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.userSearch,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            _searchController.text.isNotEmpty || _filtroEstado != null
                ? 'No se encontraron repartidores con los filtros aplicados'
                : 'No hay repartidores registrados',
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: _showRepartidorForm,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Agregar Repartidor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepartidorAvatar(Usuario repartidor) {
    final String imageUrl = BaseApi.getImageUrl(repartidor.foto);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: MedRushTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Image.network(
                imageUrl,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarFallback(repartidor);
                },
              ),
            )
          : _buildAvatarFallback(repartidor),
    );
  }

  Widget _buildAvatarFallback(Usuario repartidor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.user,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(height: 2),
          Text(
            _getInitials(repartidor.nombre),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) {
      return '??';
    }
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _copiarInformacionRepartidor(Usuario repartidor) async {
    try {
      final informacion =
          'Repartidor: ${repartidor.nombre}\nEmail: ${repartidor.email}\nID: ${repartidor.id}';

      await Clipboard.setData(ClipboardData(text: informacion));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Información copiada al portapapeles'),
            backgroundColor: MedRushTheme.primaryGreen,
          ),
        );
      }

      logInfo(
          '📋 Información del repartidor copiada: ${repartidor.nombre} - ${repartidor.id}');
    } catch (e) {
      logError('❌ Error al copiar información del repartidor', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al copiar información'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _llamarRepartidor(Usuario repartidor) async {
    // Verificar si el repartidor tiene teléfono
    if (repartidor.telefono == null || repartidor.telefono!.isEmpty) {
      if (mounted) {
        NotificationService.showError(
          'Teléfono del repartidor no disponible',
          context: context,
        );
      }
      return;
    }

    try {
      final Uri uri = Uri.parse('tel:${repartidor.telefono}');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        logInfo(
            '📞 Llamando a repartidor: ${repartidor.nombre} - ${repartidor.telefono}');
      } else {
        if (mounted) {
          NotificationService.showError(
            'No se puede realizar la llamada',
            context: context,
          );
        }
      }
    } catch (e) {
      logError('❌ Error al llamar al repartidor', e);
      if (mounted) {
        NotificationService.showError(
          'Error al realizar la llamada',
          context: context,
        );
      }
    }
  }
}

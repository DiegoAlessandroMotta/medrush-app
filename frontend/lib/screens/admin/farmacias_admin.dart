import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_elastic_list_view/flutter_elastic_list_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/repositories/farmacia.repository.dart';
import 'package:medrush/screens/admin/modules/farmacias/farmacia_detalle.dart';
import 'package:medrush/screens/admin/modules/farmacias/farmacia_form.dart';
import 'package:medrush/screens/admin/modules/farmacias/farmacias_list.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/pagination_helper.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/pagination_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';

class FarmaciasListScreen extends StatefulWidget {
  const FarmaciasListScreen({super.key});

  @override
  State<FarmaciasListScreen> createState() => _FarmaciasListScreenState();
}

class _FarmaciasListScreenState extends State<FarmaciasListScreen> {
  final FarmaciaRepository _repository = FarmaciaRepository();
  final PaginationHelper<Farmacia> _paginationHelper =
      PaginationHelper<Farmacia>();
  final TextEditingController _searchController = TextEditingController();

  List<Farmacia> _farmaciasFiltradas = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Todos los estados';
  String _searchTerm = ''; // FIX: Agregar término de búsqueda
  String? _pendingSearch; // para debounce simple
  final int _searchDebounceMs = 300;
  bool _isTableView =
      true; // FIX: Controlar vista de tabla vs tarjetas - se ajusta según dispositivo

  // Acciones del menú compacto

  @override
  void initState() {
    super.initState();
    _loadFarmacias();

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

  Future<void> _loadFarmacias() async {
    if (!mounted) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _paginationHelper.initialize();
      });

      logInfo('Cargando farmacias desde el repositorio');

      // FIX: Usar query params para búsqueda y filtros
      final result = await _repository.obtenerPaginadas(
        search: _searchTerm.isNotEmpty
            ? _searchTerm
            : null, // FIX: Incluir búsqueda
        estado: _selectedFilter != 'Todos los estados'
            ? _estadoSlugFromLabel(_selectedFilter)
            : null, // FIX: Incluir filtro de estado
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);

        setState(() {
          _farmaciasFiltradas = result.data!.items;
          _isLoading = false;
        });

        logInfo(
            '${_farmaciasFiltradas.length} farmacias cargadas exitosamente');
      } else {
        setState(() {
          _error = result.error ??
            AppLocalizations.of(context).errorLoadingPharmaciesUnknown;
          _isLoading = false;
        });
        logError('Error al cargar farmacias: ${result.error}');
      }
    } catch (e) {
      logError('Error al cargar farmacias', e);

      if (!mounted) {
        return;
      }

      setState(() {
        _error = AppLocalizations.of(context).errorLoadingPharmacies;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await _loadFarmacias();
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

      final result = await _repository.obtenerPaginadas(
        page: page,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
        estado: _selectedFilter != 'Todos los estados'
            ? _estadoSlugFromLabel(_selectedFilter)
            : null,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);
        setState(() {
          _farmaciasFiltradas = result.data!.items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ??
              AppLocalizations.of(context).errorLoadingPharmaciesUnknown;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(context).errorLoadingPharmacies;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFarmaciasWithPerPage(int perPage) async {
    if (!mounted) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _paginationHelper.initialize();
      });

      final result = await _repository.obtenerPaginadas(
        perPage: perPage,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
        estado: _selectedFilter != 'Todos los estados'
            ? _estadoSlugFromLabel(_selectedFilter)
            : null,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        _paginationHelper.updateFirstPage(result.data!);
        setState(() {
          _farmaciasFiltradas = result.data!.items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ??
              AppLocalizations.of(context).errorLoadingPharmaciesUnknown;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(context).errorLoadingPharmacies;
        _isLoading = false;
      });
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
          heroTag: 'fab_add_farmacia',
          backgroundColor: MedRushTheme.primaryGreen,
          child: const Icon(LucideIcons.plus),
          onPressed: () {
            showMaterialModalBottomSheet(
              context: context,
              expand: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              builder: (context) => FarmaciaForm(
                onSave: (farmacia) async {
                  try {
                    logInfo(
                        'Farmacia guardada desde formulario: ${farmacia.nombre}');

                    // Recargar la lista completa para mostrar los cambios
                    await _loadFarmacias();

                    if (context.mounted) {
                      NotificationService.showSuccess(
                          AppLocalizations.of(context).pharmacySavedSuccess,
                          context: context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      logError(
                          AppLocalizations.of(context).errorReloadPharmacies, e);
                      NotificationService.showWarning(
                          AppLocalizations.of(context).pharmacySavedButErrorReload,
                          context: context);
                    }
                  }
                },
              ),
            );
          },
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
          child: _buildFarmaciasList(),
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
          const SizedBox(height: MedRushTheme.spacingMd),
          // Widget de paginación en la parte inferior
          if (_paginationHelper.totalPages > 1) _buildDesktopPagination(),
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
              onChanged: (value) async {
                setState(() {
                  _searchTerm = value;
                });
                await _loadFarmacias();
              },
              decoration: InputDecoration(
                filled: false,
                hintText: AppLocalizations.of(context).searchPharmacies,
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

        // Filtro de estado (centro)
        Container(
          margin: const EdgeInsets.only(right: MedRushTheme.spacingMd),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              padding: const EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingMd),
              dropdownColor: MedRushTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
              items: [
                'Todos los estados',
                'Activa',
                'Inactiva',
                'Suspendida',
                'En Revisión',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    _filterDisplayLabel(context, value),
                    style: const TextStyle(
                      color: MedRushTheme.textPrimary,
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) async {
                setState(() {
                  _selectedFilter = newValue!;
                });
                await _loadFarmacias();
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
    final itemsPerPage = 20; // 20 farmacias por página
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
        await _loadFarmaciasWithPerPage(perPage);
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_farmaciasFiltradas.isEmpty) {
      return _buildEmptyState();
    }

    // FIX: Mostrar vista de tabla o tarjetas según el toggle
    if (_isTableView) {
      return Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingMd),
        child: FarmaciasTableView(
          farmacias: _farmaciasFiltradas,
          onRefresh: _onRefresh,
          onEdit: (farmacia) => _showFarmaciaForm(farmacia: farmacia),
          onView: _showFarmaciaDetalles,
          onDelete: _deleteFarmacia,
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
        itemCount: _farmaciasFiltradas.length,
        itemBuilder: (context, index) {
          final farmacia = _farmaciasFiltradas[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
            child: _buildFarmaciaCard(farmacia),
          );
        },
      ),
    );
  }

  void _showFarmaciaForm({Farmacia? farmacia}) {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => FarmaciaForm(
        onSave: (farmacia) async {
          try {
            logInfo('Farmacia guardada desde formulario: ${farmacia.nombre}');

            // Recargar la lista completa para mostrar los cambios
            await _loadFarmacias();

            if (context.mounted) {
              NotificationService.showSuccess(
                  AppLocalizations.of(context).pharmacyUpdatedSuccess,
                  context: context);
            }
          } catch (e) {
            logError('Error al recargar farmacias después de guardar', e);
            if (context.mounted) {
              NotificationService.showWarning(
                  AppLocalizations.of(context).pharmacySavedButErrorReload,
                  context: context);
            }
          }
        },
        initialData: farmacia,
      ),
    );
  }

  void _showFarmaciaDetalles(Farmacia farmacia) {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => FarmaciaDetalleBottomSheet(farmacia: farmacia),
    );
  }

  Future<void> _deleteFarmacia(Farmacia farmacia) async {
    try {
      final repository = FarmaciaRepository();
      final result = await repository.eliminar(farmacia.id);

      if (result.success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          NotificationService.showSuccess(
            AppLocalizations.of(context).pharmacyDeletedSuccess(farmacia.nombre),
            context: context,
          );
        }

        // Recargar la lista
        await _loadFarmacias();
      } else {
        // Mostrar mensaje de error
        if (mounted) {
          NotificationService.showError(
            AppLocalizations.of(context).errorDeletePharmacy(result.error!),
            context: context,
          );
        }
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorDeletePharmacy(e),
          context: context,
        );
      }
    }
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
              decoration: InputDecoration(
                filled: false,
                hintText: AppLocalizations.of(context).searchPharmacies,
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
              onChanged: _filtrarFarmacias,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingMd),
            child: DropdownButton<String>(
              value: _selectedFilter,
              underline: Container(),
              dropdownColor: MedRushTheme.surface,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
              items: [
                'Todos los estados',
                'Activa',
                'Inactiva',
                'Suspendida',
                'En Revisión',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(_filterDisplayLabel(context, value)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
                _filtrarFarmacias(_searchController.text);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmaciasList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_farmaciasFiltradas.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ElasticListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: MedRushTheme.spacingLg),
        itemCount: _farmaciasFiltradas.length,
        itemBuilder: (context, index) {
          final farmacia = _farmaciasFiltradas[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
            child: _buildFarmaciaCard(farmacia),
          );
        },
      ),
    );
  }

  Widget _buildFarmaciaCard(Farmacia farmacia) {
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
            // Header con nombre de la farmacia e iconos
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _copiarInformacionFarmacia(farmacia),
                    child: Text(
                      farmacia.nombre,
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
                        LucideIcons.eye,
                        color: MedRushTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: AppLocalizations.of(context).view,
                      onPressed: () {
                        showMaterialModalBottomSheet(
                          context: context,
                          expand: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              FarmaciaDetalleBottomSheet(farmacia: farmacia),
                        );
                      },
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
                      tooltip: AppLocalizations.of(context).edit,
                      onPressed: () {
                        showMaterialModalBottomSheet(
                          context: context,
                          expand: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FarmaciaForm(
                            onSave: (farmacia) async {
                              try {
                                logInfo(
                                    'Farmacia actualizada desde formulario: ${farmacia.nombre}');
                                // Recargar la lista para mostrar los cambios
                                await _loadFarmacias();

                                if (!context.mounted) {
                                  return;
                                }
                                if (mounted) {
                                  NotificationService.showSuccess(
                                      AppLocalizations.of(context)
                                          .pharmacyUpdatedSuccess,
                                      context: context);
                                }
                              } catch (e) {
                                logError(
                                    AppLocalizations.of(context)
                                        .errorReloadPharmacies,
                                    e);
                                if (!context.mounted) {
                                  return;
                                }
                                if (mounted) {
                                  NotificationService.showWarning(
                                      AppLocalizations.of(context)
                                          .pharmacySavedButErrorReload,
                                      context: context);
                                }
                              }
                            },
                            initialData: farmacia,
                          ),
                        );
                      },
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

            // Dirección de la farmacia
            Text(
              farmacia.direccion,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textSecondary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingSm),

            // Información del responsable
            if (farmacia.contactoResponsable != null)
              Row(
                children: [
                  const Icon(
                    LucideIcons.user,
                    size: 14,
                    color: MedRushTheme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      farmacia.contactoResponsable!,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (farmacia.contactoResponsable != null)
              const SizedBox(height: MedRushTheme.spacingXs),

            // Teléfono
            if (farmacia.telefono != null)
              Row(
                children: [
                  const Icon(
                    LucideIcons.phone,
                    size: 14,
                    color: MedRushTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    farmacia.telefono!,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: MedRushTheme.spacingSm),

            // Fila inferior con estado y botón
            Row(
              children: [
                // Estado de la farmacia
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingSm,
                    vertical: MedRushTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: StatusHelpers.estadoFarmaciaColor(farmacia.estado),
                    borderRadius:
                        BorderRadius.circular(MedRushTheme.borderRadiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.building2,
                        size: 14,
                        color: MedRushTheme.textInverse,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        StatusHelpers.estadoFarmaciaTexto(farmacia.estado, AppLocalizations.of(context)),
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeBodySmall,
                          color: MedRushTheme.textInverse,
                          fontWeight: MedRushTheme.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Botón Ver Detalles
                ElevatedButton(
                  onPressed: () {
                    showMaterialModalBottomSheet(
                      context: context,
                      expand: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          FarmaciaDetalleBottomSheet(farmacia: farmacia),
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
            LucideIcons.building2,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            AppLocalizations.of(context).noPharmaciesFound,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyLarge,
              color: MedRushTheme.textSecondary,
            ),
          ),
        ],
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
          Text(
            AppLocalizations.of(context).errorLoadingPharmaciesUnknown,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: _loadFarmacias,
            icon: const Icon(LucideIcons.refreshCw),
            label: Text(AppLocalizations.of(context).retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: MedRushTheme.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  void _filtrarFarmacias(String query) {
    // Debounce: ejecutar búsqueda tras breve espera y solo si no hay cambios
    _pendingSearch = query;
    setState(() {
      _searchTerm = query;
    });
    Future.delayed(Duration(milliseconds: _searchDebounceMs), () {
      if (!mounted) {
        return;
      }
      if (_pendingSearch == query) {
        _loadFarmacias();
      }
    });
  }

  String? _estadoSlugFromLabel(String label) {
    switch (label) {
      case 'Activa':
        return 'activa';
      case 'Inactiva':
        return 'inactiva';
      case 'Suspendida':
        return 'suspendida';
      case 'En Revisión':
        return 'en_revision';
      default:
        return null;
    }
  }

  String _filterDisplayLabel(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'Todos los estados':
        return l10n.allStatuses;
      case 'Activa':
        return l10n.active;
      case 'Inactiva':
        return l10n.inactive;
      case 'Suspendida':
        return l10n.suspended;
      case 'En Revisión':
        return l10n.inReview;
      default:
        return value;
    }
  }

  Future<void> _copiarInformacionFarmacia(Farmacia farmacia) async {
    try {
      final l10n = AppLocalizations.of(context);
      final informacion =
          '${l10n.pharmacy}: ${farmacia.nombre}\n${l10n.address}: ${farmacia.direccion}\n${l10n.idLabel}${farmacia.id}';

      await Clipboard.setData(ClipboardData(text: informacion));

      if (mounted) {
        NotificationService.showSuccess(
          AppLocalizations.of(context).infoCopied,
          context: context,
        );
      }

      logInfo(
          'Información de la farmacia copiada: ${farmacia.nombre} - ${farmacia.id}');
    } catch (e) {
      logError('Error al copiar información de la farmacia', e);
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorCopyingInfo,
          context: context,
        );
      }
    }
  }
}

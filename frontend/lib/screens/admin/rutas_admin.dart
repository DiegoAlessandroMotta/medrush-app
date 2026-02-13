import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/ruta_optimizada.model.dart';
import 'package:medrush/repositories/ruta.repository.dart';
import 'package:medrush/screens/admin/modules/rutas/repartidor_detalle_ruta.dart';
import 'package:medrush/screens/admin/modules/rutas/ruta_detalle.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:medrush/widgets/mapa_ruta_compacto_widget.dart';
import 'package:medrush/widgets/mapa_ruta_completa_widget.dart';

class RutasAdminScreen extends StatefulWidget {
  const RutasAdminScreen({super.key});

  @override
  State<RutasAdminScreen> createState() => _RutasAdminScreenState();
}

class _RutasAdminScreenState extends State<RutasAdminScreen> {
  List<RutaOptimizada> _rutas = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Timer? _refreshTimer;
  String _filtroEstado = 'todos';
  String _filtroRepartidor = 'todos';
  String? _rutaExpandida; // FIX: Para manejar qué ruta está expandida
  final Map<String, List<Map<String, dynamic>>> _pedidosPorRuta =
      {}; // FIX: Cache de pedidos por ruta
  final RutaRepository _rutaRepository = RutaRepository();

  @override
  void initState() {
    super.initState();
    _cargarRutas();
    _iniciarRefreshAutomatico();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _iniciarRefreshAutomatico() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _cargarRutas(silent: true);
      }
    });
  }

  Future<void> _cargarRutas({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      // Usar RutaRepository para obtener datos según el filtro activo
      final result = await _cargarRutasSegunFiltro();

      if (mounted) {
        setState(() {
          _rutas = result;
          _isLoading = false;
          _isRefreshing = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<List<RutaOptimizada>> _cargarRutasSegunFiltro() async {
    if (_filtroEstado == 'activas') {
      // Solo obtener rutas activas
      final result = await _rutaRepository.obtenerActivas();
      if (result.success) {
        return result.data ?? [];
      } else {
        throw Exception(result.error ?? 'Error al obtener rutas activas');
      }
    } else if (_filtroRepartidor != 'todos') {
      // Obtener rutas de un repartidor específico
      final result =
          await _rutaRepository.obtenerPorRepartidor(_filtroRepartidor);
      if (result.success) {
        return result.data ?? [];
      } else {
        throw Exception(
            result.error ?? 'Error al obtener rutas del repartidor');
      }
    } else {
      // Obtener todas las rutas con paginación
      final result = await _rutaRepository.obtenerTodas();
      if (result.success) {
        return result.data ?? [];
      } else {
        throw Exception(result.error ?? 'Error al obtener todas las rutas');
      }
    }
  }

  List<RutaOptimizada> _getRutasFiltradas() {
    var rutasFiltradas = _rutas;

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      switch (_filtroEstado) {
        case 'activas':
          rutasFiltradas =
              rutasFiltradas.where((r) => r.fechaCompletado == null).toList();
        case 'completadas':
          rutasFiltradas =
              rutasFiltradas.where((r) => r.fechaCompletado != null).toList();
      }
    }

    // Filtrar por repartidor
    if (_filtroRepartidor != 'todos') {
      rutasFiltradas = rutasFiltradas
          .where((r) => r.repartidor?['id'] == _filtroRepartidor)
          .toList();
    }

    return rutasFiltradas;
  }

  List<String> _getRepartidoresUnicos() {
    final repartidores = <String>[];
    for (final ruta in _rutas) {
      if (ruta.repartidor != null && ruta.repartidor!['id'] != null) {
        final repartidorId = ruta.repartidor!['id'] as String;
        if (!repartidores.contains(repartidorId)) {
          repartidores.add(repartidorId);
        }
      }
    }
    return repartidores;
  }

  String _getRepartidorNombre(String repartidorId) {
    final ruta = _rutas.firstWhere(
      (r) => r.repartidor?['id'] == repartidorId,
      orElse: () =>
          _rutas.isNotEmpty ? _rutas.first : const RutaOptimizada(id: ''),
    );
    return ruta.repartidor?['nombre']?.toString() ?? 'Repartidor Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    final double fabBottom = MediaQuery.of(context).padding.bottom + 8;

    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _buildContenido(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottom),
        child: _buildFloatingActionButtons(),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      decoration: const BoxDecoration(
        color: MedRushTheme.surface,
        border: Border(
          bottom: BorderSide(
            color: MedRushTheme.borderLight,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // FIX: En pantallas pequeñas, apilar verticalmente
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                _buildDropdownFiltro(
                  'Estado',
                  _filtroEstado,
                  {
                    'todos': 'Todas las rutas',
                    'activas': 'Rutas activas',
                    'completadas': 'Rutas completadas',
                  },
                  (value) async {
                    setState(() {
                      _filtroEstado = value!;
                    });
                    await _cargarRutas();
                  },
                ),
                const SizedBox(height: MedRushTheme.spacingMd),
                _buildDropdownFiltro(
                  'Repartidor',
                  _filtroRepartidor,
                  {
                    'todos': 'Todos los repartidores',
                    ...Map.fromEntries(
                      _getRepartidoresUnicos().map(
                        (id) => MapEntry(id, _getRepartidorNombre(id)),
                      ),
                    ),
                  },
                  (value) async {
                    setState(() {
                      _filtroRepartidor = value!;
                    });
                    await _cargarRutas();
                  },
                ),
              ],
            );
          } else {
            // FIX: En pantallas grandes, mantener horizontal
            return Row(
              children: [
                Expanded(
                  child: _buildDropdownFiltro(
                    'Estado',
                    _filtroEstado,
                    {
                      'todos': 'Todas las rutas',
                      'activas': 'Rutas activas',
                      'completadas': 'Rutas completadas',
                    },
                    (value) async {
                      setState(() {
                        _filtroEstado = value!;
                      });
                      await _cargarRutas();
                    },
                  ),
                ),
                const SizedBox(width: MedRushTheme.spacingMd),
                Expanded(
                  child: _buildDropdownFiltro(
                    'Repartidor',
                    _filtroRepartidor,
                    {
                      'todos': 'Todos los repartidores',
                      ...Map.fromEntries(
                        _getRepartidoresUnicos().map(
                          (id) => MapEntry(id, _getRepartidorNombre(id)),
                        ),
                      ),
                    },
                    (value) async {
                      setState(() {
                        _filtroRepartidor = value!;
                      });
                      await _cargarRutas();
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildDropdownFiltro(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            fontWeight: MedRushTheme.fontWeightMedium,
            color: MedRushTheme.textSecondary,
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingXs),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              borderSide: const BorderSide(color: MedRushTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
              borderSide: const BorderSide(color: MedRushTheme.primaryGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MedRushTheme.spacingMd,
              vertical: MedRushTheme.spacingSm,
            ),
          ),
          items: items.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                      color: MedRushTheme.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                MedRushTheme.primaryGreen,
              ),
            ),
            SizedBox(height: MedRushTheme.spacingLg),
            Text(
              'Cargando rutas...',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.x,
              size: 64,
              color: MedRushTheme.error,
            ),
            const SizedBox(height: MedRushTheme.spacingLg),
            const Text(
              'Error al cargar las rutas',
              style: TextStyle(
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
              onPressed: _cargarRutas,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MedRushTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final rutasFiltradas = _getRutasFiltradas();

    if (rutasFiltradas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.map,
              size: 64,
              color: MedRushTheme.textSecondary,
            ),
            SizedBox(height: MedRushTheme.spacingLg),
            Text(
              'No hay rutas disponibles',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeTitleLarge,
                fontWeight: MedRushTheme.fontWeightBold,
                color: MedRushTheme.textPrimary,
              ),
            ),
            SizedBox(height: MedRushTheme.spacingMd),
            Text(
              'No se encontraron rutas con los filtros aplicados',
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

    return RefreshIndicator(
      onRefresh: _cargarRutas,
      color: MedRushTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(MedRushTheme.spacingMd),
        itemCount: rutasFiltradas.length,
        itemBuilder: (context, index) {
          final ruta = rutasFiltradas[index];
          return _buildRutaCard(ruta);
        },
      ),
    );
  }

  Widget _buildRutaCard(RutaOptimizada ruta) {
    final esActiva = ruta.fechaCompletado == null;
    final repartidorNombre =
        ruta.repartidor?['nombre']?.toString() ?? 'Repartidor Desconocido';

    return Card(
      margin: const EdgeInsets.only(bottom: MedRushTheme.spacingMd),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
      ),
      child: InkWell(
        onTap: () => _toggleRutaExpansion(ruta.id),
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.all(MedRushTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(MedRushTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: esActiva
                          ? MedRushTheme.primaryGreen.withValues(alpha: 0.1)
                          : MedRushTheme.textSecondary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusMd),
                    ),
                    child: Icon(
                      esActiva ? LucideIcons.truck : LucideIcons.check,
                      color: esActiva
                          ? MedRushTheme.primaryGreen
                          : MedRushTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: MedRushTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ruta.nombre ?? 'Ruta sin nombre',
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeTitleMedium,
                            fontWeight: MedRushTheme.fontWeightBold,
                            color: MedRushTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: MedRushTheme.spacingXs),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Repartidor: $repartidorNombre',
                                style: const TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodyMedium,
                                  color: MedRushTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (ruta.repartidor?['verificado'] == true) ...[
                              const SizedBox(width: MedRushTheme.spacingXs),
                              const Icon(
                                LucideIcons.shield,
                                size: 14,
                                color: MedRushTheme.success,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // FIX: Usar Column en pantallas pequeñas para evitar overflow
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 300) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: MedRushTheme.spacingSm,
                                vertical: MedRushTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: esActiva
                                    ? MedRushTheme.primaryGreen
                                        .withValues(alpha: 0.1)
                                    : MedRushTheme.textSecondary
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    MedRushTheme.borderRadiusSm),
                              ),
                              child: Text(
                                esActiva ? 'Activa' : 'Completada',
                                style: TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodySmall,
                                  fontWeight: MedRushTheme.fontWeightMedium,
                                  color: esActiva
                                      ? MedRushTheme.primaryGreen
                                      : MedRushTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: MedRushTheme.spacingXs),
                            Icon(
                              _rutaExpandida == ruta.id
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 16,
                              color: MedRushTheme.textSecondary,
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: MedRushTheme.spacingSm,
                                vertical: MedRushTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: esActiva
                                    ? MedRushTheme.primaryGreen
                                        .withValues(alpha: 0.1)
                                    : MedRushTheme.textSecondary
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    MedRushTheme.borderRadiusSm),
                              ),
                              child: Text(
                                esActiva ? 'Activa' : 'Completada',
                                style: TextStyle(
                                  fontSize: MedRushTheme.fontSizeBodySmall,
                                  fontWeight: MedRushTheme.fontWeightMedium,
                                  color: esActiva
                                      ? MedRushTheme.primaryGreen
                                      : MedRushTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: MedRushTheme.spacingXs),
                            Icon(
                              _rutaExpandida == ruta.id
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 16,
                              color: MedRushTheme.textSecondary,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: MedRushTheme.spacingMd),
              // FIX: Usar Wrap para evitar overflow en pantallas pequeñas
              Wrap(
                spacing: MedRushTheme.spacingSm,
                runSpacing: MedRushTheme.spacingXs,
                children: [
                  if (ruta.distanciaTotalEstimada != null)
                    _buildInfoItem(
                      LucideIcons.mapPin,
                      StatusHelpers.formatearDistanciaKm(
                          ruta.distanciaTotalEstimada!),
                    ),
                  if (ruta.tiempoTotalEstimado != null)
                    _buildInfoItem(
                      LucideIcons.clock,
                      StatusHelpers.formatearTiempo(ruta.tiempoTotalEstimado!),
                    ),
                  _buildInfoItem(
                    LucideIcons.package,
                    '${ruta.cantidadPedidos ?? 0} pedidos',
                  ),
                ],
              ),

              // Información geográfica si está disponible
              if (ruta.puntoInicio != null || ruta.puntoFinal != null) ...[
                const SizedBox(height: MedRushTheme.spacingSm),
                // FIX: Usar Wrap para evitar overflow en coordenadas largas
                Wrap(
                  spacing: MedRushTheme.spacingSm,
                  runSpacing: MedRushTheme.spacingXs,
                  children: [
                    if (ruta.puntoInicio != null)
                      _buildInfoItem(
                        LucideIcons.mapPin,
                        'Inicio: ${(ruta.puntoInicio!['latitude'] != null && ruta.puntoInicio!['longitude'] != null) ? StatusHelpers.formatearCoordenadasEstandar((ruta.puntoInicio!['latitude'] as num).toDouble(), (ruta.puntoInicio!['longitude'] as num).toDouble()) : 'N/A'}',
                      ),
                    if (ruta.puntoFinal != null)
                      _buildInfoItem(
                        LucideIcons.flag,
                        'Final: ${(ruta.puntoFinal!['latitude'] != null && ruta.puntoFinal!['longitude'] != null) ? StatusHelpers.formatearCoordenadasEstandar((ruta.puntoFinal!['latitude'] as num).toDouble(), (ruta.puntoFinal!['longitude'] as num).toDouble()) : 'N/A'}',
                      ),
                  ],
                ),
              ],
              // Información adicional de fechas
              if (ruta.fechaHoraCalculo != null ||
                  ruta.fechaInicio != null) ...[
                const SizedBox(height: MedRushTheme.spacingMd),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: MedRushTheme.textSecondary,
                    ),
                    const SizedBox(width: MedRushTheme.spacingXs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ruta.fechaHoraCalculo != null)
                            Text(
                              'Calculada: ${StatusHelpers.formatearFechaCompleta(ruta.fechaHoraCalculo!)}',
                              style: const TextStyle(
                                fontSize: MedRushTheme.fontSizeBodySmall,
                                color: MedRushTheme.textSecondary,
                              ),
                            ),
                          if (ruta.fechaInicio != null)
                            Text(
                              'Iniciada: ${StatusHelpers.formatearFechaCompleta(ruta.fechaInicio!)}',
                              style: const TextStyle(
                                fontSize: MedRushTheme.fontSizeBodySmall,
                                color: MedRushTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // FIX: Dropdown expandible con progreso y acciones
              if (_rutaExpandida == ruta.id) ...[
                const SizedBox(height: MedRushTheme.spacingMd),
                _buildRutaExpansion(ruta),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedRushTheme.spacingSm,
        vertical: MedRushTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(width: MedRushTheme.spacingXs),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                color: MedRushTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // FIX: FloatingActionButtons para reemplazar los botones del AppBar
  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de optimizar rutas
        FloatingActionButton.small(
          heroTag: 'fab_optimizar_rutas',
          onPressed: _optimizarRutas,
          backgroundColor: MedRushTheme.warning,
          child: const Icon(
            LucideIcons.route,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingSm),

        // Botón de refresh
        FloatingActionButton(
          heroTag: 'fab_refresh_rutas',
          onPressed: _cargarRutas,
          backgroundColor: MedRushTheme.primaryGreen,
          child: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  LucideIcons.refreshCw,
                  color: Colors.white,
                ),
        ),
      ],
    );
  }

  /// FIX: Toggle para expandir/contraer ruta
  Future<void> _toggleRutaExpansion(String rutaId) async {
    setState(() {
      _rutaExpandida = _rutaExpandida == rutaId ? null : rutaId;
    });

    // FIX: Cargar pedidos si se está expandiendo y no están en cache
    if (_rutaExpandida == rutaId && ! _pedidosPorRuta.containsKey(rutaId)) {
      await _cargarPedidosRuta(rutaId);
    }
  }

  /// FIX: Cargar pedidos de una ruta específica
  Future<void> _cargarPedidosRuta(String rutaId) async {
    try {
      final result = await _rutaRepository.obtenerPedidosRuta(rutaId: rutaId);

      if (result.success && mounted) {
        setState(() {
          _pedidosPorRuta[rutaId] = result.data ?? [];
        });
      } else if (mounted) {
        _mostrarError(result.error ?? 'Error al cargar pedidos de la ruta');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar pedidos de la ruta: ${e.toString()}');
      }
    }
  }

  /// FIX: Refrescar pedidos de una ruta específica (para el botón de actualizar)
  Future<void> _refrescarPedidosRuta(String rutaId) async {
    try {
      final result = await _rutaRepository.obtenerPedidosRuta(rutaId: rutaId);

      if (result.success && mounted) {
        setState(() {
          _pedidosPorRuta[rutaId] = result.data ?? [];
        });
        _mostrarExito('Progreso actualizado exitosamente');
      } else if (mounted) {
        _mostrarError(result.error ?? 'Error al actualizar progreso');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al actualizar progreso: ${e.toString()}');
      }
    }
  }

  /// FIX: Construir el contenido expandible de la ruta
  Widget _buildRutaExpansion(RutaOptimizada ruta) {
    final tienePedidosCargados = _pedidosPorRuta.containsKey(ruta.id);

    return Container(
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Mostrar loading si no se han cargado los pedidos
          if (!tienePedidosCargados) ...[
            const Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        MedRushTheme.primaryGreen,
                      ),
                    ),
                  ),
                  SizedBox(height: MedRushTheme.spacingSm),
                  Text(
                    'Cargando pedidos...',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Progreso de la ruta
            _buildProgresoRuta(ruta),

            const SizedBox(height: MedRushTheme.spacingMd),

            // Layout de dos paneles: Lista de paradas y Mapa
            LayoutBuilder(
              builder: (context, constraints) {
                // En pantallas pequeñas, apilar verticalmente
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      // Lista de paradas
                      _buildListaParadas(ruta),
                      const SizedBox(height: MedRushTheme.spacingMd),
                      // Mapa compacto
                      _buildMapaIntegrado(ruta),
                    ],
                  );
                } else {
                  // En pantallas grandes, dos columnas
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel izquierdo: Lista de paradas
                      Expanded(
                        child: _buildListaParadas(ruta),
                      ),
                      const SizedBox(width: MedRushTheme.spacingMd),
                      // Panel derecho: Mapa
                      Expanded(
                        child: _buildMapaIntegrado(ruta),
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: MedRushTheme.spacingMd),

            // Botón de acciones
            _buildAccionesRuta(ruta),
          ],
        ],
      ),
    );
  }

  /// FIX: Construir el progreso de la ruta
  Widget _buildProgresoRuta(RutaOptimizada ruta) {
    // FIX: Usar pedidos cargados desde la API
    final pedidos = _pedidosPorRuta[ruta.id] ?? [];
    final totalPedidos = pedidos.length;
    final pedidosEntregados = pedidos
        .where((p) => p['estado'] == 'entregado' || p['estado'] == 'completado')
        .length;

    final porcentaje =
        totalPedidos > 0 ? (pedidosEntregados / totalPedidos * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progreso de la Ruta',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                fontWeight: MedRushTheme.fontWeightBold,
                color: MedRushTheme.textPrimary,
              ),
            ),
            Text(
              StatusHelpers.formatearPorcentaje(porcentaje),
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                fontWeight: MedRushTheme.fontWeightBold,
                color: porcentaje >= 100
                    ? MedRushTheme.success
                    : MedRushTheme.primaryGreen,
              ),
            ),
          ],
        ),

        const SizedBox(height: MedRushTheme.spacingSm),

        // Barra de progreso
        LinearProgressIndicator(
          value: porcentaje / 100,
          backgroundColor: MedRushTheme.borderLight,
          valueColor: AlwaysStoppedAnimation<Color>(
            porcentaje >= 100
                ? MedRushTheme.success
                : MedRushTheme.primaryGreen,
          ),
          minHeight: 8,
        ),

        const SizedBox(height: MedRushTheme.spacingXs),

        // Información detallada
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$pedidosEntregados de $totalPedidos pedidos entregados',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                color: MedRushTheme.textSecondary,
              ),
            ),
            if (ruta.fechaCompletado != null)
              Text(
                'Completada: ${StatusHelpers.formatearFechaCompleta(ruta.fechaCompletado!)}',
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  color: MedRushTheme.success,
                  fontWeight: MedRushTheme.fontWeightMedium,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Construir la lista de paradas (stops)
  Widget _buildListaParadas(RutaOptimizada ruta) {
    final pedidos = _pedidosPorRuta[ruta.id] ?? [];

    if (pedidos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(MedRushTheme.spacingLg),
          child: Text(
            'No hay paradas disponibles',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    // Ordenar pedidos por orden de entrega
    final pedidosOrdenados = List<Map<String, dynamic>>.from(pedidos)
    ..sort((a, b) {
      final ordenA = _obtenerOrdenPedido(a);
      final ordenB = _obtenerOrdenPedido(b);
      return ordenA.compareTo(ordenB);
    });

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paradas de la Ruta',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              fontWeight: MedRushTheme.fontWeightBold,
              color: MedRushTheme.textPrimary,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pedidosOrdenados.length,
              itemBuilder: (context, index) {
                final pedido = pedidosOrdenados[index];
                final orden = _obtenerOrdenPedido(pedido);
                return _buildParadaItem(pedido, orden);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construir un item de parada individual
  Widget _buildParadaItem(Map<String, dynamic> pedido, int orden) {
    final estado = pedido['estado'] as String? ?? 'pendiente';
    final estadoColor = _getEstadoColorPedido(estado);
    final estadoTexto = _getEstadoTextoPedido(estado);
    final nombreCliente = pedido['paciente_nombre']?.toString() ?? 'Cliente';
    final direccion =
        pedido['direccion_entrega_linea_1']?.toString() ?? 'Sin dirección';

    // Obtener fecha/hora de entrega si está disponible
    String? horaEntrega;
    if (pedido['fecha_entrega'] != null) {
      try {
        final fecha = DateTime.parse(pedido['fecha_entrega']);
        horaEntrega =
            '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        // Ignorar error de parsing
      }
    }

    final esEntregado = estado == 'entregado' || estado == 'completado';
    final esEnTransito = estado == 'en_ruta' || estado == 'asignado';

    return Container(
      margin: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
      padding: const EdgeInsets.all(MedRushTheme.spacingSm),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(
          color: esEntregado
              ? MedRushTheme.success.withValues(alpha: 0.3)
              : MedRushTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Número de parada
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: estadoColor,
              borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
            ),
            child: Center(
              child: Text(
                '$orden',
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: MedRushTheme.spacingSm),
          // Información de la parada
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Parada $orden: $nombreCliente',
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                          fontWeight: MedRushTheme.fontWeightBold,
                          color: MedRushTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esEntregado)
                      const Icon(
                        LucideIcons.check,
                        size: 16,
                        color: MedRushTheme.success,
                      )
                    else if (esEnTransito)
                      const Icon(
                        LucideIcons.truck,
                        size: 16,
                        color: MedRushTheme.primaryGreen,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  direccion,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (horaEntrega != null || estadoTexto != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (horaEntrega != null) ...[
                        Text(
                          horaEntrega,
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            fontWeight: MedRushTheme.fontWeightMedium,
                            color: esEntregado
                                ? MedRushTheme.success
                                : MedRushTheme.textSecondary,
                          ),
                        ),
                        if (estadoTexto != null)
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              color: MedRushTheme.textSecondary,
                            ),
                          ),
                      ],
                      if (estadoTexto != null)
                        Text(
                          estadoTexto,
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: estadoColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir el mapa integrado
  Widget _buildMapaIntegrado(RutaOptimizada ruta) {
    final pedidos = _pedidosPorRuta[ruta.id] ?? [];

    // Obtener ubicación del repartidor (simulada por ahora)
    LatLng? ubicacionRepartidor;
    if (ruta.puntoInicio != null) {
      final lat = ruta.puntoInicio!['latitude'] as num?;
      final lng = ruta.puntoInicio!['longitude'] as num?;
      if (lat != null && lng != null) {
        ubicacionRepartidor = LatLng(lat.toDouble(), lng.toDouble());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista del Mapa',
          style: TextStyle(
            fontSize: MedRushTheme.fontSizeBodyMedium,
            fontWeight: MedRushTheme.fontWeightBold,
            color: MedRushTheme.textPrimary,
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingSm),
        MapaRutaCompactoWidget(
          ruta: ruta,
          pedidos: pedidos,
          ubicacionRepartidor: ubicacionRepartidor,
        ),
      ],
    );
  }

  /// Obtener orden del pedido
  int _obtenerOrdenPedido(Map<String, dynamic> pedido) {
    final entregas = pedido['entregas'] as Map<String, dynamic>?;
    if (entregas != null) {
      return entregas['orden_personalizado'] as int? ??
          entregas['orden_optimizado'] as int? ??
          1;
    }
    return 1;
  }

  /// Obtener color del estado del pedido
  Color _getEstadoColorPedido(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
      case 'completado':
        return MedRushTheme.success;
      case 'en_ruta':
        return MedRushTheme.primaryGreen;
      case 'asignado':
        return MedRushTheme.primaryBlue;
      case 'pendiente':
        return MedRushTheme.statusPending;
      case 'cancelado':
        return MedRushTheme.statusCancelled;
      case 'fallido':
        return MedRushTheme.statusFailed;
      default:
        return MedRushTheme.textSecondary;
    }
  }

  /// Obtener texto del estado del pedido
  String? _getEstadoTextoPedido(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado':
      case 'completado':
        return 'Entregado';
      case 'en_ruta':
        return 'En Tránsito';
      case 'asignado':
        return 'Asignado';
      case 'pendiente':
        return 'Pendiente';
      case 'cancelado':
        return 'Cancelado';
      case 'fallido':
        return 'Fallido';
      default:
        return null;
    }
  }

  /// FIX: Construir las acciones de la ruta
  Widget _buildAccionesRuta(RutaOptimizada ruta) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDetallesRuta(ruta),
                icon: const Icon(LucideIcons.eye, size: 16),
                label: const Text('Ver Detalles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedRushTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingMd,
                    vertical: MedRushTheme.spacingSm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDetallesRepartidor(ruta),
                icon: const Icon(LucideIcons.user, size: 16),
                label: const Text('Ver Repartidor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedRushTheme.secondaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingMd,
                    vertical: MedRushTheme.spacingSm,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MedRushTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarMapaRuta(ruta),
                icon: const Icon(LucideIcons.map, size: 16),
                label: const Text('Ver Mapa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedRushTheme.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingMd,
                    vertical: MedRushTheme.spacingSm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: MedRushTheme.spacingSm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _refrescarPedidosRuta(ruta.id),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Actualizar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MedRushTheme.primaryGreen,
                  side: const BorderSide(color: MedRushTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(
                    horizontal: MedRushTheme.spacingMd,
                    vertical: MedRushTheme.spacingSm,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: MedRushTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        ),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: MedRushTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        ),
      ),
    );
  }

  Future<void> _optimizarRutas() async {
    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Optimizar Rutas'),
        content: const Text(
          '¿Estás seguro de que quieres optimizar todas las rutas? Este proceso puede tomar varios minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Optimizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                MedRushTheme.primaryGreen,
              ),
            ),
            SizedBox(height: MedRushTheme.spacingMd),
            Text(
              'Optimizando rutas...',
              style: TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Llamar a la API de optimización
      final result = await _rutaRepository.optimizarRutas(
        codigoIsoPais: 'PE', // FIX: Usar PE para coincidir con la data de prueba en Lima
        inicioJornada: DateTime.now().toIso8601String(),
        finJornada:
            DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
      );

      if (!result.success) {
        throw Exception(result.error ?? 'Error al optimizar rutas');
      }

      final resultado = result.data!;

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (resultado['status'] == 'success') {
          _mostrarExito('Rutas optimizadas exitosamente');
          // Recargar la lista de rutas
          _cargarRutas();
        } else {
          _mostrarError(
              'Error al optimizar rutas: ${resultado['message'] ?? 'Error desconocido'}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _mostrarError('Error al optimizar rutas: ${e.toString()}');
      }
    }
  }

  Future<void> _mostrarDetallesRuta(RutaOptimizada ruta) async {
    // Mostrar loading mientras se obtienen los detalles completos
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            MedRushTheme.primaryGreen,
          ),
        ),
      ),
    );

    try {
      // Obtener detalles completos de la ruta y sus pedidos usando el método optimizado
      final result = await _rutaRepository.obtenerRutaConPedidos(
        rutaId: ruta.id,
      );

      final rutaCompleta =
          result.success ? (result.data?['ruta'] as RutaOptimizada?) : null;
      final pedidosDetallados = result.success
          ? (result.data?['pedidos'] as List<Map<String, dynamic>>? ?? [])
          : <Map<String, dynamic>>[];

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (result.success && rutaCompleta != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RutaDetalleModal(
              ruta: rutaCompleta,
              pedidosDetallados: pedidosDetallados.cast<Map<String, dynamic>>(),
            ),
          );
        } else {
          _mostrarError(
              result.error ?? 'No se pudieron cargar los detalles de la ruta');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _mostrarError('Error al cargar detalles: ${e.toString()}');
      }
    }
  }

  /// FIX: Mostrar detalles del repartidor usando el modal separado
  Future<void> _mostrarDetallesRepartidor(RutaOptimizada ruta) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RepartidorDetalleRutaModal(ruta: ruta),
    );
  }

  /// Mostrar mapa completo de la ruta con ubicación del repartidor y pedidos
  Future<void> _mostrarMapaRuta(RutaOptimizada ruta) async {
    // Mostrar loading mientras se obtienen los datos completos
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            MedRushTheme.primaryGreen,
          ),
        ),
      ),
    );

    try {
      // Obtener pedidos de la ruta
      final result = await _rutaRepository.obtenerPedidosRuta(rutaId: ruta.id);

      if (!result.success) {
        throw Exception(result.error ?? 'Error al cargar pedidos de la ruta');
      }

      final pedidos = result.data ?? [];

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        // Obtener ubicación del repartidor (simulada por ahora)
        // TODO: Implementar obtención real de ubicación del repartidor
        LatLng? ubicacionRepartidor;
        if (ruta.puntoInicio != null) {
          final lat = ruta.puntoInicio!['latitude'] as num?;
          final lng = ruta.puntoInicio!['longitude'] as num?;
          if (lat != null && lng != null) {
            ubicacionRepartidor = LatLng(lat.toDouble(), lng.toDouble());
          }
        }

        // Navegar al mapa completo
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MapaRutaCompletaWidget(
              ruta: ruta,
              pedidos: pedidos,
              ubicacionRepartidor: ubicacionRepartidor,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _mostrarError('Error al cargar el mapa: ${e.toString()}');
      }
    }
  }
}

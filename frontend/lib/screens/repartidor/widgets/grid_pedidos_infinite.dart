import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/pagination_helper.dart';
import 'package:shimmer/shimmer.dart';

/// Widget reutilizable para mostrar una lista de pedidos con paginación infinita
class GridPedidosInfinite extends StatelessWidget {
  /// Lista de pedidos a mostrar
  final List<Pedido> pedidos;

  /// Helper de paginación para manejar el estado
  final PaginationHelper<Pedido> paginationHelper;

  /// ScrollController para detectar cuando cargar más
  final ScrollController scrollController;

  /// Callback para construir cada card de pedido
  final Widget Function(Pedido pedido) buildPedidoCard;

  /// Callback para refrescar la lista
  final Future<void> Function() onRefresh;

  /// Si está cargando la primera página
  final bool isLoading;

  /// Mensaje de error si hay alguno
  final String? error;

  /// Callback para reintentar en caso de error
  final VoidCallback? onRetry;

  /// Widget personalizado para el estado vacío
  final Widget? emptyWidget;

  /// Padding adicional en la parte inferior (para bottom navigation, etc)
  final double bottomPadding;

  const GridPedidosInfinite({
    super.key,
    required this.pedidos,
    required this.paginationHelper,
    required this.scrollController,
    required this.buildPedidoCard,
    required this.onRefresh,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.emptyWidget,
    this.bottomPadding = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    // Estado de carga inicial
    if (isLoading) {
      return _buildShimmerLoading();
    }

    // Estado de error
    if (error != null) {
      return _buildErrorState(context);
    }

    // Estado vacío
    if (pedidos.isEmpty) {
      return emptyWidget ?? _buildDefaultEmptyState();
    }

    // Lista con paginación infinita
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          MedRushTheme.spacingLg,
          0,
          MedRushTheme.spacingLg,
          MedRushTheme.spacingLg + bottomPadding,
        ),
        itemCount: pedidos.length + (paginationHelper.hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // Mostrar indicador de carga al final
          if (index == pedidos.length) {
            return _buildLoadMoreIndicator();
          }

          final pedido = pedidos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: MedRushTheme.spacingXs),
            child: buildPedidoCard(pedido),
          );
        },
      ),
    );
  }

  /// Shimmer de carga para la primera página
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

  /// Estado de error
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(height: MedRushTheme.spacingLg),
          Text(
            error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }

  /// Estado vacío por defecto
  Widget _buildDefaultEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.inbox,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          SizedBox(height: MedRushTheme.spacingLg),
          Text(
            'No hay pedidos',
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              color: MedRushTheme.textPrimary,
              fontWeight: MedRushTheme.fontWeightBold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los pedidos aparecerán aquí',
            style: TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Indicador de carga al final de la lista
  Widget _buildLoadMoreIndicator() {
    // Si no hay más datos, mostrar mensaje de completado
    if (!paginationHelper.hasMoreData) {
      return Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingLg),
        child: Center(
          child: Column(
            children: [
              const Icon(
                LucideIcons.check,
                color: MedRushTheme.primaryGreen,
                size: 32,
              ),
              const SizedBox(height: MedRushTheme.spacingSm),
              const Text(
                'Todos los pedidos cargados',
                style: TextStyle(
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                  fontWeight: MedRushTheme.fontWeightMedium,
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingXs),
              Text(
                '${paginationHelper.items.length} de ${paginationHelper.totalItems} pedidos',
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si está cargando, mostrar indicador de carga
    if (paginationHelper.isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(MedRushTheme.spacingLg),
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: MedRushTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingMd),
              Text(
                'Cargando página ${paginationHelper.currentPage + 1} de ${paginationHelper.totalPages}...',
                style: const TextStyle(
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
              ),
              const SizedBox(height: MedRushTheme.spacingXs),
              Text(
                '${paginationHelper.items.length} de ${paginationHelper.totalItems} pedidos cargados',
                style: const TextStyle(
                  color: MedRushTheme.textSecondary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si hay más datos pero no está cargando, no mostrar nada
    // El scroll trigger automáticamente cargará más
    return const SizedBox.shrink();
  }
}

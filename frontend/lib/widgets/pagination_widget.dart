import 'package:flutter/material.dart';
import 'package:medrush/theme/theme.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final int currentPageStart;
  final int currentPageEnd;
  final Function(int) onPageChanged;
  final Function(int)? onItemsPerPageChanged;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.currentPageStart,
    required this.currentPageEnd,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Información de resultados (izquierda)
        _buildResultsInfo(),

        // Espacio flexible para centrar la paginación
        Expanded(
          child: Center(
            child: _buildPageNavigation(),
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón anterior
        _buildNavigationButton(
          icon: Icons.chevron_left,
          onPressed:
              currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),

        const SizedBox(width: MedRushTheme.spacingXs),

        // Números de página
        ..._buildPageNumbers(),

        const SizedBox(width: MedRushTheme.spacingXs),

        // Botón siguiente
        _buildNavigationButton(
          icon: Icons.chevron_right,
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];

    if (totalPages <= 7) {
      // Si hay 7 páginas o menos, mostrar todas
      for (int i = 1; i <= totalPages; i++) {
        if (i > 1) {
          pageButtons.add(const SizedBox(width: MedRushTheme.spacingXs));
        }
        pageButtons.add(_buildPageButton(i));
      }
    } else {
      // Lógica inteligente para mostrar páginas con elipsis
      // Siempre mostrar página 1
      pageButtons.add(_buildPageButton(1));

      if (currentPage <= 4) {
        // Caso: página actual está cerca del inicio (1, 2, 3, 4)
        // Mostrar: 1, 2, 3, 4, 5, ..., última
        for (int i = 2; i <= 5; i++) {
          pageButtons
            ..add(const SizedBox(width: MedRushTheme.spacingXs))
            ..add(_buildPageButton(i));
        }
        pageButtons
          ..add(const SizedBox(width: MedRushTheme.spacingXs))
          ..add(_buildEllipsisButton())
          ..add(const SizedBox(width: MedRushTheme.spacingXs))
          ..add(_buildPageButton(totalPages));
      } else if (currentPage >= totalPages - 3) {
        // Caso: página actual está cerca del final
        // Mostrar: 1, ..., última-4, última-3, última-2, última-1, última
        pageButtons
          ..add(const SizedBox(width: MedRushTheme.spacingXs))
          ..add(_buildEllipsisButton());
        for (int i = totalPages - 4; i <= totalPages; i++) {
          pageButtons
            ..add(const SizedBox(width: MedRushTheme.spacingXs))
            ..add(_buildPageButton(i));
        }
      } else {
        // Caso: página actual está en el medio
        // Mostrar: 1, ..., actual-1, actual, actual+1, ..., última
        pageButtons
          ..add(const SizedBox(width: MedRushTheme.spacingXs))
          ..add(_buildEllipsisButton());

        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          pageButtons
            ..add(const SizedBox(width: MedRushTheme.spacingXs))
            ..add(_buildPageButton(i));
        }

        pageButtons
          ..add(const SizedBox(width: MedRushTheme.spacingXs))
          ..add(_buildEllipsisButton())
          ..add(const SizedBox(width: MedRushTheme.spacingXs))
          ..add(_buildPageButton(totalPages));
      }
    }

    return pageButtons;
  }

  Widget _buildPageButton(int pageNumber) {
    final isActive = pageNumber == currentPage;

    return GestureDetector(
      onTap: () => onPageChanged(pageNumber),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? MedRushTheme.primaryGreen : MedRushTheme.surface,
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
          border: Border.all(
            color:
                isActive ? MedRushTheme.primaryGreen : MedRushTheme.borderLight,
          ),
        ),
        child: Center(
          child: Text(
            pageNumber.toString(),
            style: TextStyle(
              color: isActive
                  ? MedRushTheme.textInverse
                  : MedRushTheme.textPrimary,
              fontSize: MedRushTheme.fontSizeBodySmall,
              fontWeight: isActive
                  ? MedRushTheme.fontWeightBold
                  : MedRushTheme.fontWeightMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
      {required IconData icon, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: MedRushTheme.surface,
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
          border: Border.all(
            color: onPressed != null
                ? MedRushTheme.borderLight
                : MedRushTheme.borderLight.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: onPressed != null
                ? MedRushTheme.textPrimary
                : MedRushTheme.textSecondary,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsisButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        border: Border.all(
          color: MedRushTheme.borderLight,
        ),
      ),
      child: const Center(
        child: Text(
          '...',
          style: TextStyle(
            color: MedRushTheme.textPrimary,
            fontSize: MedRushTheme.fontSizeBodySmall,
            fontWeight: MedRushTheme.fontWeightMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsInfo() {
    return Text(
      'Resultados: $currentPageStart - $currentPageEnd de $totalItems',
      style: const TextStyle(
        color: MedRushTheme.textSecondary,
        fontSize: MedRushTheme.fontSizeBodySmall,
        fontWeight: MedRushTheme.fontWeightMedium,
      ),
    );
  }
}

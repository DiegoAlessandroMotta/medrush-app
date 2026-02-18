import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:medrush/theme/theme.dart';

class CsvDataPreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> csvData;
  final Widget Function(String header, String value, int rowIndex) cellBuilder;
  final String Function(String header) formatHeaderText;
  final double rowHeight;
  final double columnWidth;
  final int maxRowsToShow;

  const CsvDataPreviewTable({
    super.key,
    required this.csvData,
    required this.cellBuilder,
    required this.formatHeaderText,
    this.rowHeight = 56.0,
    this.columnWidth = 200.0,
    this.maxRowsToShow = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (csvData.isEmpty) {
      return const SizedBox.shrink();
    }

    final headers = csvData.first.keys.toList();

    // Crear columnas para TableView
    final columns = headers
        .map((header) => TableColumn(
              width: columnWidth,
            ))
        .toList();

    return TableView.builder(
      columns: columns,
      rowCount: csvData.length > maxRowsToShow ? maxRowsToShow : csvData.length,
      rowHeight: rowHeight,
      style: const TableViewStyle(
        dividers: TableViewDividersStyle(
          vertical: TableViewVerticalDividersStyle.symmetric(
            TableViewVerticalDividerStyle(
              color: MedRushTheme.borderLight,
            ),
          ),
          horizontal: TableViewHorizontalDividersStyle.symmetric(
            TableViewHorizontalDividerStyle(
              color: MedRushTheme.borderLight,
            ),
          ),
        ),
        scrollbars: TableViewScrollbarsStyle.symmetric(
          TableViewScrollbarStyle(
            interactive: true,
            enabled: TableViewScrollbarEnabled.always,
            thumbVisibility: WidgetStatePropertyAll(true),
            trackVisibility: WidgetStatePropertyAll(true),
          ),
        ),
      ),
      headerBuilder: (context, contentBuilder) => contentBuilder(
        context,
        (context, column) => Container(
          height: rowHeight,
          decoration: const BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            border: Border(
              bottom: BorderSide(
                color: MedRushTheme.borderLight,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                formatHeaderText(headers[column]),
                style: const TextStyle(
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
      headerHeight: rowHeight,
      rowBuilder: (context, row, contentBuilder) {
        final rowData = csvData[row];
        final isEven = row % 2 == 0;

        return Container(
          height: rowHeight,
          color: isEven ? MedRushTheme.surface : MedRushTheme.backgroundPrimary,
          child: contentBuilder(
            context,
            (context, column) {
              final header = headers[column];
              final value = rowData[header]?.toString() ?? '';
              return cellBuilder(header, value, row);
            },
          ),
        );
      },
    );
  }
}

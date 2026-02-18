import 'package:flutter/material.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/theme/theme.dart';

class CsvValidationStatus extends StatelessWidget {
  final int totalRows;
  final int validRows;

  const CsvValidationStatus({
    super.key,
    required this.totalRows,
    required this.validRows,
  });

  @override
  Widget build(BuildContext context) {
    if (totalRows == 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isComplete = validRows == totalRows;

    return Container(
      margin: const EdgeInsets.all(MedRushTheme.spacingLg),
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.validationProgressTitle,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodyLarge,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MedRushTheme.spacingMd,
                  vertical: MedRushTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: MedRushTheme.primaryGreen,
                  borderRadius:
                      BorderRadius.circular(MedRushTheme.borderRadiusMd),
                ),
                child: Text(
                  l10n.recordsValidCount(totalRows, validRows),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    fontWeight: MedRushTheme.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingMd),
          LinearProgressIndicator(
            value: totalRows > 0 ? validRows / totalRows : 0,
            backgroundColor: MedRushTheme.backgroundSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? MedRushTheme.primaryGreen : MedRushTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          Text(
            isComplete
                ? l10n.allRecordsHaveValidCoordinates
                : l10n.recordsNeedValidCoordinates(totalRows - validRows),
            style: TextStyle(
              fontSize: MedRushTheme.fontSizeBodySmall,
              color: isComplete
                  ? MedRushTheme.primaryGreen
                  : MedRushTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/theme/theme.dart';

class CsvUploadZone extends StatelessWidget {
  final VoidCallback onTap;

  const CsvUploadZone({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: MedRushTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusLg),
          border: Border.all(
            color: MedRushTheme.borderLight,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: MedRushTheme.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingXl),
              decoration: BoxDecoration(
                color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.upload,
                size: 100,
                color: MedRushTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingXl),
            Text(
              AppLocalizations.of(context).dragDropCsvHere,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeTitleLarge,
                fontWeight: MedRushTheme.fontWeightBold,
                color: MedRushTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Text(
              AppLocalizations.of(context).orClickToSelectFile,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyLarge,
                color: MedRushTheme.primaryGreen,
                fontWeight: MedRushTheme.fontWeightMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MedRushTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingMd),
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
                border: Border.all(color: MedRushTheme.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 16,
                        color: MedRushTheme.textSecondary,
                      ),
                      const SizedBox(width: MedRushTheme.spacingXs),
                      Text(
                        AppLocalizations.of(context).fileInfoTitle,
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                          fontWeight: MedRushTheme.fontWeightMedium,
                          color: MedRushTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                  Text(
                    AppLocalizations.of(context).fileSizeFormatHint,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

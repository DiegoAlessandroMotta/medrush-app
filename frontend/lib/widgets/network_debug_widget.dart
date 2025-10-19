import 'package:flutter/material.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';

class NetworkDebugWidget extends StatelessWidget {
  const NetworkDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final debugInfo = EndpointManager.debugInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MedRushTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedRushTheme.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.network_check,
                color: MedRushTheme.primaryBlue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Configuración de Red',
                style: TextStyle(
                  fontSize: MedRushTheme.fontSizeTitleMedium,
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...debugInfo.entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              fontWeight: MedRushTheme.fontWeightMedium,
                              color: MedRushTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: MedRushTheme.fontSizeBodySmall,
                              color: MedRushTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              ,
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              logInfo('🔍 Información de red: $debugInfo');
            },
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Log Info'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedRushTheme.primaryBlue,
              foregroundColor: MedRushTheme.textInverse,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

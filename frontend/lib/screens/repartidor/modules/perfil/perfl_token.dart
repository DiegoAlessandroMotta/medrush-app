import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/auth.api.dart';
import 'package:medrush/api/endpoint_manager.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';

class PerfilTokensScreen extends StatefulWidget {
  const PerfilTokensScreen({super.key});

  @override
  State<PerfilTokensScreen> createState() => _PerfilTokensScreenState();
}

class _PerfilTokensScreenState extends State<PerfilTokensScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, dynamic>> _tokens = const [];
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _accessToken = await _storage.read(key: EndpointManager.tokenKey);
      if (_accessToken == null || _accessToken!.isEmpty) {
        logWarning('⚠️ No hay access token para listar sesiones');
        if (mounted) {
          NotificationService.showError('No hay sesión activa',
              context: context);
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final tokens = await AuthApi.listTokens(_accessToken!);
      if (!mounted) {
        return;
      }
      setState(() {
        _tokens = tokens;
        _isLoading = false;
      });
    } catch (e) {
      logError('❌ Error al cargar tokens', e);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      NotificationService.showError('Error al cargar sesiones',
          context: context);
    }
  }

  Future<void> _revokeToken(String tokenId) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      return;
    }
    try {
      final ok = await AuthApi.revokeToken(_accessToken!, tokenId);
      if (!mounted) {
        return;
      }
      if (ok) {
        NotificationService.showSuccess('Sesión revocada', context: context);
        await _loadTokens();
      } else {
        NotificationService.showError('No se pudo revocar la sesión',
            context: context);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      NotificationService.showError('Error al revocar sesión',
          context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedRushTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: MedRushTheme.surface,
        elevation: 0,
        title: const Text(
          'Sesiones activas',
          style: TextStyle(
            color: MedRushTheme.textPrimary,
            fontSize: MedRushTheme.fontSizeHeadlineSmall,
            fontWeight: MedRushTheme.fontWeightBold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _isLoading ? null : _loadTokens,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tokens.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(MedRushTheme.spacingLg),
                  itemBuilder: (context, index) {
                    final t = _tokens[index];
                    final isCurrent =
                        (t['is_current'] == true) || (t['current'] == true);
                    final device =
                        (t['name'] ?? t['device_name'] ?? 'Sin nombre')
                            .toString();
                    final lastUsedAt = (t['last_used_at'] ??
                            t['last_used'] ??
                            t['updated_at'] ??
                            '-')
                        .toString();
                    final createdAt = (t['created_at'] ?? '-').toString();
                    final lastUsedRel = _formatRelative(lastUsedAt);
                    final createdRel = _formatRelative(createdAt);
                    final abilities = (t['abilities'] is List)
                        ? (t['abilities'] as List).join(', ')
                        : (t['abilities']?.toString() ?? '');

                    return Container(
                      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: MedRushTheme.surface,
                        borderRadius:
                            BorderRadius.circular(MedRushTheme.borderRadiusMd),
                        border: Border.all(color: MedRushTheme.borderLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono eliminado para compactar el layout
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        device,
                                        style: const TextStyle(
                                          fontSize:
                                              MedRushTheme.fontSizeBodyLarge,
                                          fontWeight:
                                              MedRushTheme.fontWeightBold,
                                          color: MedRushTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _kv('Último uso', lastUsedRel,
                                    icon: LucideIcons.clock),
                                _kv('Creado', createdRel,
                                    icon: LucideIcons.calendar),
                                if (abilities.isNotEmpty)
                                  _kv('Permisos', abilities,
                                      icon: LucideIcons.badgeInfo),
                                const SizedBox(height: MedRushTheme.spacingSm),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: MedRushTheme.primaryGreen
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Actual',
                                          style: TextStyle(
                                            color: MedRushTheme.primaryGreen,
                                            fontSize:
                                                MedRushTheme.fontSizeLabelSmall,
                                            fontWeight:
                                                MedRushTheme.fontWeightMedium,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 1),
                                    ElevatedButton.icon(
                                      onPressed: isCurrent
                                          ? null
                                          : () async {
                                              final confirm = await _confirm(
                                                  context, 'Revocar sesión');
                                              if (confirm == true) {
                                                final tokenId = (t['id'] ??
                                                        t['token_id'] ??
                                                        '')
                                                    .toString();
                                                if (tokenId.isNotEmpty) {
                                                  await _revokeToken(tokenId);
                                                }
                                              }
                                            },
                                      icon: const Icon(LucideIcons.circleX,
                                          size: 16),
                                      label: Text(AppLocalizations.of(context).revoke),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Botón movido debajo del contenido para no tapar el nombre
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: MedRushTheme.spacingSm),
                  itemCount: _tokens.length,
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shieldAlert,
              size: 64, color: MedRushTheme.textSecondary),
          SizedBox(height: MedRushTheme.spacingMd),
          Text(
            'No hay sesiones activas',
            style: TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          )
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: MedRushTheme.textSecondary),
            const SizedBox(width: 8),
          ],
          Text(
            '$k:',
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeBodyMedium,
              color: MedRushTheme.textSecondary,
              fontWeight: MedRushTheme.fontWeightMedium,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                color: MedRushTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  String _formatRelative(String iso) {
    try {
      if (iso.isEmpty || iso == '-') {
        return '-';
      }
      final dt = DateTime.tryParse(iso);
      if (dt == null) {
        return iso.replaceAll('Z', '');
      }
      final now = DateTime.now().toUtc();
      final diff = now.difference(dt.toUtc());

      if (diff.inSeconds < 60) {
        return 'hace ${diff.inSeconds}s';
      }
      if (diff.inMinutes < 60) {
        return 'hace ${diff.inMinutes} min';
      }
      if (diff.inHours < 24) {
        return 'hace ${diff.inHours} h';
      }
      if (diff.inDays < 7) {
        return 'hace ${diff.inDays} d';
      }

      // Fallback: fecha corta sin milisegundos ni zona
      final local = dt.toLocal();
      String two(int n) => StatusHelpers.formatearIdConCeros(n, digitos: 2);
      return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
    } catch (_) {
      return iso;
    }
  }

  Future<bool?> _confirm(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
            'Esta acción cerrará la sesión seleccionada. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).confirm)),
        ],
      ),
    );
  }
}

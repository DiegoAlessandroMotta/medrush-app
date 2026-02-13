import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/farmacias.api.dart';
import 'package:medrush/api/pedidos.api.dart';
import 'package:medrush/l10n/app_localizations.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/screens/repartidor/entregar_repartidor.dart';
import 'package:medrush/services/notification_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final String pedidoId;

  const PedidoDetalleScreen({super.key, required this.pedidoId});

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('pedidoId', pedidoId));
  }
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  Pedido? _pedido;
  Farmacia? _farmacia;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadPedidoDetalle();
  }

  Future<void> _loadPedidoDetalle() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener pedido real desde API
      final pedido = await PedidosApi.getPedidoById(widget.pedidoId.toString());
      if (pedido != null) {
        // Log para verificar si el pedido tiene firma
        if (pedido.firmaDigitalUrl != null &&
            pedido.firmaDigitalUrl!.isNotEmpty) {
          debugPrint(
              '✅ [PedidoDetalle] Pedido #${pedido.id} tiene firma digital: ${pedido.firmaDigitalUrl!.substring(0, 50)}...');
        } else {
          debugPrint(
              '❌ [PedidoDetalle] Pedido #${pedido.id} NO tiene firma digital');
        }

        // Obtener farmacia asociada
        final farmacias = await FarmaciasApi.getAllFarmacias();
        final farmacia =
            farmacias.where((f) => f.id == pedido.farmaciaId).firstOrNull;

        if (!mounted) {
          return;
        }

        setState(() {
          _pedido = pedido;
          _farmacia = farmacia;
          _isLoading = false;
        });
      } else {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar pedido: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarEstadoPedido(EstadoPedido nuevoEstado) async {
    if (_pedido == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final pedidoActualizado = _pedido!.copyWith(
        estado: nuevoEstado,
        updatedAt: DateTime.now(),
      );

      // Actualizar fechas específicas según el estado (sin tocar createdAt)
      Pedido pedidoConFechas = pedidoActualizado;
      switch (nuevoEstado) {
        case EstadoPedido.asignado:
          pedidoConFechas =
              pedidoActualizado.copyWith(fechaAsignacion: DateTime.now());
        case EstadoPedido.recogido:
          pedidoConFechas =
              pedidoActualizado.copyWith(fechaRecogida: DateTime.now());
        case EstadoPedido.enRuta:
          // No modificamos fechas aquí
          break;
        case EstadoPedido.entregado:
          pedidoConFechas =
              pedidoActualizado.copyWith(fechaEntrega: DateTime.now());
        case EstadoPedido.pendiente:
        case EstadoPedido.cancelado:
        case EstadoPedido.fallido:
          // Mantener fechas existentes
          break;
      }

      // Confirmar captura de firma antes de entregar
      if (nuevoEstado == EstadoPedido.entregado) {
        final decision = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).confirmDeliveryTitle),
            content: Text(
                AppLocalizations.of(context).confirmDeliveryWithSignature),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('capture'),
                child: Text(AppLocalizations.of(context).captureSignature),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('deliver'),
                child: Text(AppLocalizations.of(context).deliverWithoutSignature),
              ),
            ],
          ),
        );

        if (!mounted) {
          return;
        }

        if (decision == 'capture') {
          setState(() {
            _isUpdating = false;
          });

          Navigator.pushNamed(
            context,
            '/firma',
            arguments: {
              'pedidoId': _pedido!.id,
              'esModoEdicion': false,
            },
          );
          return;
        }
      }

      // Llamar API específica y preferir la respuesta del servidor
      Pedido? respuesta;
      switch (nuevoEstado) {
        case EstadoPedido.recogido:
          respuesta =
              await PedidosApi.marcarPedidoRecogido(_pedido!.id.toString());
        case EstadoPedido.enRuta:
          respuesta =
              await PedidosApi.marcarPedidoEnRuta(_pedido!.id.toString());
        case EstadoPedido.entregado:
          respuesta = await PedidosApi.marcarPedidoEntregado(
            _pedido!.id.toString(),
            latitud: 0.0, // TODO: Obtener coordenadas reales del dispositivo
            longitud: 0.0,
          );
        case EstadoPedido.fallido:
          respuesta = await PedidosApi.marcarPedidoFallido(
            _pedido!.id.toString(),
            motivoFallo: 'Cambio de estado manual',
            latitud: 0.0, // TODO: Obtener coordenadas reales del dispositivo
            longitud: 0.0,
          );
        case EstadoPedido.asignado:
        case EstadoPedido.pendiente:
        case EstadoPedido.cancelado:
          // Sin endpoint específico o gestión fuera de esta pantalla
          break;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pedido = respuesta ?? pedidoConFechas;
        _isUpdating = false;
      });

      NotificationService.showSuccess(
        'Estado actualizado a: ${StatusHelpers.estadoPedidoTexto(nuevoEstado, AppLocalizations.of(context))}',
        context: context,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      NotificationService.showError(
        AppLocalizations.of(context).errorUpdatingState(e),
        context: context,
      );
    }
  }

  Future<void> _llamarCliente() async {
    if (_pedido == null) {
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: _pedido!.pacienteTelefono);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).cannotMakeCall,
          context: context,
        );
      }
    }
  }

  Future<void> _copiarTelefonoAlPortapapeles() async {
    if (_pedido == null) {
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _pedido!.pacienteTelefono));
      if (mounted) {
        NotificationService.showSuccess(
          AppLocalizations.of(context).infoCopied,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorCopyingInfo,
          context: context,
        );
      }
    }
  }

  Future<void> _copiarEmailAlPortapapeles() async {
    if (_pedido == null || _pedido!.pacienteEmail == null) {
      NotificationService.showInfo(
        AppLocalizations.of(context).clientHasNoEmail,
        context: context,
      );
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _pedido!.pacienteEmail!));
      if (mounted) {
        NotificationService.showSuccess(
          AppLocalizations.of(context).infoCopied,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).errorCopyingInfo,
          context: context,
        );
      }
    }
  }

  Future<void> _abrirMapas() async {
    if (_pedido == null) {
      return;
    }

    final direccionEncoded = Uri.encodeComponent(_pedido!.direccionEntrega);
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$direccionEncoded',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).couldNotOpenMaps,
          context: context,
        );
      }
    }
  }

  Future<void> _abrirNavegacion() async {
    if (_pedido == null) {
      return;
    }

    final lat = _pedido!.latitudEntrega;
    final lng = _pedido!.longitudEntrega;
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        NotificationService.showError(
          AppLocalizations.of(context).cannotOpenNavigation,
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: [
            // Header con drag handle y botón de cerrar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              decoration: const BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MedRushTheme.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header con título y botón de cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context).orderIdShort}${widget.pedidoId}',
                              style: const TextStyle(
                                fontSize: MedRushTheme.fontSizeTitleLarge,
                                fontWeight: MedRushTheme.fontWeightBold,
                                color: MedRushTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_pedido != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: StatusHelpers.estadoPedidoColor(
                                      _pedido!.estado),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  StatusHelpers.estadoPedidoTexto(
                                      _pedido!.estado, AppLocalizations.of(context)),
                                  style: const TextStyle(
                                    color: MedRushTheme.textInverse,
                                    fontSize: MedRushTheme.fontSizeLabelSmall,
                                    fontWeight: MedRushTheme.fontWeightMedium,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: MedRushTheme.textSecondary,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: MedRushTheme.backgroundSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido scrolleable
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(MedRushTheme.spacingLg),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _pedido == null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estado del pedido
                              _buildInfoSection(AppLocalizations.of(context).deliveryStatus, [
                                if (_pedido!.prioridad > 1)
                                  _buildInfoRow(
                                      AppLocalizations.of(context).priority,
                                      'P${_pedido!.prioridad}'),
                                _buildTimelineInfo(),
                              ]),

                              const SizedBox(height: MedRushTheme.spacingLg),

                              _buildInfoSection(
                                  AppLocalizations.of(context).clientInformation, [
                                _buildInfoRow(
                                    AppLocalizations.of(context).name,
                                    _pedido!.pacienteNombre),
                                _buildInfoRowWithActions(
                                  AppLocalizations.of(context).phone,
                                  _pedido!.pacienteTelefono,
                                  [
                                    _buildActionButton(
                                      icon: LucideIcons.copy,
                                      tooltip: AppLocalizations.of(context).copyPhoneTooltip,
                                      onPressed: _copiarTelefonoAlPortapapeles,
                                    ),
                                  ],
                                ),
                                if (_pedido!.pacienteEmail != null &&
                                    _pedido!.pacienteEmail!.isNotEmpty)
                                  _buildInfoRowWithActions(
                                    AppLocalizations.of(context).email,
                                    _pedido!.pacienteEmail!,
                                    [
                                      _buildActionButton(
                                        icon: LucideIcons.copy,
                                        tooltip: AppLocalizations.of(context).copyEmail,
                                        onPressed: _copiarEmailAlPortapapeles,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: MedRushTheme.spacingMd),
                                // Botón grande para llamar
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _llamarCliente,
                                    icon:
                                        const Icon(LucideIcons.phone, size: 22),
                                    label: Text(AppLocalizations.of(context).callClient),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          MedRushTheme.primaryGreen,
                                      foregroundColor: MedRushTheme.textInverse,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                              ]),

                              const SizedBox(height: MedRushTheme.spacingLg),

                              _buildInfoSection(
                                  AppLocalizations.of(context).deliveryLocationLabel, [
                                _buildInfoRow(
                                    AppLocalizations.of(context).address,
                                    _pedido!.direccionEntrega),
                                if (_pedido!.direccionDetalle != null &&
                                    _pedido!.direccionDetalle!.isNotEmpty)
                                  _buildInfoRow(
                                      AppLocalizations.of(context).detail,
                                      _pedido!.direccionDetalle!),
                                _buildInfoRow(
                                    AppLocalizations.of(context).districtLabel,
                                    _pedido!.distritoEntrega),
                                if (_pedido!.codigoAcceso != null &&
                                    _pedido!.codigoAcceso!.isNotEmpty)
                                  _buildInfoRow(
                                      AppLocalizations.of(context).accessCode,
                                      _pedido!.codigoAcceso!),
                                if (_pedido!.tiempoEntregaEstimado != null ||
                                    _pedido!.distanciaEstimada != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (_pedido!.tiempoEntregaEstimado !=
                                          null) ...[
                                        const Icon(LucideIcons.clock,
                                            size: 18,
                                            color: MedRushTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_pedido!.tiempoEntregaEstimado} min',
                                          style: const TextStyle(
                                            fontSize:
                                                MedRushTheme.fontSizeBodyMedium,
                                            color: MedRushTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (_pedido!.distanciaEstimada !=
                                          null) ...[
                                        const SizedBox(width: 16),
                                        const Icon(LucideIcons.route,
                                            size: 18,
                                            color: MedRushTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          StatusHelpers.formatearDistanciaKm(
                                              _pedido!.distanciaEstimada!),
                                          style: const TextStyle(
                                            fontSize:
                                                MedRushTheme.fontSizeBodyMedium,
                                            color: MedRushTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _abrirMapas,
                                        icon: const Icon(LucideIcons.map,
                                            size: 20),
                                        label: Text(AppLocalizations.of(context).viewMap),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              MedRushTheme.primaryGreen,
                                          foregroundColor:
                                              MedRushTheme.textInverse,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _abrirNavegacion,
                                        icon: const Icon(LucideIcons.navigation,
                                            size: 20),
                                        label: Text(AppLocalizations.of(context).navigate),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              MedRushTheme.primaryGreen,
                                          side: const BorderSide(
                                              color: MedRushTheme.primaryGreen),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ]),

                              const SizedBox(height: MedRushTheme.spacingLg),

                              if (_farmacia != null)
                                _buildInfoSection(
                                    AppLocalizations.of(context).pharmacy, [
                                  _buildInfoRow(
                                      AppLocalizations.of(context).name,
                                      _farmacia!.nombre),
                                  _buildInfoRow(
                                      AppLocalizations.of(context).cadenaLabel,
                                      _farmacia!.cadena ??
                                          AppLocalizations.of(context).noChain),
                                  _buildInfoRow(
                                      AppLocalizations.of(context).address,
                                      _farmacia!.direccion),
                                  _buildInfoRow(
                                      AppLocalizations.of(context).phone,
                                      _farmacia!.telefono ??
                                          AppLocalizations.of(context).noPhone),
                                  if (_farmacia!.delivery24h) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: MedRushTheme.primaryGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context).delivery24hLabel,
                                        style: const TextStyle(
                                          color: MedRushTheme.textInverse,
                                          fontSize:
                                              MedRushTheme.fontSizeLabelSmall,
                                          fontWeight:
                                              MedRushTheme.fontWeightBold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ]),

                              const SizedBox(height: MedRushTheme.spacingLg),

                              _buildInfoSection(
                                  AppLocalizations.of(context).orderTypeSectionTitle, [
                                Container(
                                  padding: const EdgeInsets.all(
                                    MedRushTheme.spacingMd,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MedRushTheme.backgroundPrimary,
                                    borderRadius: BorderRadius.circular(
                                      MedRushTheme.borderRadiusMd,
                                    ),
                                    border: Border.all(
                                      color: MedRushTheme.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: MedRushTheme.primaryGreen
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _pedido!.tipoPedido ==
                                                  TipoPedido
                                                      .medicamentosControlados
                                              ? LucideIcons.shieldAlert
                                              : LucideIcons.clipboardList,
                                          size: 22,
                                          color: _pedido!.tipoPedido ==
                                                  TipoPedido
                                                      .medicamentosControlados
                                              ? Colors.red
                                              : MedRushTheme.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: MedRushTheme.spacingMd,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context).orderTypeLabel,
                                              style: const TextStyle(
                                                fontSize: MedRushTheme
                                                    .fontSizeTitleMedium,
                                                fontWeight: MedRushTheme
                                                    .fontWeightSemiBold,
                                                color: MedRushTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: MedRushTheme.spacingXs,
                                            ),
                                            Text(
                                              StatusHelpers.tipoPedidoTexto(
                                                  _pedido!.tipoPedido, AppLocalizations.of(context)),
                                              style: TextStyle(
                                                fontSize: MedRushTheme
                                                    .fontSizeBodyLarge,
                                                fontWeight:
                                                    MedRushTheme.fontWeightBold,
                                                color: _pedido!.tipoPedido ==
                                                        TipoPedido
                                                            .medicamentosControlados
                                                    ? Colors.red
                                                    : MedRushTheme.primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_pedido!.requiereFirmaEspecial) ...[
                                  const SizedBox(
                                      height: MedRushTheme.spacingMd),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: MedRushTheme.spacingMd,
                                      vertical: MedRushTheme.spacingSm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MedRushTheme.specialSignature
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: MedRushTheme.specialSignature
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.pencil,
                                          size: 18,
                                          color: MedRushTheme.specialSignature,
                                        ),
                                        const SizedBox(
                                          width: MedRushTheme.spacingSm,
                                        ),
                                        Text(
                                          AppLocalizations.of(context).requiresSpecialSignature,
                                          style: const TextStyle(
                                            color:
                                                MedRushTheme.specialSignature,
                                            fontWeight:
                                                MedRushTheme.fontWeightBold,
                                            fontSize:
                                                MedRushTheme.fontSizeBodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ]),

                              const SizedBox(height: MedRushTheme.spacingLg),

                              // Firma Digital (si existe)
                              if (_pedido!.firmaDigitalUrl != null &&
                                  _pedido!.firmaDigitalUrl!.isNotEmpty)
                                _buildInfoSection(
                                    AppLocalizations.of(context).digitalSignatureLabel, [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(
                                        MedRushTheme.spacingMd),
                                    decoration: BoxDecoration(
                                      color: MedRushTheme.backgroundPrimary,
                                      borderRadius: BorderRadius.circular(
                                          MedRushTheme.borderRadiusMd),
                                      border: Border.all(
                                          color: MedRushTheme.borderLight),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              LucideIcons.pencil,
                                              color: MedRushTheme.primaryGreen,
                                              size: 18,
                                            ),
                                            const SizedBox(
                                                width: MedRushTheme.spacingSm),
                                            Text(
                                              AppLocalizations.of(context).signatureCaptured,
                                              style: const TextStyle(
                                                fontSize: MedRushTheme
                                                    .fontSizeBodyMedium,
                                                fontWeight: MedRushTheme
                                                    .fontWeightMedium,
                                                color: MedRushTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height: MedRushTheme.spacingSm),
                                        Container(
                                          width: double.infinity,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: MedRushTheme
                                                .backgroundSecondary,
                                            borderRadius: BorderRadius.circular(
                                                MedRushTheme.borderRadiusSm),
                                            border: Border.all(
                                                color:
                                                    MedRushTheme.borderLight),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                MedRushTheme.borderRadiusSm),
                                            child: _buildFirmaImage(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]),

                              const SizedBox(height: MedRushTheme.spacingLg),

                              // Observaciones y detalles
                              if (_pedido!.observaciones != null &&
                                  _pedido!.observaciones!.isNotEmpty)
                                _buildInfoSection(
                                    AppLocalizations.of(context).observations, [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(
                                        MedRushTheme.spacingMd),
                                    decoration: BoxDecoration(
                                      color: MedRushTheme.observations
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          MedRushTheme.borderRadiusMd),
                                      border: Border.all(
                                          color: MedRushTheme.observations
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      _pedido!.observaciones!,
                                      style: const TextStyle(
                                        color: MedRushTheme.observations,
                                        fontSize:
                                            MedRushTheme.fontSizeBodyMedium,
                                        fontWeight:
                                            MedRushTheme.fontWeightMedium,
                                      ),
                                    ),
                                  ),
                                ]),
                              const SizedBox(height: MedRushTheme.spacingLg),
                              // Botón de acción flotante
                              if (_pedido != null && !_isUpdating) ...[
                                const SizedBox(height: MedRushTheme.spacingLg),
                                if (_buildFloatingActionButton() != null)
                                  _buildFloatingActionButton()!,
                              ],

                              // Espacio extra al final para evitar que el contenido se corte
                              const SizedBox(height: MedRushTheme.spacingXl),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 64,
            color: MedRushTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).deliveryNotFound,
            style: const TextStyle(
              fontSize: MedRushTheme.fontSizeTitleLarge,
              color: MedRushTheme.textPrimary,
              fontWeight: MedRushTheme.fontWeightBold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).deliveryNotFoundWithId(widget.pedidoId),
            style: const TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodyLarge,
            fontWeight: MedRushTheme.fontWeightBold,
            color: MedRushTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: MedRushTheme.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MedRushTheme.spacingMd),
          decoration: BoxDecoration(
            color: MedRushTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
            border: Border.all(color: MedRushTheme.borderLight),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textSecondary,
                fontSize: MedRushTheme.fontSizeBodySmall,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithActions(
      String label, String value, List<Widget> actions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textSecondary,
                fontSize: MedRushTheme.fontSizeBodySmall,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: MedRushTheme.textPrimary,
                      fontSize: MedRushTheme.fontSizeBodyMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...actions,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: isPrimary
              ? MedRushTheme.primaryGreen
              : MedRushTheme.textSecondary,
        ),
        tooltip: tooltip,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isPrimary
              ? MedRushTheme.primaryGreen.withValues(alpha: 0.1)
              : MedRushTheme.textSecondary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineInfo() {
    return Column(
      children: [
        if (_pedido!.createdAt != null)
          _buildTimelineItem(
            AppLocalizations.of(context).created,
            _pedido!.createdAt!,
            LucideIcons.clock,
            Colors.grey,
          ),
        if (_pedido!.fechaAsignacion != null)
          _buildTimelineItem(
            AppLocalizations.of(context).assigned,
            _pedido!.fechaAsignacion!,
            LucideIcons.userPlus,
            Colors.blue,
          ),
        if (_pedido!.fechaRecogida != null)
          _buildTimelineItem(
            AppLocalizations.of(context).pickedUp,
            _pedido!.fechaRecogida!,
            LucideIcons.package,
            Colors.purple,
          ),
        if (_pedido!.fechaEntrega != null)
          _buildTimelineItem(
            AppLocalizations.of(context).deliveredStatus,
            _pedido!.fechaEntrega!,
            LucideIcons.check,
            Colors.green,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
      String label, DateTime fecha, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ${StatusHelpers.formatearFechaCompleta(fecha)}',
            style: const TextStyle(
              color: MedRushTheme.textSecondary,
              fontSize: MedRushTheme.fontSizeBodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_pedido == null || _isUpdating) {
      return null;
    }

    final siguienteEstado = _getSiguienteEstado(_pedido!.estado);
    if (siguienteEstado == null) {
      return null;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (siguienteEstado == EstadoPedido.entregado) {
            // Navegar a flujo de entrega (captura de firma y confirmación)
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => EntregarRepartidorScreen(
                  pedido: _pedido!,
                ),
              ),
            )
                .then((entregado) {
              if (entregado == true) {
                // Refrescar detalle tras entrega exitosa
                _loadPedidoDetalle();
              }
            });
          } else {
            _actualizarEstadoPedido(siguienteEstado);
          }
        },
        icon: const Icon(Icons.arrow_forward),
        label: Text(_getAccionTexto(siguienteEstado)),
        style: ElevatedButton.styleFrom(
          backgroundColor: StatusHelpers.estadoPedidoColor(siguienteEstado),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  EstadoPedido? _getSiguienteEstado(EstadoPedido estadoActual) {
    switch (estadoActual) {
      case EstadoPedido.pendiente:
        return EstadoPedido.asignado;
      case EstadoPedido.asignado:
        return EstadoPedido.recogido;
      case EstadoPedido.recogido:
        return EstadoPedido.enRuta;
      case EstadoPedido.enRuta:
        return EstadoPedido.entregado;
      case EstadoPedido.entregado:
      case EstadoPedido.cancelado:
      case EstadoPedido.fallido:
        return null;
    }
  }

  String _getAccionTexto(EstadoPedido estado) {
    final l10n = AppLocalizations.of(context);
    switch (estado) {
      case EstadoPedido.asignado:
        return l10n.assign;
      case EstadoPedido.recogido:
        return l10n.pickUpAction;
      case EstadoPedido.enRuta:
        return l10n.onRoute;
      case EstadoPedido.entregado:
        return l10n.deliver;
      default:
        return l10n.next;
    }
  }

  Widget _buildFirmaImage() {
    if (_pedido?.firmaDigitalUrl == null || _pedido!.firmaDigitalUrl!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              color: MedRushTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).noSignatureAvailable,
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodySmall,
                color: MedRushTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final firmaUrl = _pedido!.firmaDigitalUrl!;

    // Verificar si es una URL o datos base64
    if (firmaUrl.startsWith('http://') || firmaUrl.startsWith('https://')) {
      // Es una URL, usar Image.network
      return Image.network(
        firmaUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  color: MedRushTheme.textSecondary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).errorLoadingSignature,
                  style: const TextStyle(
                    fontSize: MedRushTheme.fontSizeBodySmall,
                    color: MedRushTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else if (firmaUrl.startsWith('<?xml') || firmaUrl.startsWith('<svg')) {
      // Es SVG texto, usar SvgPicture.string
      try {
        return SvgPicture.string(
          firmaUrl,
          placeholderBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      } catch (e) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                color: MedRushTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).errorRenderingSvg,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  color: MedRushTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Es datos base64, usar Image.memory
      try {
        return Image.memory(
          base64Decode(firmaUrl),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.triangleAlert,
                    color: MedRushTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).errorDecodingSignature,
                    style: const TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                color: MedRushTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).invalidSignatureFormat,
                style: const TextStyle(
                  fontSize: MedRushTheme.fontSizeBodySmall,
                  color: MedRushTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}

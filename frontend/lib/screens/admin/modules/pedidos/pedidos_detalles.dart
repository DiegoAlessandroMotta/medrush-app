import 'dart:convert';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/api/base.api.dart';
import 'package:medrush/models/farmacia.model.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/models/usuario.model.dart';
import 'package:medrush/repositories/farmacia.repository.dart';
import 'package:medrush/repositories/pedido.repository.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

// Ancho máximo del bottom sheet en desktop para mejorar legibilidad
const double _kMaxDesktopSheetWidth = 980;

class EntregasDetalles extends StatefulWidget {
  final Pedido pedido;
  const EntregasDetalles({super.key, required this.pedido});

  @override
  State<EntregasDetalles> createState() => _EntregasDetallesState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Pedido>('pedido', pedido));
  }
}

class _EntregasDetallesState extends State<EntregasDetalles> {
  Farmacia? _farmacia;
  Usuario? _repartidor;
  Pedido? _pedidoCompleto;
  bool _isLoading = true;
  final PedidoRepository _pedidoRepository = PedidoRepository();

  /// Getter para obtener el pedido completo o el original como fallback
  Pedido get pedido => _pedidoCompleto ?? widget.pedido;

  @override
  void initState() {
    super.initState();
    _loadRelatedData();
  }

  Future<void> _loadRelatedData() async {
    try {
      logInfo(
          '[FIRMA_DETALLES] Cargando detalles completos del pedido ${pedido.id}');

      // Cargar pedido completo con todos los campos (incluyendo firma_digital)
      final pedidoRes = await _pedidoRepository.obtenerPorId(pedido.id);
      final pedidoCompleto = pedidoRes.data;

      // Log detallado de la firma digital obtenida
      if (pedidoCompleto?.firmaDigitalUrl != null) {
        logInfo('[FIRMA_DETALLES] Firma digital encontrada en pedido');
        logInfo(
            '[FIRMA_DETALLES] Longitud de firma: ${pedidoCompleto!.firmaDigitalUrl!.length} caracteres');
        logInfo(
            '[FIRMA_DETALLES] Es base64 válido: ${pedidoCompleto.firmaDigitalUrl!.startsWith('data:image/')}');
        logInfo(
            '[FIRMA_DETALLES] Inicio de firma: ${pedidoCompleto.firmaDigitalUrl!.substring(0, pedidoCompleto.firmaDigitalUrl!.length > 100 ? 100 : pedidoCompleto.firmaDigitalUrl!.length)}...');
        logInfo(
            '[FIRMA_DETALLES] Final de firma: ...${pedidoCompleto.firmaDigitalUrl!.substring(pedidoCompleto.firmaDigitalUrl!.length > 100 ? pedidoCompleto.firmaDigitalUrl!.length - 100 : 0)}');
      } else {
        logInfo('[FIRMA_DETALLES] No se encontró firma digital en el pedido');
      }

      // Cargar farmacia
      final farmaciaRepo = FarmaciaRepository();
      final farmaciaRes = await farmaciaRepo.obtenerPorId(pedido.farmaciaId);
      final farmacia = farmaciaRes.data;

      // TODO: Cargar repartidor cuando el backend soporte endpoint /usuarios/{id}
      // Por ahora, solo log ya que no hay endpoint para esto
      Usuario? repartidor;
      if (pedido.repartidorId != null) {
        logInfo(
            '[FIRMA_DETALLES] Repartidor ID ${pedido.repartidorId} - no cargado (endpoint no disponible)');
        // TODO: Implementar cuando haya endpoint para obtener usuario por ID
      }

      setState(() {
        _pedidoCompleto = pedidoCompleto;
        _farmacia = farmacia;
        _repartidor = repartidor;
        _isLoading = false;
      });

      logInfo('[FIRMA_DETALLES] Detalles completos cargados exitosamente');
    } catch (e) {
      logError('[FIRMA_DETALLES] Error al cargar detalles del pedido', e);
      logError('[FIRMA_DETALLES] Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxDesktopSheetWidth),
        child: Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Column(
              children: [
                // Header con drag handle y botón de cerrar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  decoration: const BoxDecoration(
                    color: MedRushTheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              MedRushTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header con título y botones de acciones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pedido #${pedido.id}',
                                  style: const TextStyle(
                                    fontSize: MedRushTheme.fontSizeTitleLarge,
                                    fontWeight: MedRushTheme.fontWeightBold,
                                    color: MedRushTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: StatusHelpers.estadoPedidoColor(
                                        pedido.estado),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    StatusHelpers.estadoPedidoTexto(
                                        pedido.estado),
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
                          Row(
                            children: [
                              IconButton(
                                onPressed: _mostrarCodigoBarrasDialog,
                                icon: const Icon(
                                  LucideIcons.barcode,
                                  color: MedRushTheme.primaryGreen,
                                  size: 24,
                                ),
                                tooltip: 'Código de barras',
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  LucideIcons.x,
                                  color: MedRushTheme.textSecondary,
                                  size: 24,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      MedRushTheme.backgroundSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información básica
                        _buildInfoSection('Información Básica', [
                          _buildIconRow(
                              'ID del Pedido', pedido.id, LucideIcons.hash),
                          _buildIconRow('Código de Barra', pedido.codigoBarra,
                              LucideIcons.barcode),
                          _buildIconRow('Cliente', pedido.pacienteNombre,
                              LucideIcons.user),
                          _buildIconRow('Teléfono', pedido.pacienteTelefono,
                              LucideIcons.phone),
                          if (pedido.pacienteEmail != null)
                            _buildIconRow('Email', pedido.pacienteEmail!,
                                LucideIcons.mail),
                          _buildIconRow(
                              'Tipo',
                              StatusHelpers.tipoPedidoTexto(pedido.tipoPedido),
                              LucideIcons.tag),
                          _buildIconRow(
                              'Estado',
                              StatusHelpers.estadoPedidoTexto(pedido.estado),
                              LucideIcons.info,
                              iconColor: StatusHelpers.estadoPedidoColor(
                                  pedido.estado)),
                          _buildIconRow('Prioridad', '${pedido.prioridad}',
                              LucideIcons.star),
                          if (pedido.requiereFirmaEspecial)
                            _buildIconRow('Requiere Firma Especial', 'Sí',
                                LucideIcons.penTool),
                          if (pedido.fechaAsignacion != null)
                            _buildIconRow(
                                'Fecha de Asignación',
                                _formatDate(pedido.fechaAsignacion!),
                                LucideIcons.calendar),
                        ]),

                        const SizedBox(height: MedRushTheme.spacingLg),

                        // Información de medicamentos
                        if (pedido.medicamentos.isNotEmpty)
                          Column(
                            children: [
                              _buildInfoSection('Medicamentos', [
                                ...pedido.medicamentos
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final medicamento = entry.value;
                                  return _buildMedicamentoRow(
                                      medicamento, index + 1);
                                }),
                              ]),
                              const SizedBox(height: MedRushTheme.spacingLg),
                            ],
                          ),

                        // Información de entrega
                        _buildInfoSection('Dirección de Entrega', [
                          _buildIconRow('Dirección', pedido.direccionEntrega,
                              LucideIcons.mapPin),
                          if (pedido.direccionEntregaLinea2 != null)
                            _buildIconRow(
                                'Dirección Línea 2',
                                pedido.direccionEntregaLinea2!,
                                LucideIcons.mapPin),
                          _buildIconRow('Ciudad', pedido.distritoEntrega,
                              LucideIcons.building),
                          if (pedido.estadoRegionEntrega != null)
                            _buildIconRow('Estado/Región',
                                pedido.estadoRegionEntrega!, LucideIcons.map),
                          if (pedido.codigoPostalEntrega != null)
                            _buildIconRow('Código Postal',
                                pedido.codigoPostalEntrega!, LucideIcons.mail),
                          if (pedido.direccionDetalle != null)
                            _buildIconRow('Detalle', pedido.direccionDetalle!,
                                LucideIcons.fileText),
                          if (pedido.codigoAcceso != null)
                            _buildIconRow('Código de Acceso',
                                pedido.codigoAcceso!, LucideIcons.lock),
                          if (pedido.codigoAccesoEdificio != null)
                            _buildIconRow(
                                'Código de Edificio',
                                pedido.codigoAccesoEdificio!,
                                LucideIcons.building2),
                          if (pedido.codigoIsoPaisEntrega != null)
                            _buildIconRow('País', pedido.codigoIsoPaisEntrega!,
                                LucideIcons.flag),
                          const SizedBox(height: MedRushTheme.spacingMd),
                          SizedBox(
                            height: 220,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  MedRushTheme.borderRadiusMd),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: pedido.latitudEntrega != null &&
                                          pedido.longitudEntrega != null
                                      ? LatLng(
                                          pedido.latitudEntrega!,
                                          pedido.longitudEntrega!,
                                        )
                                      : const LatLng(26.037737,
                                          -80.179550), // EEUU por defecto
                                  zoom: 15,
                                ),
                                markers: pedido.latitudEntrega != null &&
                                        pedido.longitudEntrega != null
                                    ? {
                                        Marker(
                                          markerId: const MarkerId('entrega'),
                                          position: LatLng(
                                            pedido.latitudEntrega!,
                                            pedido.longitudEntrega!,
                                          ),
                                          infoWindow: InfoWindow(
                                            title: 'Pedido #${pedido.id}',
                                            snippet: pedido.direccionEntrega,
                                          ),
                                        ),
                                      }
                                    : {},
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: MedRushTheme.spacingLg),

                        // Información de ubicación de recogida
                        if (_hasRecojoInfo())
                          Column(
                            children: [
                              _buildInfoSection('Ubicación de Recogida', [
                                if (pedido.latitudRecojo != null &&
                                    pedido.longitudRecojo != null)
                                  _buildIconRow(
                                      'Coordenadas',
                                      StatusHelpers
                                          .formatearCoordenadasAltaPrecision(
                                              pedido.latitudRecojo!,
                                              pedido.longitudRecojo!),
                                      LucideIcons.navigation),
                                if (pedido.ubicacionRecojo != null)
                                  _buildIconRow(
                                      'Ubicación Detallada',
                                      '${pedido.ubicacionRecojo}',
                                      LucideIcons.search),
                              ]),
                              const SizedBox(height: MedRushTheme.spacingLg),
                            ],
                          ),

                        // Información de farmacia y repartidor
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(MedRushTheme.spacingLg),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          _buildInfoSection('Farmacia', [
                            _buildIconRow(
                                'Nombre',
                                _farmacia?.nombre ?? 'No encontrada',
                                LucideIcons.pill),
                            if (_farmacia != null) ...[
                              _buildIconRow('Dirección', _farmacia!.direccion,
                                  LucideIcons.mapPin),
                              if (_farmacia!.telefono != null)
                                _buildIconRow('Teléfono', _farmacia!.telefono!,
                                    LucideIcons.phone),
                            ],
                          ]),
                          const SizedBox(height: MedRushTheme.spacingLg),
                          if (_repartidor != null)
                            _buildInfoSection('Repartidor', [
                              Row(
                                children: [
                                  _buildRepartidorAvatar(_repartidor!),
                                  const SizedBox(width: MedRushTheme.spacingMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildBoldText(_repartidor!.nombre),
                                        const SizedBox(height: 4),
                                        if (_repartidor!.telefono != null)
                                          Text(_repartidor!.telefono!,
                                              style: const TextStyle(
                                                  color: MedRushTheme
                                                      .textSecondary)),
                                        Text(
                                            'Estado: ${_repartidor!.estadoRepartidor?.name ?? '-'}',
                                            style: const TextStyle(
                                                color: MedRushTheme
                                                    .textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ])
                          else
                            _buildInfoSection('Repartidor', [
                              const Text(
                                'Sin asignar',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: MedRushTheme.textSecondary,
                                ),
                              ),
                            ]),
                        ],

                        const SizedBox(height: MedRushTheme.spacingLg),

                        // Fechas importantes
                        _buildInfoSection('Fechas y Progreso', [
                          if (pedido.fechaRecogida != null)
                            _buildIconRow(
                                'Fecha de Recogida',
                                _formatDate(pedido.fechaRecogida!),
                                LucideIcons.package),
                          if (pedido.fechaEntrega != null)
                            _buildIconRow(
                                'Fecha de Entrega',
                                _formatDate(pedido.fechaEntrega!),
                                LucideIcons.check),
                          if (pedido.createdAt != null)
                            _buildIconRow(
                                'Creado',
                                _formatDate(pedido.createdAt!),
                                LucideIcons.calendar),
                          if (pedido.updatedAt != null &&
                              pedido.updatedAt != pedido.createdAt)
                            _buildIconRow(
                                'Última Actualización',
                                _formatDate(pedido.updatedAt!),
                                LucideIcons.calendarCheck),

                          // Información de estimaciones
                          if (pedido.tiempoEntregaEstimado != null)
                            _buildIconRow(
                                'Tiempo Estimado',
                                StatusHelpers.formatearTiempo(
                                    pedido.tiempoEntregaEstimado!),
                                LucideIcons.clock),
                          if (pedido.distanciaEstimada != null)
                            _buildIconRow(
                                'Distancia Estimada',
                                StatusHelpers.formatearDistanciaKm(
                                    pedido.distanciaEstimada!),
                                LucideIcons.ruler),
                        ]),

                        // Observaciones si existen
                        if (pedido.observaciones != null) ...[
                          const SizedBox(height: MedRushTheme.spacingLg),
                          _buildInfoSection('Observaciones', [
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(MedRushTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: MedRushTheme.backgroundSecondary,
                                borderRadius: BorderRadius.circular(
                                    MedRushTheme.borderRadiusMd),
                              ),
                              child: Text(
                                pedido.observaciones!,
                                style: const TextStyle(
                                  color: MedRushTheme.textSecondary,
                                  fontSize: MedRushTheme.fontSizeBodyMedium,
                                ),
                              ),
                            ),
                          ]),
                        ],

                        // Archivos de entrega: foto, firma y documento de consentimiento
                        if ((pedido.fotoEntregaUrl != null &&
                                pedido.fotoEntregaUrl!.isNotEmpty) ||
                            (pedido.firmaDigitalUrl != null &&
                                pedido.firmaDigitalUrl!.isNotEmpty) ||
                            (pedido.documentoConsentimientoUrl != null &&
                                pedido.documentoConsentimientoUrl!
                                    .isNotEmpty)) ...[
                          const SizedBox(height: MedRushTheme.spacingLg),
                          _buildInfoSection('Comprobantes de Entrega', [
                            Wrap(
                              spacing: MedRushTheme.spacingMd,
                              runSpacing: MedRushTheme.spacingMd,
                              children: [
                                if (pedido.fotoEntregaUrl != null &&
                                    pedido.fotoEntregaUrl!.isNotEmpty)
                                  _buildMediaCard(
                                    title: 'Foto de Entrega',
                                    url: BaseApi.getValidImageUrl(
                                        pedido.fotoEntregaUrl),
                                  ),
                                if (pedido.firmaDigitalUrl != null &&
                                    pedido.firmaDigitalUrl!.isNotEmpty) ...[
                                  // Log antes de mostrar la firma
                                  Builder(
                                    builder: (context) {
                                      logInfo(
                                          '[FIRMA_DETALLES] Mostrando firma en UI');
                                      logInfo(
                                          '[FIRMA_DETALLES] Firma disponible: ${pedido.firmaDigitalUrl!.isNotEmpty}');
                                      logInfo(
                                          '[FIRMA_DETALLES] Longitud de firma: ${pedido.firmaDigitalUrl!.length}');
                                      return _buildMediaCard(
                                        title: 'Firma del Cliente',
                                        url: pedido.firmaDigitalUrl!,
                                      );
                                    },
                                  ),
                                ],
                                if (pedido.documentoConsentimientoUrl != null &&
                                    pedido
                                        .documentoConsentimientoUrl!.isNotEmpty)
                                  _buildDocumentoButton(
                                    'Documento de Consentimiento',
                                    pedido.documentoConsentimientoUrl!,
                                  ),
                              ],
                            ),
                          ]),
                        ],

                        // Información de fallo si aplica
                        if (pedido.estado == EstadoPedido.fallido) ...[
                          const SizedBox(height: MedRushTheme.spacingLg),
                          _buildInfoSection('Información de Fallo', [
                            if (pedido.motivoFallo != null)
                              _buildInfoRow(
                                  'Motivo',
                                  pedido.motivoFallo!
                                      .toString()
                                      .split('.')
                                      .last),
                            if (pedido.observacionesFallo != null)
                              _buildInfoRow(
                                  'Detalles', pedido.observacionesFallo!),
                          ]),
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
        ),
      ),
    );
  }

  // ---------- Media helpers ----------
  Widget _buildMediaCard({required String title, required String url}) {
    // Log detallado del contenido recibido
    logInfo('[FIRMA_DETALLES] _buildMediaCard - Título: $title');
    logInfo(
        '[FIRMA_DETALLES] URL completa: ${url.length > 100 ? '${url.substring(0, 100)}...' : url}');
    logInfo(
        '[FIRMA_DETALLES] Longitud del contenido: ${url.length} caracteres');
    logInfo(
        '[FIRMA_DETALLES] Inicio del contenido: ${url.substring(0, url.length > 50 ? 50 : url.length)}');
    logInfo(
        '[FIRMA_DETALLES] Final del contenido: ${url.substring(url.length > 50 ? url.length - 50 : 0)}');

    // Detectar si es base64 o URL
    final bool isBase64 = url.startsWith('data:image/');

    // Debug: Verificar detección de base64
    logInfo('[FIRMA_DETALLES] Es base64 válido: $isBase64');

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: MedRushTheme.fontWeightMedium,
              color: MedRushTheme.textPrimary,
              fontSize: MedRushTheme.fontSizeBodySmall,
            ),
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          GestureDetector(
            onTap: () =>
                _showImageDialog(url, isBase64: isBase64, title: title),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusSm),
                border: Border.all(color: MedRushTheme.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: isBase64
                  ? _buildBase64Widget(url)
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => _mediaError(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBase64Widget(String base64Data) {
    logInfo(
        '[FIRMA_DETALLES] _buildBase64Widget - Iniciando renderizado base64');
    logInfo('[FIRMA_DETALLES] Longitud: ${base64Data.length} caracteres');

    try {
      // Decodificar base64 a bytes
      final bytes = base64Decode(base64Data.split(',')[1]);
      logInfo('[FIRMA_DETALLES] Bytes decodificados: ${bytes.length} bytes');

      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          logError('[FIRMA_DETALLES] Error renderizando base64', error);
          return _mediaError();
        },
      );
    } catch (e) {
      logError('[FIRMA_DETALLES] Error decodificando base64', e);
      return _mediaError();
    }
  }

  Widget _mediaError() {
    return Container(
      color: MedRushTheme.backgroundSecondary,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: MedRushTheme.textTertiary),
    );
  }

  void _showImageDialog(String url, {required bool isBase64, String? title}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: MedRushTheme.fontWeightBold,
                      fontSize: MedRushTheme.fontSizeTitleSmall,
                      color: MedRushTheme.textPrimary,
                    ),
                  ),
                ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(MedRushTheme.spacingMd),
                    child: isBase64
                        ? _buildBase64Widget(url)
                        : Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentoButton(String label, String url) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el documento')),
          );
        }
      },
      icon: const Icon(LucideIcons.fileText, size: 18),
      label: Text(label),
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

  Widget _buildIconRow(String label, String value, IconData icon,
      {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              children: [
                Icon(icon,
                    size: 16, color: iconColor ?? MedRushTheme.primaryGreen),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$label:',
                    style: const TextStyle(
                      fontWeight: MedRushTheme.fontWeightBold,
                      color: MedRushTheme.textPrimary,
                      fontSize: MedRushTheme.fontSizeBodySmall,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodySmall,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepartidorAvatar(Usuario repartidor) {
    final String url = BaseApi.getImageUrl(repartidor.foto);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MedRushTheme.primaryGreen, width: 2),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover)
            : ColoredBox(
                color: MedRushTheme.primaryGreen.withValues(alpha: 0.1),
                child: const Icon(LucideIcons.user,
                    color: MedRushTheme.primaryGreen),
              ),
      ),
    );
  }

  Widget _buildBoldText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: MedRushTheme.fontWeightBold,
        color: MedRushTheme.textPrimary,
        fontSize: MedRushTheme.fontSizeBodyMedium,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MedRushTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textSecondary,
                fontSize: MedRushTheme.fontSizeBodySmall,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: MedRushTheme.textPrimary,
                fontSize: MedRushTheme.fontSizeBodyMedium,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return StatusHelpers.formatearFechaCompleta(date);
  }

  void _mostrarCodigoBarrasDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.barcode,
              color: MedRushTheme.primaryGreen,
              size: 24,
            ),
            SizedBox(width: MedRushTheme.spacingSm),
            Text('Código de Barras'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pedido #${pedido.id}',
              style: const TextStyle(
                fontSize: MedRushTheme.fontSizeBodyMedium,
                fontWeight: MedRushTheme.fontWeightMedium,
                color: MedRushTheme.textPrimary,
              ),
            ),
            const SizedBox(height: MedRushTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(MedRushTheme.spacingLg),
              decoration: BoxDecoration(
                color: MedRushTheme.surface,
                borderRadius:
                    BorderRadius.circular(MedRushTheme.borderRadiusMd),
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
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: pedido.codigoBarra,
                    width: 250,
                    height: 80,
                    color: MedRushTheme.textPrimary,
                    backgroundColor: MedRushTheme.surface,
                  ),
                  const SizedBox(height: MedRushTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MedRushTheme.spacingMd,
                      vertical: MedRushTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: MedRushTheme.backgroundSecondary,
                      borderRadius:
                          BorderRadius.circular(MedRushTheme.borderRadiusSm),
                    ),
                    child: Text(
                      pedido.codigoBarra,
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        fontWeight: MedRushTheme.fontWeightBold,
                        fontFamily: 'monospace',
                        color: MedRushTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: MedRushTheme.spacingSm),
                  const Text(
                    'Código de barras del pedido',
                    style: TextStyle(
                      fontSize: MedRushTheme.fontSizeBodySmall,
                      color: MedRushTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  bool _hasRecojoInfo() {
    return pedido.latitudRecojo != null ||
        pedido.longitudRecojo != null ||
        pedido.ubicacionRecojo != null;
  }

  Widget _buildMedicamentoRow(Map<String, dynamic> medicamento, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: MedRushTheme.spacingSm),
      padding: const EdgeInsets.all(MedRushTheme.spacingMd),
      decoration: BoxDecoration(
        color: MedRushTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusSm),
        border: Border.all(color: MedRushTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.pill,
                size: 16,
                color: MedRushTheme.primaryGreen,
              ),
              const SizedBox(width: MedRushTheme.spacingSm),
              Text(
                'Medicamento $index',
                style: const TextStyle(
                  fontWeight: MedRushTheme.fontWeightBold,
                  color: MedRushTheme.textPrimary,
                  fontSize: MedRushTheme.fontSizeBodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: MedRushTheme.spacingSm),
          ...medicamento.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(
                        fontWeight: MedRushTheme.fontWeightMedium,
                        color: MedRushTheme.textSecondary,
                        fontSize: MedRushTheme.fontSizeBodySmall,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: MedRushTheme.textPrimary,
                        fontSize: MedRushTheme.fontSizeBodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/ruta_optimizada.model.dart';
import 'package:medrush/services/polyline_decoding.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';
import 'package:medrush/utils/status_helpers.dart';

class MapaRutaCompletaWidget extends StatefulWidget {
  final RutaOptimizada ruta;
  final List<Map<String, dynamic>> pedidos;
  final LatLng? ubicacionRepartidor;

  const MapaRutaCompletaWidget({
    super.key,
    required this.ruta,
    required this.pedidos,
    this.ubicacionRepartidor,
  });

  @override
  State<MapaRutaCompletaWidget> createState() => _MapaRutaCompletaWidgetState();
}

class _MapaRutaCompletaWidgetState extends State<MapaRutaCompletaWidget> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Map<String, BitmapDescriptor> _numberIconCache = {};

  @override
  void initState() {
    super.initState();
    _configurarMapa();
  }

  Future<void> _configurarMapa() async {
    await _crearMarcadores();
    _crearPolylineRuta();
  }

  Future<void> _crearMarcadores() async {
    _markers.clear();

    logInfo('🗺️ Creando marcadores para ${widget.pedidos.length} pedidos');

    // Marcador del punto de inicio
    if (widget.ruta.puntoInicio != null) {
      final lat = widget.ruta.puntoInicio!['latitude'] as num?;
      final lng = widget.ruta.puntoInicio!['longitude'] as num?;
      if (lat != null && lng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('inicio'),
            position: LatLng(lat.toDouble(), lng.toDouble()),
            infoWindow: const InfoWindow(
              title: 'Punto de Inicio',
              snippet: 'Inicio de la ruta',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ),
        );
      }
    }

    // Marcador del punto final
    if (widget.ruta.puntoFinal != null) {
      final lat = widget.ruta.puntoFinal!['latitude'] as num?;
      final lng = widget.ruta.puntoFinal!['longitude'] as num?;
      if (lat != null && lng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('final'),
            position: LatLng(lat.toDouble(), lng.toDouble()),
            infoWindow: const InfoWindow(
              title: 'Punto Final',
              snippet: 'Final de la ruta',
            ),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    // Marcador de la ubicación del repartidor
    if (widget.ubicacionRepartidor != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('repartidor'),
          position: widget.ubicacionRepartidor!,
          infoWindow: InfoWindow(
            title: 'Repartidor',
            snippet:
                widget.ruta.repartidor?['nombre']?.toString() ?? 'Repartidor',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Marcadores de pedidos con orden y tipo de acción
    for (int i = 0; i < widget.pedidos.length; i++) {
      final pedido = widget.pedidos[i];

      // Acceder a las coordenadas desde ubicacion_entrega
      final ubicacionEntrega =
          pedido['ubicacion_entrega'] as Map<String, dynamic>?;
      final lat = ubicacionEntrega?['latitude'] as num?;
      final lng = ubicacionEntrega?['longitude'] as num?;

      if (lat != null && lng != null) {
        final orden = _obtenerOrdenPedido(pedido);

        // Crear icono numerado con color uniforme
        final iconoNumerado =
            await _getNumberedIcon(orden, MedRushTheme.primaryBlue);

        logInfo(
            '📍 Agregando marcador para pedido ${pedido['id']} en ($lat, $lng) - Orden: $orden');

        _markers.add(
          Marker(
            markerId: MarkerId('pedido_${pedido['id']}'),
            position: LatLng(lat.toDouble(), lng.toDouble()),
            infoWindow: InfoWindow(
              title: '$orden) ${pedido['paciente_nombre'] ?? 'Paciente'}',
              snippet: 'Pedido #${pedido['id']}',
            ),
            icon: iconoNumerado,
          ),
        );
      } else {
        logWarning('⚠️ Pedido ${pedido['id']} no tiene coordenadas válidas');
      }
    }

    logInfo('✅ Total de marcadores creados: ${_markers.length}');
    setState(() {});
  }

  void _crearPolylineRuta() {
    if (widget.ruta.polylineEncoded != null &&
        widget.ruta.polylineEncoded!.isNotEmpty) {
      logInfo('🗺️ Decodificando polyline de la ruta desde el backend');

      try {
        // Usar PolylineDecodingService para decodificar el polyline del backend
        final puntosDecodificados =
            PolylineDecodingService.decodePolylineManual(
          widget.ruta.polylineEncoded!,
        );

        if (puntosDecodificados.isNotEmpty) {
          logInfo(
              '✅ Polyline decodificado exitosamente: ${puntosDecodificados.length} puntos');

          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_optimizada'),
              points: puntosDecodificados,
              color: MedRushTheme.primaryGreen,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );

          setState(() {});
        } else {
          logWarning('⚠️ Polyline decodificado está vacío, usando fallback');
          _crearPolylineFallback();
        }
      } catch (e) {
        logError('❌ Error decodificando polyline de la ruta', e);
        logInfo('🔄 Usando fallback de polyline simple');
        _crearPolylineFallback();
      }
    } else {
      logWarning('⚠️ No hay polyline encoded en la ruta, usando fallback');
      _crearPolylineFallback();
    }
  }

  /// Crea un polyline fallback simple entre punto inicio y final
  void _crearPolylineFallback() {
    final puntos = <LatLng>[];

    // Agregar punto de inicio
    if (widget.ruta.puntoInicio != null) {
      final lat = widget.ruta.puntoInicio!['latitude'] as num?;
      final lng = widget.ruta.puntoInicio!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    // Agregar punto final
    if (widget.ruta.puntoFinal != null) {
      final lat = widget.ruta.puntoFinal!['latitude'] as num?;
      final lng = widget.ruta.puntoFinal!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    if (puntos.length >= 2) {
      logInfo('📍 Creando polyline fallback con ${puntos.length} puntos');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_fallback'),
          points: puntos,
          color: MedRushTheme.primaryGreen.withValues(alpha: 0.7),
          width: 3,
          patterns: [PatternItem.dash(15), PatternItem.gap(8)],
        ),
      );
      setState(() {});
    }
  }

  /// Crea iconos numerados para los pedidos
  Future<BitmapDescriptor> _getNumberedIcon(int number, Color color) async {
    final String cacheKey = '${color.toARGB32()}_$number';
    if (_numberIconCache.containsKey(cacheKey)) {
      return _numberIconCache[cacheKey]!;
    }

    const int size = 36;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = color;

    // Fondo círculo
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint);

    // Texto número
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)))
      ..addText(number.toString());

    final ui.Paragraph paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));
    canvas.drawParagraph(paragraph, Offset(0, (size - paragraph.height) / 2));

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List list = bytes!.buffer.asUint8List();
    final icon = BitmapDescriptor.bytes(list);
    _numberIconCache[cacheKey] = icon;
    return icon;
  }

  /// Obtiene el orden del pedido desde los datos del backend
  int _obtenerOrdenPedido(Map<String, dynamic> pedido) {
    final entregas = pedido['entregas'] as Map<String, dynamic>?;
    if (entregas != null) {
      // Priorizar orden_personalizado, luego orden_optimizado
      return entregas['orden_personalizado'] as int? ??
          entregas['orden_optimizado'] as int? ??
          1;
    }
    return 1;
  }

  LatLng _obtenerCentroDelMapa() {
    final puntos = <LatLng>[];

    // Agregar punto de inicio
    if (widget.ruta.puntoInicio != null) {
      final lat = widget.ruta.puntoInicio!['latitude'] as num?;
      final lng = widget.ruta.puntoInicio!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    // Agregar punto final
    if (widget.ruta.puntoFinal != null) {
      final lat = widget.ruta.puntoFinal!['latitude'] as num?;
      final lng = widget.ruta.puntoFinal!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    // Agregar ubicación del repartidor
    if (widget.ubicacionRepartidor != null) {
      puntos.add(widget.ubicacionRepartidor!);
    }

    // Agregar algunos pedidos para centrar mejor
    for (final pedido in widget.pedidos.take(5)) {
      final ubicacionEntrega =
          pedido['ubicacion_entrega'] as Map<String, dynamic>?;
      final lat = ubicacionEntrega?['latitude'] as num?;
      final lng = ubicacionEntrega?['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    if (puntos.isEmpty) {
      return const LatLng(-12.0464, -77.0428); // Lima por defecto
    }

    // Calcular centro promedio
    double latSum = 0;
    double lngSum = 0;
    for (final punto in puntos) {
      latSum += punto.latitude;
      lngSum += punto.longitude;
    }

    return LatLng(latSum / puntos.length, lngSum / puntos.length);
  }

  void _centrarMapa() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _obtenerCentroDelMapa(),
          zoom: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Ruta: ${widget.ruta.nombre ?? 'Sin nombre'}'),
        backgroundColor: MedRushTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.navigation),
            onPressed: _centrarMapa,
            tooltip: 'Centrar mapa',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de la ruta
          Container(
            padding: const EdgeInsets.all(MedRushTheme.spacingMd),
            decoration: const BoxDecoration(
              color: MedRushTheme.surface,
              border: Border(
                bottom: BorderSide(color: MedRushTheme.borderLight),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.truck,
                      color: MedRushTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: MedRushTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'Repartidor: ${widget.ruta.repartidor?['nombre'] ?? 'No asignado'}',
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeBodyMedium,
                          fontWeight: MedRushTheme.fontWeightMedium,
                          color: MedRushTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MedRushTheme.spacingXs),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.package,
                      color: MedRushTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: MedRushTheme.spacingXs),
                    Text(
                      '${widget.pedidos.length} pedidos',
                      style: const TextStyle(
                        fontSize: MedRushTheme.fontSizeBodySmall,
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: MedRushTheme.spacingMd),
                    if (widget.ruta.distanciaTotalEstimada != null) ...[
                      const Icon(
                        LucideIcons.mapPin,
                        color: MedRushTheme.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: MedRushTheme.spacingXs),
                      Text(
                        StatusHelpers.formatearDistanciaKm(
                            widget.ruta.distanciaTotalEstimada!),
                        style: const TextStyle(
                          fontSize: MedRushTheme.fontSizeBodySmall,
                          color: MedRushTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _obtenerCentroDelMapa(),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),

          // Leyenda de marcadores
          Container(
            padding: const EdgeInsets.all(MedRushTheme.spacingMd),
            decoration: const BoxDecoration(
              color: MedRushTheme.surface,
              border: Border(
                top: BorderSide(color: MedRushTheme.borderLight),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leyenda:',
                  style: TextStyle(
                    fontSize: MedRushTheme.fontSizeBodyMedium,
                    fontWeight: MedRushTheme.fontWeightMedium,
                    color: MedRushTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: MedRushTheme.spacingSm),
                Wrap(
                  spacing: MedRushTheme.spacingMd,
                  runSpacing: MedRushTheme.spacingXs,
                  children: [
                    _buildLeyendaItem('Inicio', BitmapDescriptor.hueGreen),
                    _buildLeyendaItem('Final', BitmapDescriptor.hueRed),
                    _buildLeyendaItem('Repartidor', BitmapDescriptor.hueBlue),
                    _buildLeyendaItem('Pedidos', MedRushTheme.primaryBlue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaItem(String label, color) {
    Color displayColor;
    if (color is double) {
      // Es un hue de BitmapDescriptor
      displayColor = HSVColor.fromAHSV(1.0, color, 1.0, 1.0).toColor();
    } else if (color is Color) {
      // Es un Color directo
      displayColor = color;
    } else {
      displayColor = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: displayColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: MedRushTheme.spacingXs),
        Text(
          label,
          style: const TextStyle(
            fontSize: MedRushTheme.fontSizeBodySmall,
            color: MedRushTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

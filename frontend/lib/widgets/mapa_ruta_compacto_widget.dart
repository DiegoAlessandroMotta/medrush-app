import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medrush/models/ruta_optimizada.model.dart';
import 'package:medrush/services/polyline_decoding.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/loggers.dart';

class MapaRutaCompactoWidget extends StatefulWidget {
  final RutaOptimizada ruta;
  final List<Map<String, dynamic>> pedidos;
  final LatLng? ubicacionRepartidor;
  final double height;

  const MapaRutaCompactoWidget({
    super.key,
    required this.ruta,
    required this.pedidos,
    this.ubicacionRepartidor,
    this.height = 300,
  });

  @override
  State<MapaRutaCompactoWidget> createState() => _MapaRutaCompactoWidgetState();
}

class _MapaRutaCompactoWidgetState extends State<MapaRutaCompactoWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Map<String, BitmapDescriptor> _numberIconCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configurarMapa();
    });
  }

  Future<void> _configurarMapa() async {
    await _crearMarcadores();
    _crearPolylineRuta();
    _centrarMapa();
  }

  Future<void> _crearMarcadores() async {
    _markers.clear();

    // Marcador del punto de inicio
    if (widget.ruta.puntoInicio != null) {
      final lat = widget.ruta.puntoInicio!['latitude'] as num?;
      final lng = widget.ruta.puntoInicio!['longitude'] as num?;
      if (lat != null && lng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('inicio'),
            position: LatLng(lat.toDouble(), lng.toDouble()),
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
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    // Marcador de la ubicación del repartidor (vehículo en vivo)
    if (widget.ubicacionRepartidor != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('repartidor'),
          position: widget.ubicacionRepartidor!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Marcadores de pedidos numerados
    for (int i = 0; i < widget.pedidos.length; i++) {
      final pedido = widget.pedidos[i];
      final ubicacionEntrega =
          pedido['ubicacion_entrega'] as Map<String, dynamic>?;
      final lat = ubicacionEntrega?['latitude'] as num?;
      final lng = ubicacionEntrega?['longitude'] as num?;

      if (lat != null && lng != null) {
        final orden = _obtenerOrdenPedido(pedido);
        final iconoNumerado =
            await _getNumberedIcon(orden, MedRushTheme.primaryBlue);

        _markers.add(
          Marker(
            markerId: MarkerId('pedido_${pedido['id']}'),
            position: LatLng(lat.toDouble(), lng.toDouble()),
            icon: iconoNumerado,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _crearPolylineRuta() {
    if (widget.ruta.polylineEncoded != null &&
        widget.ruta.polylineEncoded!.isNotEmpty) {
      try {
        final puntosDecodificados =
            PolylineDecodingService.decodePolylineManual(
          widget.ruta.polylineEncoded!,
        );

        if (puntosDecodificados.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_optimizada'),
              points: puntosDecodificados,
              color: MedRushTheme.primaryBlue,
              width: 4,
            ),
          );
          if (mounted) {
            setState(() {});
          }
        } else {
          _crearPolylineFallback();
        }
      } catch (e) {
        logError('Error decodificando polyline', e);
        _crearPolylineFallback();
      }
    } else {
      _crearPolylineFallback();
    }
  }

  void _crearPolylineFallback() {
    final puntos = <LatLng>[];

    if (widget.ruta.puntoInicio != null) {
      final lat = widget.ruta.puntoInicio!['latitude'] as num?;
      final lng = widget.ruta.puntoInicio!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    if (widget.ruta.puntoFinal != null) {
      final lat = widget.ruta.puntoFinal!['latitude'] as num?;
      final lng = widget.ruta.puntoFinal!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    if (puntos.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_fallback'),
          points: puntos,
          color: MedRushTheme.primaryBlue.withValues(alpha: 0.7),
          width: 3,
        ),
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<BitmapDescriptor> _getNumberedIcon(int number, Color color) async {
    final String cacheKey = '${color.toARGB32()}_$number';
    if (_numberIconCache.containsKey(cacheKey)) {
      return _numberIconCache[cacheKey]!;
    }

    const int size = 36;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = color;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint);

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

  int _obtenerOrdenPedido(Map<String, dynamic> pedido) {
    final entregas = pedido['entregas'] as Map<String, dynamic>?;
    if (entregas != null) {
      return entregas['orden_personalizado'] as int? ??
          entregas['orden_optimizado'] as int? ??
          1;
    }
    return 1;
  }

  LatLng _obtenerCentroDelMapa() {
    final puntos = <LatLng>[];

    if (widget.ruta.puntoInicio != null) {
      final lat = widget.ruta.puntoInicio!['latitude'] as num?;
      final lng = widget.ruta.puntoInicio!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    if (widget.ruta.puntoFinal != null) {
      final lat = widget.ruta.puntoFinal!['latitude'] as num?;
      final lng = widget.ruta.puntoFinal!['longitude'] as num?;
      if (lat != null && lng != null) {
        puntos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }

    if (widget.ubicacionRepartidor != null) {
      puntos.add(widget.ubicacionRepartidor!);
    }

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
      return const LatLng(-12.0464, -77.0428);
    }

    double latSum = 0;
    double lngSum = 0;
    for (final punto in puntos) {
      latSum += punto.latitude;
      lngSum += punto.longitude;
    }

    return LatLng(latSum / puntos.length, lngSum / puntos.length);
  }

  void _centrarMapa() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _obtenerCentroDelMapa(),
            zoom: 12,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MedRushTheme.borderRadiusMd),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _obtenerCentroDelMapa(),
            zoom: 12,
          ),
          markers: _markers,
          polylines: _polylines,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _centrarMapa();
          },
        ),
      ),
    );
  }
}

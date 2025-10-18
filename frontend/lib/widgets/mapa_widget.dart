import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medrush/models/pedido.model.dart';
import 'package:medrush/services/geocoding_service.dart';
import 'package:medrush/theme/theme.dart';
import 'package:medrush/utils/status_helpers.dart';

class MapaWidget extends StatelessWidget {
  final List<Pedido> pedidos;
  final double? latitudActual;
  final double? longitudActual;
  final Function(Pedido)? onPedidoTap;
  final LatLng? puntoSeleccionado;
  final void Function(LatLng)? onTapMapa;
  final double height;
  final bool readOnly;
  final String? markerTitle;
  final String? markerSnippet;

  const MapaWidget({
    super.key,
    required this.pedidos,
    this.latitudActual,
    this.longitudActual,
    this.onPedidoTap,
    this.puntoSeleccionado,
    this.onTapMapa,
    this.height = 220,
    this.readOnly = false,
    this.markerTitle,
    this.markerSnippet,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};

    // Agregar marcador del punto seleccionado
    if (puntoSeleccionado != null) {
      markers.add(Marker(
        markerId: const MarkerId('punto'),
        position: puntoSeleccionado!,
        infoWindow: InfoWindow(
          title: markerTitle ?? 'Ubicación',
          snippet: markerSnippet,
        ),
        icon: readOnly
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    // Agregar marcadores de pedidos (solo si no es modo de solo lectura)
    if (!readOnly) {
      for (final p in pedidos.take(20)) {
        // Solo agregar marcador si las coordenadas están disponibles
        if (p.latitudEntrega != null && p.longitudEntrega != null) {
          markers.add(Marker(
            markerId: MarkerId('pedido_${p.id}'),
            position: LatLng(p.latitudEntrega!, p.longitudEntrega!),
            infoWindow:
                InfoWindow(title: '#${p.id}', snippet: p.pacienteNombre),
          ));
        }
      }
    }

    final initialTarget = puntoSeleccionado ??
        (pedidos.isNotEmpty &&
                pedidos.first.latitudEntrega != null &&
                pedidos.first.longitudEntrega != null
            ? LatLng(
                pedidos.first.latitudEntrega!, pedidos.first.longitudEntrega!)
            : const LatLng(-12.0464, -77.0428));

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition:
              CameraPosition(target: initialTarget, zoom: readOnly ? 15 : 14),
          markers: markers,
          myLocationEnabled:
              !readOnly, // Solo mostrar ubicación en modo edición
          zoomControlsEnabled:
              false, // Ocultar controles +/-, usamos gestos o botones propios
          onTap:
              readOnly ? null : onTapMapa, // Solo permitir tap en modo edición
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Pedido>('pedidos', pedidos))
      ..add(DoubleProperty('latitudActual', latitudActual))
      ..add(DoubleProperty('longitudActual', longitudActual))
      ..add(ObjectFlagProperty<Function(Pedido p1)?>.has(
          'onPedidoTap', onPedidoTap))
      ..add(
          DiagnosticsProperty<LatLng?>('puntoSeleccionado', puntoSeleccionado))
      ..add(ObjectFlagProperty<void Function(LatLng p1)?>.has(
          'onTapMapa', onTapMapa))
      ..add(DoubleProperty('height', height))
      ..add(DiagnosticsProperty<bool>('readOnly', readOnly))
      ..add(StringProperty('markerTitle', markerTitle))
      ..add(StringProperty('markerSnippet', markerSnippet));
  }
}

class MapaPantallaCompleta extends StatefulWidget {
  final LatLng? puntoInicial;
  final void Function(LatLng, GeocodingResult?)? onUbicacionSeleccionada;
  final String? titulo;

  const MapaPantallaCompleta({
    super.key,
    this.puntoInicial,
    this.onUbicacionSeleccionada,
    this.titulo,
  });

  @override
  State<MapaPantallaCompleta> createState() => _MapaPantallaCompletaState();
}

class _MapaPantallaCompletaState extends State<MapaPantallaCompleta> {
  late GoogleMapController _mapController;
  LatLng? _puntoSeleccionado;
  String _direccionEncontrada = '';
  GeocodingResult? _geocodingResult;

  @override
  void initState() {
    super.initState();
    _puntoSeleccionado = widget.puntoInicial;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _obtenerDireccionDesdeCoordenadas(LatLng coordenadas) async {
    try {
      // Usar Google Geocoding API para obtener información de dirección
      final result = await GeocodingService.reverseGeocode(
          coordenadas.latitude, coordenadas.longitude);

      if (result != null) {
        _direccionEncontrada = result.formattedAddress;
        _geocodingResult = result;
      } else {
        _direccionEncontrada = StatusHelpers.formatearCoordenadasAltaPrecision(
            coordenadas.latitude, coordenadas.longitude);
        _geocodingResult = null;
      }
    } catch (e) {
      _direccionEncontrada = 'Error al obtener dirección';
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onMapTap(LatLng coordenadas) {
    setState(() {
      _puntoSeleccionado = coordenadas;
    });
    _obtenerDireccionDesdeCoordenadas(coordenadas);
  }

  void _confirmarUbicacion() {
    if (_puntoSeleccionado != null) {
      widget.onUbicacionSeleccionada
          ?.call(_puntoSeleccionado!, _geocodingResult);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Información de ubicación seleccionada con botón de salir
          Container(
            padding: const EdgeInsets.all(16),
            color: MedRushTheme.backgroundSecondary,
            child: Row(
              children: [
                if (_puntoSeleccionado != null) ...[
                  const Icon(
                    LucideIcons.mapPin,
                    color: MedRushTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ubicación seleccionada:',
                          style: TextStyle(
                            fontSize: MedRushTheme.fontSizeBodySmall,
                            color: MedRushTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Dirección principal
                        Text(
                          _geocodingResult?.addressLine1.isNotEmpty == true
                              ? _geocodingResult!.addressLine1
                              : _direccionEncontrada.isNotEmpty
                                  ? _direccionEncontrada
                                  : StatusHelpers
                                      .formatearCoordenadasAltaPrecision(
                                          _puntoSeleccionado!.latitude,
                                          _puntoSeleccionado!.longitude),
                          style: const TextStyle(
                            fontSize: MedRushTheme.fontSizeBodyMedium,
                            color: MedRushTheme.textPrimary,
                            fontWeight: MedRushTheme.fontWeightMedium,
                          ),
                        ),
                        // Ciudad, Estado y Código Postal
                        if (_geocodingResult != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (_geocodingResult!.city.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MedRushTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _geocodingResult!.city,
                                    style: const TextStyle(
                                      fontSize: MedRushTheme.fontSizeBodySmall,
                                      color: MedRushTheme.primaryGreen,
                                      fontWeight: MedRushTheme.fontWeightMedium,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (_geocodingResult!.state.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MedRushTheme.primaryBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _geocodingResult!.state,
                                    style: const TextStyle(
                                      fontSize: MedRushTheme.fontSizeBodySmall,
                                      color: MedRushTheme.primaryBlue,
                                      fontWeight: MedRushTheme.fontWeightMedium,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (_geocodingResult!.postalCode.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: MedRushTheme.textSecondary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _geocodingResult!.postalCode,
                                    style: const TextStyle(
                                      fontSize: MedRushTheme.fontSizeBodySmall,
                                      color: MedRushTheme.textSecondary,
                                      fontWeight: MedRushTheme.fontWeightMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: Text(
                      'Toca el mapa para seleccionar una ubicación',
                      style: TextStyle(
                        fontSize: MedRushTheme.fontSizeBodyMedium,
                        color: MedRushTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    LucideIcons.x,
                    color: MedRushTheme.textSecondary,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: MedRushTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _puntoSeleccionado ?? const LatLng(-12.0464, -77.0428),
                zoom: 15,
              ),
              markers: _puntoSeleccionado != null
                  ? {
                      Marker(
                        markerId: const MarkerId('ubicacion_seleccionada'),
                        position: _puntoSeleccionado!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    }
                  : {},
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: _onMapTap,
              myLocationEnabled: true,
            ),
          ),

          // Botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            color: MedRushTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _mapController.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _puntoSeleccionado ??
                                const LatLng(-12.0464, -77.0428),
                            zoom: 15,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.navigation),
                    label: const Text('Centrar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MedRushTheme.primaryGreen,
                      side: const BorderSide(color: MedRushTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _puntoSeleccionado != null ? _confirmarUbicacion : null,
                    icon: const Icon(LucideIcons.check),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MedRushTheme.primaryGreen,
                      foregroundColor: MedRushTheme.textInverse,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  label: const Text('Salir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MedRushTheme.textSecondary,
                    side: const BorderSide(color: MedRushTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

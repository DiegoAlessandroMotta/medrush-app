import 'package:flutter/foundation.dart'
    show
        defaultTargetPlatform,
        TargetPlatform,
        kIsWeb,
        DiagnosticPropertiesBuilder,
        DoubleProperty,
        StringProperty;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlng;

class MapWidget extends StatelessWidget {
  final double height;
  final double lat;
  final double lng;
  final String? title;
  final String? snippet;

  const MapWidget({
    super.key,
    required this.height,
    required this.lat,
    required this.lng,
    this.title,
    this.snippet,
  });

  bool get _usarFlutterMap {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    if (_usarFlutterMap) {
      final pos = latlng.LatLng(lat, lng);
      return SizedBox(
        height: height,
        child: fmap.FlutterMap(
          options: fmap.MapOptions(
            initialCenter: pos,
            initialZoom: 15,
          ),
          children: [
            fmap.TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            fmap.MarkerLayer(
              markers: [
                fmap.Marker(
                  point: pos,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      final pos = gmaps.LatLng(lat, lng);
      return SizedBox(
        height: height,
        child: gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: pos,
            zoom: 16,
          ),
          markers: {
            gmaps.Marker(
              markerId: const gmaps.MarkerId('farmacia'),
              position: pos,
              infoWindow: gmaps.InfoWindow(
                title: title ?? 'Farmacia',
                snippet: snippet ?? 'Ubicación de la farmacia',
              ),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('height', height))
      ..add(DoubleProperty('lat', lat))
      ..add(DoubleProperty('lng', lng))
      ..add(StringProperty('title', title))
      ..add(StringProperty('snippet', snippet));
  }
}
